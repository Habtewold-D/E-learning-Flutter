import asyncio
import json
import httpx
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path
import PyPDF2
import io
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models.course import CourseContent, ContentType
from app.models.rag import DocumentChunk, StudentQuery, VectorIndex
from sqlalchemy.sql import func
from app.core.exceptions import ValidationError, NotFoundError
import logging

logger = logging.getLogger(__name__)


class RAGService:
    """Service for RAG (Retrieval-Augmented Generation) functionality using Groq."""
    
    def __init__(self, db: Session):
        self.db = db
        
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

        # Clear old chunks before re-indexing
        self.db.query(DocumentChunk).filter(DocumentChunk.content_id == content_id).delete()
        self.db.commit()
        
        try:
            if content.type == ContentType.PDF:
                chunks = await self._process_pdf_content(content)
            else:
                raise ValidationError(f"Only PDF content is supported for RAG processing. Content type: {content.type}")
            
            # Generate embeddings and store chunks
            await self._store_chunks_with_embeddings(content_id, chunks)
            
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
                text = page.extract_text()
                if text.strip():
                    # Split page into smaller chunks (roughly 500 characters)
                    chunks = self._split_text_into_chunks(text, chunk_size=500, overlap=50)
                    
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
    
    def _split_text_into_chunks(self, text: str, chunk_size: int = 500, overlap: int = 50) -> List[str]:
        """Split text into overlapping chunks."""
        chunks = []
        start = 0
        
        while start < len(text):
            end = start + chunk_size
            
            if end >= len(text):
                chunks.append(text[start:])
                break
            
            # Try to break at sentence boundary
            chunk_text = text[start:end]
            last_period = chunk_text.rfind('.')
            last_question = chunk_text.rfind('?')
            last_exclamation = chunk_text.rfind('!')
            
            best_break = max(last_period, last_question, last_exclamation)
            
            if best_break > start + chunk_size // 2:  # Don't go back too far
                end = start + best_break + 1
                chunk_text = text[start:end]
            
            chunks.append(chunk_text.strip())
            start = end - overlap
        
        return [chunk for chunk in chunks if chunk.strip()]
    
    async def _store_chunks_with_embeddings(self, content_id: int, chunks: List[Dict[str, Any]]) -> None:
        """Generate embeddings and store chunks."""
        for i, chunk_data in enumerate(chunks):
            # Generate embedding (using a free service)
            embedding = await self._generate_embedding(chunk_data["text"])
            
            # Store chunk
            chunk = DocumentChunk(
                content_id=content_id,
                chunk_text=chunk_data["text"],
                chunk_index=i,
                chunk_metadata=chunk_data["metadata"],
                embedding=embedding
            )
            self.db.add(chunk)
        
        self.db.commit()
    
    async def _generate_embedding(self, text: str) -> List[float]:
        """Generate embedding for text using Groq."""
        try:
            # Use Groq for embeddings (simplified approach)
            # For production, you might want to use a dedicated embedding service
            return self._simple_embedding(text)
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
    
    async def answer_student_question(
        self, 
        student_id: int, 
        course_id: int, 
        question: str
    ) -> Dict[str, Any]:
        """Answer student question using RAG."""
        import time
        start_time = time.time()
        
        try:
            # Retrieve relevant chunks
            relevant_chunks = await self._retrieve_relevant_chunks(course_id, question)
            
            if not relevant_chunks:
                return {
                    "answer": "I couldn't find relevant information in your course materials to answer this question. Please try rephrasing or contact your teacher.",
                    "confidence": 0.0,
                    "sources": []
                }
            
            # Generate answer using LLM
            context = "\n\n".join([chunk["text"] for chunk in relevant_chunks[:3]])  # Top 3 chunks
            answer = await self._generate_answer(question, context)
            
            # Calculate response time
            response_time = int((time.time() - start_time) * 1000)
            
            # Store query and response
            query_record = StudentQuery(
                student_id=student_id,
                course_id=course_id,
                question=question,
                answer=answer,
                context_chunks=[chunk["metadata"] for chunk in relevant_chunks],
                confidence_score=min(len(relevant_chunks) / 5.0, 1.0),  # Simple confidence calculation
                response_time_ms=response_time
            )
            self.db.add(query_record)
            self.db.commit()
            
            return {
                "answer": answer,
                "confidence": query_record.confidence_score,
                "sources": [chunk["metadata"] for chunk in relevant_chunks],
                "response_time_ms": response_time
            }
            
        except Exception as e:
            logger.error(f"Error answering question: {str(e)}")
            return {
                "answer": "I'm having trouble processing your question right now. Please try again later.",
                "confidence": 0.0,
                "sources": []
            }
    
    async def _retrieve_relevant_chunks(self, course_id: int, question: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """Retrieve most relevant chunks for a question."""
        try:
            # Generate question embedding
            question_embedding = await self._generate_embedding(question)
            
            # Get all chunks for the course
            chunks = self.db.query(DocumentChunk).join(CourseContent).filter(
                CourseContent.course_id == course_id
            ).all()
            
            # Calculate similarity scores (simple cosine similarity)
            scored_chunks = []
            for chunk in chunks:
                similarity = self._cosine_similarity(question_embedding, chunk.embedding)
                scored_chunks.append({
                    "chunk": chunk,
                    "similarity": similarity,
                    "text": chunk.chunk_text,
                    "metadata": chunk.metadata
                })
            
            # Sort by similarity and return top_k
            scored_chunks.sort(key=lambda x: x["similarity"], reverse=True)
            return scored_chunks[:top_k]
            
        except Exception as e:
            logger.error(f"Error retrieving chunks: {str(e)}")
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
        """Generate answer using Groq."""
        if not settings.GROQ_API_KEY:
            raise ValidationError("GROQ_API_KEY is required for RAG answer generation")
        prompt = f"""Based on the following course materials, answer the student's question.

Course Materials:
{context}

Student Question: {question}

Provide a helpful, accurate answer based only on the provided materials. If the materials don't contain enough information, say so clearly."""

        try:
            async with httpx.AsyncClient(timeout=60) as client:
                response = await client.post(
                    "https://api.groq.com/openai/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {settings.GROQ_API_KEY}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": "llama-3.1-70b-versatile",
                        "messages": [
                            {"role": "system", "content": "You are a helpful AI tutor that answers questions based on provided course materials."},
                            {"role": "user", "content": prompt}
                        ],
                        "max_tokens": 500,
                        "temperature": 0.7
                    }
                )

            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"]
            raise Exception(f"Groq API error: {response.status_code}")
                
        except Exception as e:
            logger.error(f"Groq generation error: {str(e)}")
            raise
    
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
