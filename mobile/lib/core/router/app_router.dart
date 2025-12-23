import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/student_home_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
// Teacher screens
import '../../features/teacher/screens/teacher_home_screen.dart';
import '../../features/teacher/screens/my_courses_screen.dart';
import '../../features/teacher/screens/create_course_screen.dart';
import '../../features/teacher/screens/course_detail_screen.dart';
import '../../features/teacher/screens/upload_content_screen.dart';
import '../../features/teacher/screens/create_exam_screen.dart';
import '../../features/teacher/screens/exams_management_screen.dart';
import '../../features/teacher/screens/exam_detail_screen.dart';
import '../../features/teacher/screens/exam_submissions_screen.dart';
import '../../features/teacher/screens/live_classes_screen.dart';
import '../../features/teacher/screens/live_class_join_screen.dart';
import '../../features/teacher/screens/teacher_profile_screen.dart';

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
      final isHomePage = state.uri.path == '/teacher-home' || 
                         state.uri.path == '/teacher/home' ||
                         state.uri.path == '/student-home';
      final isTeacherRoute = state.uri.path.startsWith('/teacher');
      final isStudentRoute = state.uri.path.startsWith('/student');

      print('Router redirect: path=${state.uri.path}, authenticated=$isAuthenticated, user=${currentAuthState.user?.role}');

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isLoginPage) {
        print('Redirecting to login (not authenticated)');
        return '/login';
      }

      // Role-based route protection
      if (isAuthenticated) {
        // Teacher trying to access student routes
        if (currentAuthState.isTeacher && isStudentRoute) {
          print('Redirecting teacher from student route to teacher home');
          return '/teacher/home';
        }
        // Student trying to access teacher routes
        if (currentAuthState.isStudent && isTeacherRoute) {
          print('Redirecting student from teacher route to student home');
          return '/student-home';
        }
      }

      // If authenticated and accessing home, ensure correct role-based home
      if (isAuthenticated && isHomePage) {
        if (currentAuthState.isTeacher && state.uri.path == '/student-home') {
          print('Redirecting teacher to teacher-home');
          return '/teacher/home';
        }
        if (currentAuthState.isStudent && (state.uri.path == '/teacher-home' || state.uri.path == '/teacher/home')) {
          print('Redirecting student to student-home');
          return '/student-home';
        }
        // If role matches, allow navigation
        print('Allowing navigation to ${state.uri.path}');
        return null;
      }

      // If authenticated and on login/register page, redirect to appropriate home
      if (isAuthenticated && isLoginPage) {
        print('Authenticated on login page, redirecting to home');
        if (currentAuthState.isTeacher) {
          return '/teacher/home';
        } else {
          return '/student-home';
        }
      }

      print('No redirect needed');
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
        redirect: (context, state) => '/teacher/home',
      ),
      GoRoute(
        path: '/student-home',
        name: 'student-home',
        builder: (context, state) => const StudentHomeScreen(),
      ),

      // Teacher Routes
      GoRoute(
        path: '/teacher',
        redirect: (context, state) => '/teacher/home',
      ),
      GoRoute(
        path: '/teacher/home',
        name: 'teacher-home',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/teacher/courses',
        name: 'teacher-courses',
        builder: (context, state) => const MyCoursesScreen(),
      ),
      GoRoute(
        path: '/teacher/create-course',
        name: 'teacher-create-course',
        builder: (context, state) => const CreateCourseScreen(),
      ),
      GoRoute(
        path: '/teacher/courses/:id',
        name: 'teacher-course-detail',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/teacher/courses/:id/upload-content',
        name: 'teacher-upload-content',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return UploadContentScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/teacher/courses/:id/create-exam',
        name: 'teacher-create-exam',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          final examId = state.uri.queryParameters['examId'];
          return CreateExamScreen(
            courseId: courseId,
            examId: examId,
          );
        },
      ),
      GoRoute(
        path: '/teacher/exams',
        name: 'teacher-exams',
        builder: (context, state) => const ExamsManagementScreen(),
      ),
      GoRoute(
        path: '/teacher/exams/:id',
        name: 'teacher-exam-detail',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          return ExamDetailScreen(examId: examId);
        },
      ),
      GoRoute(
        path: '/teacher/exams/:id/submissions',
        name: 'teacher-exam-submissions',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          return ExamSubmissionsScreen(examId: examId);
        },
      ),
      GoRoute(
        path: '/teacher/live',
        name: 'teacher-live',
        builder: (context, state) => const LiveClassesScreen(),
      ),
      GoRoute(
        path: '/teacher/live/:roomName',
        name: 'teacher-live-class',
        builder: (context, state) {
          final roomName = state.pathParameters['roomName']!;
          return LiveClassJoinScreen(roomName: roomName);
        },
      ),
      GoRoute(
        path: '/teacher/profile',
        name: 'teacher-profile',
        builder: (context, state) => const TeacherProfileScreen(),
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
        print('GoRouterRefreshStream: Auth state changed - previous: ${previous?.isAuthenticated}, next: ${next.isAuthenticated}');
        // Only notify if authentication status changed
        if (previous?.isAuthenticated != next.isAuthenticated) {
          print('GoRouterRefreshStream: Notifying router of auth state change');
          notifyListeners();
        } else if (previous?.user?.role != next.user?.role) {
          // Also notify if user role changed (e.g., after login)
          print('GoRouterRefreshStream: User role changed, notifying router');
          notifyListeners();
        }
      },
    );
  }
}
