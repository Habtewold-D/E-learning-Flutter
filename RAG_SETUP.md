# RAG System Setup Guide

## 🤖 AI Model Options

### **Option 1: Ollama (Recommended - Free & Local)**
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull Llama 3.1 8B model
ollama pull llama3.1:8b

# Start Ollama server
ollama serve
```

**Pros**: 
- Completely free
- Runs locally (privacy)
- No API limits
- Good performance

**Cons**: 
- Requires local resources
- Setup needed

### **Option 2: Groq (Fastest - Free Tier)**
```bash
# Get API key from https://console.groq.com/
# Add to .env:
GROQ_API_KEY=your_groq_api_key
RAG_LLM_PROVIDER=groq
```

**Pros**: 
- Fastest inference (500+ tokens/sec)
- High-quality models (Llama-3-70B)
- Easy setup

**Cons**: 
- 14K requests/day limit
- Requires internet

### **Option 3: Hugging Face (Free Tier)**
```bash
# Get API key from https://huggingface.co/settings/tokens
# Add to .env:
HUGGINGFACE_API_KEY=your_hf_api_key
RAG_LLM_PROVIDER=huggingface
```

**Pros**: 
- Multiple models available
- Good free tier
- Reliable

**Cons**: 
- 30K requests/month
- Slower than Groq

## 📋 Environment Configuration

Update your `.env` file:

```bash
# RAG Configuration
RAG_LLM_PROVIDER=ollama  # Options: ollama, huggingface, groq
OLLAMA_BASE_URL=http://localhost:11434
HUGGINGFACE_API_KEY=your_huggingface_api_key
GROQ_API_KEY=your_groq_api_key
```

## 🗄️ Database Migration

Run the database migration to create RAG tables:

```bash
cd backend
python -c "
from app.core.database import engine, Base
from app.models.rag import DocumentChunk, StudentQuery, VectorIndex
Base.metadata.create_all(bind=engine)
print('RAG tables created successfully!')
"
```

## 📦 Install Dependencies

```bash
cd backend
pip install PyPDF2==3.0.1 sentence-transformers==2.2.2 numpy==1.24.3 scikit-learn==1.3.0
```

## 🚀 Usage Guide

### **For Teachers: Index Content**

1. Upload course materials (PDFs, videos)
2. Trigger indexing for RAG:
```bash
curl -X POST "http://localhost:8000/api/rag/index-content/{content_id}" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

3. Check indexing status:
```bash
curl -X GET "http://localhost:8000/api/rag/index-status/{content_id}" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### **For Students: Ask Questions**

```bash
curl -X POST "http://localhost:8000/api/rag/ask" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": 1,
    "question": "What is machine learning?"
  }'
```

### **Query History**

```bash
curl -X GET "http://localhost:8000/api/rag/history" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📊 How It Works

### **1. Content Processing**
- PDFs: Text extraction → Chunking (500 chars) → Embedding generation
- Videos: Metadata processing (future: transcription)
- Storage: Chunks + embeddings in database

### **2. Question Answering**
- Question embedding generation
- Similarity search against course chunks
- Context retrieval (top 5 similar chunks)
- LLM answer generation using retrieved context

### **3. Performance Features**
- Cosine similarity for chunk retrieval
- Confidence scoring based on retrieved chunks
- Response time tracking
- Query history for analytics

## 🔧 Advanced Configuration

### **Embedding Model**
Default: `all-MiniLM-L6-v2` (384 dimensions)
Can be changed in `rag_service.py`

### **Chunking Strategy**
- Size: 500 characters
- Overlap: 50 characters
- Sentence boundary detection

### **Retrieval Strategy**
- Top-k: 5 chunks
- Similarity: Cosine similarity
- Context: Top 3 chunks for LLM

## 📱 Mobile Integration

Add to Flutter app:

```dart
// API endpoints
static const String ragAsk = '/rag/ask';
static const String ragHistory = '/rag/history';
static const String ragIndexStatus = '/rag/index-status/{content_id}';

// Example usage
Future<Map<String, dynamic>> askQuestion(int courseId, String question) async {
  final response = await apiClient.post(
    ragAsk,
    data: {
      'course_id': courseId,
      'question': question,
    },
  );
  return response.data;
}
```

## 🎯 Best Practices

### **For Teachers**
1. **Quality Materials**: Upload clear, well-structured PDFs
2. **Index After Upload**: Always trigger indexing after uploading
3. **Monitor Status**: Check indexing completion

### **For Students**
1. **Specific Questions**: Ask detailed questions
2. **Context**: Mention specific topics/concepts
3. **Follow-up**: Use conversation history for context

### **For Developers**
1. **Error Handling**: Implement proper error handling
2. **Rate Limiting**: Respect API limits
3. **Monitoring**: Track response times and accuracy

## 🔍 Troubleshooting

### **Common Issues**

1. **Ollama Connection Failed**
   ```bash
   # Check if Ollama is running
   curl http://localhost:11434/api/tags
   
   # Restart Ollama
   ollama serve
   ```

2. **PDF Processing Failed**
   - Check if PDF is text-based (not scanned images)
   - Verify file size limits
   - Check Cloudinary URL accessibility

3. **No Relevant Chunks Found**
   - Verify content is indexed
   - Check question relevance
   - Review chunking strategy

4. **Slow Response Times**
   - Check LLM provider performance
   - Consider reducing chunk size
   - Optimize database queries

## 📈 Scaling Considerations

### **Production Optimizations**
1. **Vector Database**: Use Pinecone/Weaviate for large scale
2. **Background Processing**: Use Celery for indexing
3. **Caching**: Redis for frequent queries
4. **Load Balancing**: Multiple LLM providers

### **Performance Monitoring**
- Track query response times
- Monitor embedding generation
- Analyze chunk retrieval accuracy
- User satisfaction metrics

## 🔒 Security & Privacy

- **Local Processing**: Ollama keeps data private
- **API Keys**: Secure storage of API credentials
- **Content Access**: Role-based access control
- **Query Logging**: Optional privacy controls
