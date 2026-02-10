import asyncio
import os
import json
import httpx
import psutil  # Add memory monitoring
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path
import PyPDF2
import io
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models.course import CourseContent, ContentType
from app.models.rag import StudentQuery, VectorIndex, RagThread
from sqlalchemy.sql import func
from app.core.exceptions import ValidationError, NotFoundError
import logging

# Memory optimization settings - must be set BEFORE model imports
os.environ.setdefault("SENTENCE_TRANSFORMERS_HOME", os.path.abspath("./model_cache"))
os.environ.setdefault("HF_HOME", os.path.abspath("./model_cache"))
os.environ.setdefault("HUGGINGFACE_HUB_CACHE", os.path.abspath("./model_cache"))
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
os.environ.setdefault("ONNXRUNTIME_DISABLE", "1")
os.environ.setdefault("DISABLE_OPENVINO", "1")
os.environ.setdefault("TORCH_CUDA_ARCH_LIST", "")
os.environ.setdefault("CUDA_VISIBLE_DEVICES", "")

import chromadb
from chromadb.config import Settings as ChromaSettings
from huggingface_hub import snapshot_download
from sentence_transformers import SentenceTransformer

# Global singleton for embedding model - TRULY shared across all instances
_GLOBAL_EMBEDDING_MODEL = None

logger = logging.getLogger(__name__)


