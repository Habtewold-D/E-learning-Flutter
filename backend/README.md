---
title: E-Learning RAG System
emoji: 🎓
colorFrom: blue
colorTo: pink
sdk: docker
pinned: false
license: mit
---

# E-Learning RAG System

A Retrieval-Augmented Generation (RAG) system for e-learning platforms using Sentence Transformers and ChromaDB.

## Features

- 🧠 **Semantic Search**: Using Sentence Transformers embeddings
- 🗄️ **Vector Database**: ChromaDB for efficient retrieval
- 💬 **AI Answers**: Groq-powered question answering
- 📱 **Mobile Ready**: RESTful API for mobile apps
- 🔄 **Lazy Loading**: Memory-efficient model loading

## API Endpoints

### Health Check
```
GET /api/health
```

### RAG Operations
```
POST /api/rag/index-content/{content_id}  # Index new content
GET /api/rag/index-status/{content_id}    # Check indexing status
POST /api/rag/ask-question              # Ask questions
```

### Authentication
```
POST /api/auth/login
POST /api/auth/register
GET /api/auth/me
```

## Usage

1. **Index Content**: Upload PDFs and index them for search
2. **Ask Questions**: Get AI-powered answers from indexed content
3. **Mobile Integration**: Use with Flutter mobile app

## Memory Optimization

This system is optimized for memory-constrained environments:
- Ultra-lightweight models (90MB)
- Lazy loading (load on first use)
- Small batch processing (4 chunks)
- Efficient vector operations

## Hardware

- **CPU Basic** (Free tier)
- **16GB RAM** (Free tier)
- **10GB Storage** (Free tier)

---

*Built with ❤️ using Sentence Transformers, ChromaDB, and Groq*
