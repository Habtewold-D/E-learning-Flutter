class AppConstants {
  // API Configuration
  // Change this based on your setup:
  // - Android Emulator: http://10.0.2.2:8000
  // - iOS Simulator: http://localhost:8000
  // - Physical Device: http://YOUR_IP:8000
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // API Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  
  static const String courses = '/courses';
  static const String courseContent = '/courses/{course_id}/content';
  
  static const String exams = '/exams';
  static const String examSubmit = '/exams/{exam_id}/submit';
  static const String examResults = '/exams/{exam_id}/results';
  
  static const String ragAsk = '/rag/ask';
  static const String ragProcess = '/rag/process/{course_content_id}';
  
  static const String liveCreateRoom = '/live/create-room';
  static const String liveJoinRoom = '/live/join-room/{room_name}';
  
  // File Upload
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
  static const List<String> allowedPdfFormats = ['pdf'];
  
  // App Info
  static const String appName = 'E-Learning Platform';
  static const String appVersion = '1.0.0';
}