class RAGService:
    """Service for RAG (Retrieval-Augmented Generation) functionality using Groq + Sentence Transformers + ChromaDB."""
    
    def __init__(self, db: Session):
        self.db = db
        # Initialize ChromaDB client with persistence
        self.chroma_client = chromadb.PersistentClient(
            path="./chroma_db",
            settings=ChromaSettings(anonymized_telemetry=False),
        )
        self.collection = self.chroma_client.get_or_create_collection("course_content")
        
        # Load sentence transformer model once (TRUE global singleton) with memory optimization
        global _GLOBAL_EMBEDDING_MODEL
        if _GLOBAL_EMBEDDING_MODEL is None:
            # Check available memory before loading
            memory_before = psutil.virtual_memory().available / (1024 * 1024 * 1024)  # GB
            logger.info(f"Available memory before model load: {memory_before:.2f}GB")
            
            # Choose model based on available memory
            if memory_before < 0.3:  # Less than 300MB available
                logger.warning("Low memory detected, using minimal model")
                model_name = 'all-MiniLM-L6-v2'  # Smallest model
            else:
                model_name = 'all-MiniLM-L6-v2'  # Standard model
            
            logger.info(f"Loading sentence transformer model: {model_name}")
            model_path = self._ensure_local_model(model_name)
            _GLOBAL_EMBEDDING_MODEL = SentenceTransformer(model_path)
            
            # Check memory after loading
            memory_after = psutil.virtual_memory().available / (1024 * 1024 * 1024)  # GB
            memory_used = memory_before - memory_after
            logger.info(f"Memory used by model: {memory_used:.2f}GB")
            logger.info(f"Available memory after load: {memory_after:.2f}GB")
        else:
            logger.info("Reusing existing sentence transformer model")

    @classmethod
    def get_embedding_model(cls):
        """Get singleton embedding model instance."""
        return _GLOBAL_EMBEDDING_MODEL

    @staticmethod
    def _ensure_local_model(model_name: str) -> str:
        """Download only required model files (exclude ONNX/OpenVINO) and return local path."""
        cache_root = os.path.abspath("./model_cache")
        local_dir = os.path.join(cache_root, "sentence_transformers", model_name.replace("/", "__"))
        if not Path(local_dir).exists():
            Path(local_dir).mkdir(parents=True, exist_ok=True)
            snapshot_download(
                repo_id=model_name,
                local_dir=local_dir,
                local_dir_use_symlinks=False,
                allow_patterns=[
                    "*.json",
                    "*.txt",
                    "model.safetensors",  # ONLY the main model
                    "pytorch_model.bin",  # ONLY PyTorch format
                    "*.model",  # Tokenizer files
                    "vocab.txt",
                    "tokenizer.json",
                ],
                ignore_patterns=[
                    "*.onnx",  # Exclude ALL ONNX files
                    "*_O*.onnx",  # Exclude quantized ONNX
                    "*_quantized*",  # Exclude quantized models
                    "openvino_*",  # Exclude OpenVINO files
                    "*_int8*",  # Exclude quantized versions
                ],
                resume_download=True,
            )
        return local_dir
        
    async def process_uploaded_content(self, content_id: int) -> Dict[str, Any]:
        """Process uploaded content for RAG indexing."""
        content = self.db.query(CourseContent).filter(CourseContent.id == content_id).first()
        if not content:
            raise NotFoundError("Content not found")
        
        # Mark as indexing (idempotent)
        vector_index = (
            self.db.query(VectorIndex)
            .filter(VectorIndex.content_id == content_id)
            .first()
        )
        if vector_index is None:
            vector_index = VectorIndex(content_id=content_id, is_indexed=1)
            self.db.add(vector_index)
        else:
            vector_index.is_indexed = 1
            vector_index.chunk_count = 0
            vector_index.error_message = None
            vector_index.last_updated = func.now()

        # Persist indexing status before background work
        self.db.commit()
        
        try:
            if content.type == ContentType.PDF:
                chunks = await self._process_pdf_content(content)
            else:
                raise ValidationError(f"Only PDF content is supported for RAG processing. Content type: {content.type}")
            
            # Generate embeddings and store chunks
            await self._store_chunks_with_embeddings(content_id, content.course_id, chunks)
            
            # Update index status
            vector_index.is_indexed = 2
            vector_index.chunk_count = len(chunks)
            vector_index.last_updated = func.now()
            self.db.commit()
            
            return {
                "content_id": content_id,
                "status": "indexed",
                "chunks_created": len(chunks)
            }
            
        except Exception as e:
            vector_index.is_indexed = 0
            vector_index.error_message = str(e)
            self.db.commit()
            logger.error(f"Error processing content {content_id}: {str(e)}")
            raise
    
    async def _process_pdf_content(self, content: CourseContent) -> List[Dict[str, Any]]:
        """Extract and chunk PDF content."""
        try:
            # Download PDF from Cloudinary
            pdf_content = await self._download_file_from_url(content.url)
            
            # Extract text from PDF
            pdf_reader = PyPDF2.PdfReader(io.BytesIO(pdf_content))
            text_chunks = []
            
            for page_num, page in enumerate(pdf_reader.pages):
                text = page.extract_text() or ""
                text = self._clean_extracted_text(text)
                if text.strip():
                    # Split page into smaller chunks (sentence-based, ~900 chars)
                    chunks = self._split_text_into_chunks(
                        text,
                        chunk_size=900,
                        overlap_sentences=2,
                    )
                    
                    for i, chunk in enumerate(chunks):
                        text_chunks.append({
                            "text": chunk,
                            "metadata": {
                                "page_number": page_num + 1,
                                "chunk_index": i,
                                "content_title": content.title
                            }
                        })
            
            return text_chunks
            
        except Exception as e:
            logger.error(f"Error processing PDF: {str(e)}")
            raise ValidationError(f"Failed to process PDF: {str(e)}")

    def _clean_extracted_text(self, text: str) -> str:
        """Normalize PDF extracted text for better chunking."""
        import re

        # Fix hyphenated line breaks (e.g., "inter-\nnational")
        text = re.sub(r"(\w)-\n(\w)", r"\1\2", text)
        # Normalize newlines and spacing
        text = text.replace("\r", "\n")
        text = re.sub(r"\n{3,}", "\n\n", text)
        text = re.sub(r"[ \t]{2,}", " ", text)
        # Trim each line and rejoin
        lines = [line.strip() for line in text.split("\n")]
        text = "\n".join([line for line in lines if line != ""])
        return text.strip()
    
    async def _download_file_from_url(self, url: str) -> bytes:
        """Download file from URL or load from local path."""
        try:
            if not (url.startswith("http://") or url.startswith("https://")):
                raise ValidationError("Content URL must be an http/https URL")

            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(url)
                response.raise_for_status()
                return response.content
        except Exception as e:
            logger.error(f"Error downloading file: {str(e)}")
            raise ValidationError(f"Failed to download file: {str(e)}")
    
    def _split_text_into_chunks(
        self,
        text: str,
        chunk_size: int = 1000,
        overlap: int = 2,
        overlap_sentences: Optional[int] = None,
    ) -> List[str]:
        """Split text into structure-aware semantic chunks."""
        import re

        # Determine overlap sentences
        if overlap_sentences is None:
            overlap_sentences = overlap

        # Clean and normalize text first
        text = self._clean_extracted_text(text)
        
        # Split by document structure (headings, paragraphs)
        chunks = []
        
        # Try to detect headings (Markdown-style) - FIXED regex with closing )
        heading_pattern = r'(?m)^((?:#{1,6}\s+|[A-Z][a-z]*\.\s+|[0-9]+\.\s+).+)$'
        sections = re.split(heading_pattern, text)
        
        if len(sections) > 1:
            # Document has structure - chunk by sections
            current_chunk = ""
            current_length = 0
            
            for section in sections:
                section = section.strip()
                if not section:
                    continue
                    
                # If adding this section exceeds chunk size, start new chunk
                if current_length + len(section) + 2 > chunk_size and current_chunk:
                    chunks.append(current_chunk.strip())
                    # Start new chunk with overlap from previous
                    sentences = re.split(r'(?<=[.!?])\s+', current_chunk)
                    overlap_text = " ".join(sentences[-overlap_sentences:]) if len(sentences) > overlap_sentences else ""
                    current_chunk = overlap_text + "\n\n" + section
                    current_length = len(current_chunk)
                else:
                    if current_chunk:
                        current_chunk += "\n\n" + section
                    else:
                        current_chunk = section
                    current_length += len(section) + 2
            
            # Add final chunk
            if current_chunk.strip():
                chunks.append(current_chunk.strip())
                
        else:
            # No clear structure - fall back to paragraph-based chunking
            paragraphs = [p.strip() for p in re.split(r'\n\s*\n', text) if p.strip()]
            
            if not paragraphs:
                # Fallback to sentence-based splitting
                sentences = [s.strip() for s in re.split(r'(?<=[.!?])\s+', text) if s.strip()]
                if not sentences:
                    return []

                current_chunk = ""
                current_length = 0

                for sentence in sentences:
                    if current_length + len(sentence) + 1 > chunk_size and current_chunk:
                        chunks.append(current_chunk.strip())
                        sentences_list = re.split(r'(?<=[.!?])\s+', current_chunk)
                        overlap_text = " ".join(sentences_list[-overlap_sentences:]) if len(sentences_list) > overlap_sentences else ""
                        current_chunk = overlap_text + " " + sentence
                        current_length = len(current_chunk)
                    else:
                        current_chunk += " " + sentence if current_chunk else sentence
                        current_length += len(sentence) + 1

                if current_chunk.strip():
                    chunks.append(current_chunk.strip())
            else:
                # Paragraph-based chunking with better context preservation
                current_chunk = ""
                current_length = 0
                
                for paragraph in paragraphs:
                    if current_length + len(paragraph) + 2 > chunk_size and current_chunk:
                        chunks.append(current_chunk.strip())
                        # Start new chunk with overlap
                        sentences = re.split(r'(?<=[.!?])\s+', current_chunk)
                        overlap_text = " ".join(sentences[-overlap_sentences:]) if len(sentences) > overlap_sentences else ""
                        current_chunk = overlap_text + "\n\n" + paragraph
                        current_length = len(current_chunk)
                    else:
                        if current_chunk:
                            current_chunk += "\n\n" + paragraph
                        else:
                            current_chunk = paragraph
                        current_length += len(paragraph) + 2

                if current_chunk.strip():
                    chunks.append(current_chunk.strip())

        # Filter out very short chunks and clean up
        final_chunks = []
        for chunk in chunks:
            chunk = chunk.strip()
            if len(chunk) > 100:  # Minimum chunk size
                final_chunks.append(chunk)

        return final_chunks
    
    async def _store_chunks_with_embeddings(self, content_id: int, course_id: int, chunks: List[Dict[str, Any]]) -> None:
        """Generate embeddings and store chunks in ChromaDB with proper metadata."""
        try:
            # Generate embeddings using singleton model
            model = self.get_embedding_model()
            texts = [chunk_data["text"] for chunk_data in chunks]
            
            # Clear existing content from ChromaDB to avoid duplicates - FIXED deletion
            try:
                # First, try to get existing chunks for this content_id
                existing_results = self.collection.get(
                    where={"content_id": {"$eq": str(content_id)}}
                )

                if existing_results and existing_results.get("ids"):
                    # Delete old chunks for this content_id
                    self.collection.delete(ids=existing_results["ids"])
                    logger.info(f"Deleted {len(existing_results['ids'])} old chunks for content {content_id}")
            except:
                pass  # Collection might not exist yet
            
            # Store in ChromaDB in batches to reduce memory
            batch_size = 16
            for start in range(0, len(chunks), batch_size):
                end = min(start + batch_size, len(chunks))
                batch_texts = texts[start:end]
                batch_embeddings = model.encode(batch_texts, batch_size=16, show_progress_bar=False)
                batch_ids = [f"{content_id}_{i}" for i in range(start, end)]
                batch_metadatas = [
                    {
                        **chunks[i]["metadata"],
                        "course_id": str(course_id),
                        "content_id": str(content_id),
                    }
                    for i in range(start, end)
                ]

                self.collection.add(
                    documents=batch_texts,
                    embeddings=batch_embeddings.tolist(),
                    metadatas=batch_metadatas,
                    ids=batch_ids,
                )
            
            logger.info(f"Stored {len(chunks)} chunks in ChromaDB for content {content_id}")
            
        except Exception as e:
            logger.error(f"Error storing chunks: {str(e)}")
            raise
    
    def _generate_embedding(self, text: str) -> List[float]:
        """Generate embedding using singleton Sentence Transformers model."""
        try:
            # Use singleton model instance
            model = self.get_embedding_model()
            embedding = model.encode(text)
            logger.info(f"Generated embedding with {len(embedding)} dimensions")
            return embedding.tolist()
                    
        except Exception as e:
            logger.error(f"Error generating embedding: {str(e)}")
            # Fallback to simple embedding
            return self._simple_embedding(text)
    
    def _simple_embedding(self, text: str) -> List[float]:
        """Simple fallback embedding (hash-based)."""
        # This is a very basic fallback - in production you'd want proper embeddings
        import hashlib
        hash_obj = hashlib.md5(text.encode())
        hash_hex = hash_obj.hexdigest()
        
        # Convert hash to float values (very basic approach)
        embedding = []
        for i in range(0, len(hash_hex), 2):
            byte_val = int(hash_hex[i:i+2], 16)
            embedding.append(byte_val / 255.0)
        
        # Pad or truncate to 384 dimensions (standard for many embedding models)
        while len(embedding) < 384:
            embedding.append(0.0)
        
        return embedding[:384]
    
    def _get_or_create_thread(
        self,
        student_id: int,
        course_id: int,
        thread_id: Optional[str],
        thread_title: Optional[str],
        seed_question: str,
    ) -> RagThread:
        if thread_id:
            thread = (
                self.db.query(RagThread)
                .filter(RagThread.id == thread_id)
                .filter(RagThread.student_id == student_id)
                .filter(RagThread.course_id == course_id)
                .first()
            )
            if not thread:
                raise ValidationError("Invalid thread id")
            return thread

        import uuid
        title = (thread_title or seed_question).strip()
        if len(title) > 60:
            title = title[:57] + "..."

        thread = RagThread(
            id=str(uuid.uuid4()),
            student_id=student_id,
            course_id=course_id,
            title=title or "New conversation",
        )
        self.db.add(thread)
        self.db.commit()
        self.db.refresh(thread)
        return thread

    async def answer_student_question(
        self,
        student_id: int,
        course_id: int,
        question: str,
        thread_id: Optional[str] = None,
        thread_title: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Answer student question using RAG."""
        import time
        start_time = time.time()

        normalized = question.strip().lower()
        thread = self._get_or_create_thread(
            student_id=student_id,
            course_id=course_id,
            thread_id=thread_id,
            thread_title=thread_title,
            seed_question=question,
        )
        if len(normalized.split()) <= 2 or normalized in {"hi", "hello", "hey", "thanks", "thank you"}:
            return {
                "answer": "Hi! Ask me a specific question from the course materials and I’ll answer it.",
                "confidence": 0.0,
                "sources": [],
                "response_time_ms": int((time.time() - start_time) * 1000),
                "thread_id": thread.id,
            }
        
        try:
            # Retrieve relevant chunks
            relevant_chunks = await self._retrieve_relevant_chunks(course_id, question)
            
            if not relevant_chunks:
                return {
                    "answer": "I couldn't find relevant information in your course materials to answer this question. Please try rephrasing or contact your teacher.",
                    "confidence": 0.0,
                    "sources": []
                }
            
            # Generate answer using LLM with plain context
            context_blocks = [chunk["text"] for chunk in relevant_chunks]
            context = "\n\n---\n\n".join(context_blocks)
            answer = await self._generate_answer(question, context)
            
            # Calculate response time
            response_time = int((time.time() - start_time) * 1000)
            
            # Store query and response
            query_record = StudentQuery(
                student_id=student_id,
                course_id=course_id,
                thread_id=thread.id,
                question=question,
                answer=answer,
                context_chunks=[chunk["metadata"] for chunk in relevant_chunks],
                confidence_score=min(len(relevant_chunks) / 2.0, 1.0),  # Simple confidence calculation
                response_time_ms=response_time
            )
            self.db.add(query_record)
            thread.updated_at = func.now()
            self.db.commit()
            
            return {
                "answer": answer,
                "confidence": query_record.confidence_score,
                "sources": [chunk["metadata"] for chunk in relevant_chunks],
                "response_time_ms": response_time,
                "thread_id": thread.id,
            }
            
        except Exception as e:
            logger.error(f"Error answering question: {str(e)}")
            return {
                "answer": "I'm having trouble processing your question right now. Please try again later.",
                "confidence": 0.0,
                "sources": []
            }

    def list_threads(self, student_id: int, course_id: Optional[int] = None) -> List[Dict[str, Any]]:
        query = self.db.query(RagThread).filter(RagThread.student_id == student_id)
        if course_id:
            query = query.filter(RagThread.course_id == course_id)
        threads = query.order_by(RagThread.updated_at.desc()).all()

        results = []
        for thread in threads:
            last_query = (
                self.db.query(StudentQuery)
                .filter(StudentQuery.thread_id == thread.id)
                .order_by(StudentQuery.created_at.desc())
                .first()
            )
            results.append(
                {
                    "thread_id": thread.id,
                    "course_id": thread.course_id,
                    "title": thread.title,
                    "last_question": last_query.question if last_query else "",
                    "last_answer": last_query.answer if last_query else "",
                    "updated_at": (last_query.created_at if last_query else thread.updated_at).isoformat(),
                }
            )
        return results

    def get_thread_messages(self, student_id: int, thread_id: str) -> List[Dict[str, Any]]:
        thread = (
            self.db.query(RagThread)
            .filter(RagThread.id == thread_id)
            .filter(RagThread.student_id == student_id)
            .first()
        )
        if not thread:
            raise NotFoundError("Thread not found")

        queries = (
            self.db.query(StudentQuery)
            .filter(StudentQuery.thread_id == thread_id)
            .order_by(StudentQuery.created_at.asc())
            .all()
        )

        return [
            {
                "question": q.question,
                "answer": q.answer,
                "confidence": q.confidence_score or 0.0,
                "sources": q.context_chunks or [],
                "created_at": q.created_at.isoformat(),
            }
            for q in queries
        ]
    
    async def _retrieve_relevant_chunks(self, course_id: int, question: str, top_k: int = 8) -> List[Dict[str, Any]]:
        """Retrieve most relevant chunks using ChromaDB vector search."""
        try:
            logger.info(f"Retrieving chunks for course {course_id}, question: '{question[:100]}...'")
            
            # Generate question embedding using singleton model
            model = self.get_embedding_model()
            question_embedding = model.encode(question)
            
            try:
                results = self.collection.query(
                    query_embeddings=question_embedding.tolist(),
                    n_results=top_k * 2,  # Get more results for filtering
                    where={"course_id": {"$eq": str(course_id)}}  # Proper ChromaDB syntax for exact match
                )
                
                # Debug logging
                logger.info(f"ChromaDB query returned: {type(results)}")
                logger.info(f"Available keys: {list(results.keys()) if isinstance(results, dict) else 'Not a dict'}")
                
                # Convert ChromaDB results to our format - FIXED PARSING with better error handling
                scored_chunks = []
                if (results and 
                    isinstance(results, dict) and 
                    'documents' in results and 
                    'metadatas' in results and 
                    'distances' in results and
                    results['documents'] and 
                    results['metadatas'][0] and 
                    results['distances'][0]):
                    
                    for i in range(len(results['documents'][0])):
                        similarity = 1 - results['distances'][0][i]  # Convert distance to similarity
                        document = results['documents'][0][i]
                        metadata = results['metadatas'][0][i] if results['metadatas'][0] else {}
                        
                        scored_chunks.append({
                            "chunk": {
                                "chunk_text": document,
                                "chunk_metadata": metadata
                            },
                            "similarity": similarity,
                            "text": document,
                            "metadata": metadata
                        })
                else:
                    logger.warning(f"Unexpected ChromaDB response structure: {results}")
                    
            except Exception as e:
                logger.error(f"ChromaDB query failed: {str(e)}")
                return []
            
            # Sort by similarity and return top_k
            scored_chunks.sort(key=lambda x: x["similarity"], reverse=True)
            final_chunks = scored_chunks[:top_k]
            
            logger.info(f"Retrieved {len(final_chunks)} relevant chunks from ChromaDB with similarities: {[c['similarity'] for c in final_chunks]}")
            
            return final_chunks
            
        except Exception as e:
            logger.error(f"Error retrieving chunks from ChromaDB: {str(e)}")
            return []
    
    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors."""
        try:
            import math
            
            dot_product = sum(a * b for a, b in zip(vec1, vec2))
            magnitude1 = math.sqrt(sum(a * a for a in vec1))
            magnitude2 = math.sqrt(sum(b * b for b in vec2))
            
            if magnitude1 == 0 or magnitude2 == 0:
                return 0.0
            
            return dot_product / (magnitude1 * magnitude2)
            
        except Exception as e:
            logger.error(f"Error calculating similarity: {str(e)}")
            return 0.0
    
    async def _generate_answer(self, question: str, context: str) -> str:
        """Generate answer using Groq."""
        try:
            return await self._groq_generate(question, context)
        except Exception as e:
            logger.error(f"Error generating answer: {str(e)}")
            return self._fallback_answer(question, context)
    
    async def _groq_generate(self, question: str, context: str) -> str:
        """Generate answer using Groq with improved prompt."""
        if not settings.GROQ_API_KEY:
            logger.warning("GROQ_API_KEY not configured, using fallback answer")
            return self._fallback_answer(question, context)
        
        prompt = f"""You are an expert AI tutor helping students learn from course materials.

CONTEXT from course materials:
{context}

STUDENT QUESTION: {question}

INSTRUCTIONS:
1. Answer ONLY using the provided context
2. If context contains relevant information, provide a clear, detailed answer
3. If context doesn't contain enough information, say "I don't have enough information in the course materials to answer this question"
4. Be educational and helpful
5. Do not mention sources, page numbers, or chunk references
6. Keep answers concise (2-3 paragraphs maximum)

Answer:"""

        try:
            async with httpx.AsyncClient(timeout=60) as client:
                response = await client.post(
                    "https://api.groq.com/openai/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.GROQ_API_KEY}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": "llama-3.1-8b-instant",
                        "messages": [
                            {"role": "system", "content": "You are an expert AI tutor that answers questions based only on provided course materials."},
                            {"role": "user", "content": prompt}
                        ],
                        "max_tokens": 500,
                        "temperature": 0.2  # Lower for more factual answers
                    }
                )

            if response.status_code == 200:
                answer = response.json()["choices"][0]["message"]["content"]
                logger.info(f"Generated answer with {len(answer)} characters")
                return answer
            else:
                logger.error(f"Groq API error: {response.status_code} - {response.text}")
                return self._fallback_answer(question, context)
                
        except Exception as e:
            logger.error(f"Groq generation error: {str(e)}")
            return self._fallback_answer(question, context)

    def _fallback_answer(self, question: str, context: str) -> str:
        """Fallback answer when AI services are unavailable."""
        # Simple keyword-based answer
        question_lower = question.lower()
        context_lower = context.lower()
        
        # Look for direct matches
        if any(word in context_lower for word in question_lower.split() if len(word) > 3):
            return "Based on the course materials, I can see information related to your question. However, I'm having trouble generating a detailed response right now. Please review the course materials or ask your teacher for clarification."
        
        return "I couldn't find specific information about your question in the course materials. Please review the materials or contact your teacher for help with this topic."

    def get_student_query_history(self, student_id: int, course_id: Optional[int] = None) -> List[Dict[str, Any]]:
        """Get query history for a student."""
        query = self.db.query(StudentQuery).filter(StudentQuery.student_id == student_id)
        
        if course_id:
            query = query.filter(StudentQuery.course_id == course_id)
        
        queries = query.order_by(StudentQuery.created_at.desc()).limit(50).all()
        
        return [
            {
                "id": q.id,
                "question": q.question,
                "answer": q.answer,
                "confidence": q.confidence_score,
                "response_time_ms": q.response_time_ms,
                "created_at": q.created_at.isoformat(),
                "sources": q.context_chunks
            }
            for q in queries
        ]
