import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens (will be created later)
// import '../../features/auth/screens/login_screen.dart';
// import '../../features/auth/screens/register_screen.dart';
// import '../../features/courses/screens/courses_list_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Register Screen - Coming Soon')),
        ),
      ),
      
      // Home/Courses Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home Screen - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/courses',
        name: 'courses',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Courses List - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/course/:id',
        name: 'course-detail',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return Scaffold(
            appBar: AppBar(title: Text('Course $courseId')),
            body: Center(child: Text('Course Detail - Coming Soon')),
          );
        },
      ),
      
      // Exams Routes
      GoRoute(
        path: '/exams/:courseId',
        name: 'exams',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return Scaffold(
            appBar: AppBar(title: Text('Exams - Course $courseId')),
            body: Center(child: Text('Exams List - Coming Soon')),
          );
        },
      ),
      GoRoute(
        path: '/exam/:id',
        name: 'exam-detail',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          return Scaffold(
            appBar: AppBar(title: Text('Exam $examId')),
            body: Center(child: Text('Take Exam - Coming Soon')),
          );
        },
      ),
      
      // RAG Route
      GoRoute(
        path: '/rag/:contentId',
        name: 'rag',
        builder: (context, state) {
          final contentId = state.pathParameters['contentId']!;
          return Scaffold(
            appBar: AppBar(title: const Text('Ask Questions')),
            body: Center(child: Text('RAG Chat - Content $contentId - Coming Soon')),
          );
        },
      ),
      
      // Live Class Route
      GoRoute(
        path: '/live/:roomName',
        name: 'live-class',
        builder: (context, state) {
          final roomName = state.pathParameters['roomName']!;
          return Scaffold(
            appBar: AppBar(title: const Text('Live Class')),
            body: Center(child: Text('Live Class - $roomName - Coming Soon')),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}


