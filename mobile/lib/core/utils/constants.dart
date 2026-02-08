class AppConstants {
  // ============================================
  // API BASE URL CONFIGURATION
  // ============================================
  // IMPORTANT: Change this IP address to match your backend server's IP
  // 
  // To find your IP address:
  //   Linux/Mac: Run `hostname -I` or `ip addr show` or `ifconfig`
  //   Windows: Run `ipconfig` and look for IPv4 Address
  //
  // Common configurations:
  //   - Android Emulator: http://10.0.2.2:8000/api
  //   - iOS Simulator: http://localhost:8000/api
  //   - Physical Device: http://YOUR_LOCAL_IP:8000/api (e.g., http://192.168.8.9:8000/api)
  //
  // Make sure your backend is running with: uvicorn app.main:app --host 0.0.0.0 --port 8000
  // ============================================
  static const String baseUrl = 'https://e-learning-backend-nkf7.onrender.com/api';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String pushTokenKey = 'push_token';
  
  // API Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authChangePassword = '/auth/change-password';
  
  static const String courses = '/courses';
  static const String courseContent = '/courses/{course_id}/content';
  
  static const String exams = '/exams';
  static const String examSubmit = '/exams/{exam_id}/submit';
  static const String examResults = '/exams/{exam_id}/results';

  static const String notificationTokens = '/notifications/tokens';
  static const String notificationsInApp = '/notifications/inapp';

  // RAG - AI Assistant
  static const String ragAsk = '/rag/ask';
  static const String ragHistory = '/rag/history';
  static const String ragIndexStatus = '/rag/index-status/{content_id}';
  static const String ragIndexContent = '/rag/index-content/{content_id}';

  // JaaS live class token is served by backend
  
  // File Upload
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
  static const List<String> allowedPdfFormats = ['pdf'];
  
  // App Info
  static const String appName = 'E-Learning Platform';
  static const String appVersion = '1.0.0';
}


