import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/teacher_home_screen.dart';
import '../../features/auth/screens/student_home_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to trigger router rebuilds
  ref.watch(authProvider);
  
  // Create a refresh notifier that will trigger router rebuilds
  final refreshNotifier = GoRouterRefreshStream(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final currentAuthState = ref.read(authProvider);
      final isAuthenticated = currentAuthState.isAuthenticated;
      final isLoginPage = state.uri.path == '/login' || state.uri.path == '/register';
      final isHomePage = state.uri.path == '/teacher-home' || state.uri.path == '/student-home';

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isLoginPage) {
        return '/login';
      }

      // If authenticated and on login/register page, redirect to appropriate home
      if (isAuthenticated && isLoginPage) {
        if (currentAuthState.isTeacher) {
          return '/teacher-home';
        } else {
          return '/student-home';
        }
      }

      // If authenticated and accessing home, ensure correct role-based home
      if (isAuthenticated && isHomePage) {
        if (currentAuthState.isTeacher && state.uri.path == '/student-home') {
          return '/teacher-home';
        }
        if (currentAuthState.isStudent && state.uri.path == '/teacher-home') {
          return '/student-home';
        }
      }

      return null; // No redirect needed
    },
    routes: [
      // Auth Routes (public)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home Routes (protected, role-based)
      GoRoute(
        path: '/teacher-home',
        name: 'teacher-home',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/student-home',
        name: 'student-home',
        builder: (context, state) => const StudentHomeScreen(),
      ),

      // Courses Routes (will be implemented later)
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

      // Exams Routes (will be implemented later)
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

      // RAG Route (will be implemented later)
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

      // Live Class Route (will be implemented later)
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
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Helper class to make router refresh when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    // Listen to auth state changes and notify router
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        // Only notify if authentication status changed
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }
}
