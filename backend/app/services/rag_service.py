import os
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

# Store FAISS indices per content
vector_stores: dict[int, Tuple[faiss.Index, List[str]]] = {}


class RAGService:
    def __init__(self):
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len
        )
    
    async def process_pdf(self, file_path: str, content_id: int):
        """Extract text from PDF, chunk it, and create embeddings."""
        # Read PDF
        full_path = Path(settings.UPLOAD_DIR) / file_path
        reader = PdfReader(str(full_path))
        
        # Extract text
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        
        if not text.strip():
            raise ValueError("No text extracted from PDF")
        
        # Split into chunks
        chunks = self.text_splitter.split_text(text)
        
        # Create embeddings
        embeddings = embedding_model.encode(chunks)
        
        # Create FAISS index
        dimension = embeddings.shape[1]
        index = faiss.IndexFlatL2(dimension)
        index.add(embeddings.astype('float32'))
        
        # Store index and chunks
        vector_stores[content_id] = (index, chunks)
        
        return len(chunks)
    
    async def ask_question(self, question: str, content_id: int) -> Tuple[str, List[str]]:
        """Answer a question using RAG."""
        if content_id not in vector_stores:
            raise ValueError(f"PDF not processed for content_id {content_id}")
        
        index, chunks = vector_stores[content_id]
        
        # Embed question
        question_embedding = embedding_model.encode([question])
        
        # Search similar chunks
        k = min(3, len(chunks))  # Get top 3 relevant chunks
        distances, indices = index.search(question_embedding.astype('float32'), k)
        
        # Get relevant chunks
        relevant_chunks = [chunks[i] for i in indices[0]]
        context = "\n\n".join(relevant_chunks)
        
        # Generate answer using OpenAI
        if not openai_client:
            # Fallback: return first relevant chunk
            return relevant_chunks[0] if relevant_chunks else "No relevant information found.", []
        
        prompt = f"""Based on the following context from a course PDF, answer the question.
        
Context:
{context}

Question: {question}

Answer:"""
        
        try:
            response = openai_client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful teaching assistant. Answer questions based on the provided context."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=300,
                temperature=0.7
            )
            answer = response.choices[0].message.content
            sources = [f"Chunk {i+1}" for i in range(len(relevant_chunks))]
            return answer, sources
        except Exception as e:
            # Fallback to simple answer
            return relevant_chunks[0] if relevant_chunks else "Unable to generate answer.", []

