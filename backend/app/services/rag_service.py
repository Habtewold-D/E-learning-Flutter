import os
import json
from pathlib import Path
from typing import Tuple, List
from pypdf import PdfReader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from sentence_transformers import SentenceTransformer
import faiss
import numpy as np
from openai import OpenAI
from app.core.config import settings

# Global models (load once)
embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
openai_client = OpenAI(api_key=settings.OPENAI_API_KEY) if settings.OPENAI_API_KEY else None

# Store FAISS indices per content (in-memory cache)
vector_stores: dict[int, Tuple[faiss.Index, List[str]]] = {}

# Directory for storing RAG data
RAG_DATA_DIR = Path(settings.UPLOAD_DIR) / "rag_data"
RAG_DATA_DIR.mkdir(parents=True, exist_ok=True)


class RAGService:
    def __init__(self):
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len
        )
        # Load existing RAG data on startup
        self._load_all_rag_data()
    
    def _save_rag_data(self, content_id: int, index: faiss.Index, chunks: List[str]):
        """Save FAISS index and chunks to disk."""
        content_dir = RAG_DATA_DIR / str(content_id)
        content_dir.mkdir(parents=True, exist_ok=True)
        
        # Save FAISS index
        index_path = content_dir / "index.faiss"
        faiss.write_index(index, str(index_path))
        
        # Save chunks as JSON
        chunks_path = content_dir / "chunks.json"
        with open(chunks_path, 'w', encoding='utf-8') as f:
            json.dump(chunks, f, ensure_ascii=False, indent=2)
        
        # Store in memory cache
        vector_stores[content_id] = (index, chunks)
        print(f"Saved RAG data for content_id {content_id} to disk")
    
    def _load_rag_data(self, content_id: int) -> Tuple[faiss.Index, List[str]] | None:
        """Load FAISS index and chunks from disk."""
        content_dir = RAG_DATA_DIR / str(content_id)
        index_path = content_dir / "index.faiss"
        chunks_path = content_dir / "chunks.json"
        
        if not index_path.exists() or not chunks_path.exists():
            return None
        
        try:
            # Load FAISS index
            index = faiss.read_index(str(index_path))
            
            # Load chunks
            with open(chunks_path, 'r', encoding='utf-8') as f:
                chunks = json.load(f)
            
            # Store in memory cache
            vector_stores[content_id] = (index, chunks)
            return (index, chunks)
        except Exception as e:
            print(f"Error loading RAG data for content_id {content_id}: {e}")
            return None
    
    def _load_all_rag_data(self):
        """Load all existing RAG data on startup."""
        if not RAG_DATA_DIR.exists():
            return
        
        loaded_count = 0
        for content_dir in RAG_DATA_DIR.iterdir():
            if content_dir.is_dir():
                try:
                    content_id = int(content_dir.name)
                    loaded = self._load_rag_data(content_id)
                    if loaded:
                        loaded_count += 1
                        print(f"Loaded RAG data for content_id {content_id} from disk")
                except ValueError:
                    continue
        
        if loaded_count > 0:
            print(f"Loaded {loaded_count} RAG dataset(s) on startup")
    
    async def process_pdf(self, file_path: str, content_id: int):
        """Extract text from PDF, chunk it, and create embeddings."""
        # Check if already processed (in memory)
        if content_id in vector_stores:
            print(f"RAG data already exists in memory for content_id {content_id}")
            return len(vector_stores[content_id][1])
        
        # Try to load from disk first
        loaded = self._load_rag_data(content_id)
        if loaded:
            print(f"Loaded existing RAG data for content_id {content_id} from disk")
            return len(loaded[1])
        
        # Read PDF
        full_path = Path(settings.UPLOAD_DIR) / file_path
        if not full_path.exists():
            raise ValueError(f"PDF file not found: {full_path}")
        
        reader = PdfReader(str(full_path))
        
        # Extract text
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        
        if not text.strip():
            raise ValueError("No text extracted from PDF")
        
        # Split into chunks
        chunks = self.text_splitter.split_text(text)
        
        if not chunks or len(chunks) == 0:
            raise ValueError("No text chunks created from PDF")
        
        # Create embeddings
        embeddings = embedding_model.encode(chunks)
        
        if embeddings.shape[0] == 0:
            raise ValueError("Failed to create embeddings")
        
        # Create FAISS index
        dimension = embeddings.shape[1]
        index = faiss.IndexFlatL2(dimension)
        index.add(embeddings.astype('float32'))
        
        # Save to disk and store in memory
        self._save_rag_data(content_id, index, chunks)
        
        return len(chunks)
    
    async def ask_question(self, question: str, content_id: int) -> Tuple[str, List[str]]:
        """Answer a question using RAG."""
        # Try to load from disk if not in memory
        if content_id not in vector_stores:
            loaded = self._load_rag_data(content_id)
            if not loaded:
                raise ValueError(f"PDF not processed for content_id {content_id}. Please process the PDF first.")
        
        index, chunks = vector_stores[content_id]
        
        if not chunks or len(chunks) == 0:
            raise ValueError(f"No chunks available for content_id {content_id}")
        
        # Embed question
        question_embedding = embedding_model.encode([question])
        
        # Search similar chunks
        k = min(3, len(chunks))  # Get top 3 relevant chunks
        if k == 0:
            raise ValueError("No chunks available for search")
        
        distances, indices = index.search(question_embedding.astype('float32'), k)
        
        # Get relevant chunks with bounds checking
        relevant_chunks = []
        if len(indices) > 0 and len(indices[0]) > 0:
            for idx in indices[0]:
                if 0 <= idx < len(chunks):
                    relevant_chunks.append(chunks[idx])
        
        # Fallback to first chunks if search failed
        if not relevant_chunks:
            relevant_chunks = chunks[:min(3, len(chunks))]
        
        context = "\n\n".join(relevant_chunks)
        sources = [f"Section {i+1}" for i in range(len(relevant_chunks))]
        
        # Generate answer using OpenAI
        if not openai_client:
            # Fallback: return formatted summary
            answer = f"Based on the document:\n\n{context[:500]}..."
            if len(context) > 500:
                answer += "\n\n(Note: OpenAI API key not configured. Add OPENAI_API_KEY to .env for better answers)"
            return answer, sources
        
        prompt = f"""Based on the following context from a course PDF, answer the question concisely and accurately.

Context:
{context}

Question: {question}

Provide a clear, direct answer based only on the context provided. If the information is not in the context, say so."""
        
        try:
            print(f"Calling OpenAI API for question: {question[:50]}...")
            response = openai_client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful teaching assistant. Answer questions based on the provided context. Be concise and accurate."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=500,
                temperature=0.7
            )
            answer = response.choices[0].message.content.strip()
            print(f"OpenAI response received successfully")
            return answer, sources
        except Exception as e:
            # Fallback to formatted context summary
            import traceback
            error_msg = str(e)
            print(f"⚠️ OpenAI API error: {error_msg}")
            print(f"⚠️ Using fallback answer from document context")
            traceback.print_exc()
            
            # Return formatted answer with error note
            answer = f"Based on the document:\n\n{context[:600]}..."
            if len(context) > 600:
                answer += "..."
            
            # Add error note
            if "quota" in error_msg.lower() or "429" in error_msg or "insufficient_quota" in error_msg:
                answer += "\n\n(Note: OpenAI API quota exceeded. Please check your billing or upgrade your plan.)"
            else:
                answer += f"\n\n(Note: OpenAI API error occurred. Using document context directly.)"
            
            return answer, sources

