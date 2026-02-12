class AppConstants {

  // Base URL for the API
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
  static const String ragThreads = '/rag/threads';
  static const String ragThreadMessages = '/rag/threads/{thread_id}';
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


