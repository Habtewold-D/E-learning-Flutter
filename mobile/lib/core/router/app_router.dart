import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
// Student screens
import '../../features/student/screens/student_home_screen.dart';
import '../../features/student/screens/my_courses_screen.dart' as student;
import '../../features/student/screens/browse_courses_screen.dart';
import '../../features/student/screens/course_detail_screen.dart' as student_course;
import '../../features/student/screens/content_viewer_screen.dart';
import '../../features/student/screens/exams_list_screen.dart';
import '../../features/student/screens/take_exam_screen.dart';
import '../../features/student/screens/exam_results_screen.dart';
import '../../features/student/screens/review_answers_screen.dart';
import '../../features/student/screens/live_classes_screen.dart';
import '../../features/student/screens/live_class_join_screen.dart';
import '../../features/student/screens/student_profile_screen.dart';
// Teacher screens
import '../../features/teacher/screens/teacher_home_screen.dart';
import '../../features/teacher/screens/my_courses_screen.dart' as teacher;
import '../../features/teacher/screens/create_course_screen.dart';
import '../../features/teacher/screens/course_detail_screen.dart' as teacher_course;
import '../../features/teacher/screens/upload_content_screen.dart';
import '../../features/teacher/screens/create_exam_screen.dart';
import '../../features/teacher/screens/exams_management_screen.dart';
import '../../features/teacher/screens/exam_detail_screen.dart';
import '../../features/teacher/screens/exam_submissions_screen.dart';
import '../../features/teacher/screens/live_classes_screen.dart';
import '../../features/teacher/screens/live_class_join_screen.dart';
import '../../features/teacher/screens/teacher_profile_screen.dart';
import '../../features/teacher/screens/enrollment_requests_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_teachers_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_notifications_screen.dart';
// RAG Screens
import '../../features/rag/screens/ai_chat_screen.dart';
import '../../features/rag/screens/admin_rag_content_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to trigger router rebuilds
  ref.watch(authProvider);
  
  // Create a refresh notifier that will trigger router rebuilds
  final refreshNotifier = GoRouterRefreshStream(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    observers: [routeObserver],
    redirect: (context, state) {
      final currentAuthState = ref.read(authProvider);
      final isAuthenticated = currentAuthState.isAuthenticated;
      final isLoginPage = state.uri.path == '/login' || state.uri.path == '/register';
      final isHomePage = state.uri.path == '/teacher-home' || 
                         state.uri.path == '/teacher/home' ||
                         state.uri.path == '/admin-home' ||
                         state.uri.path == '/admin/home' ||
                         state.uri.path == '/student-home' ||
                         state.uri.path == '/student/home';
      final isTeacherRoute = state.uri.path.startsWith('/teacher');
      final isStudentRoute = state.uri.path.startsWith('/student');
      final isAdminRoute = state.uri.path.startsWith('/admin');

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isLoginPage) {
        return '/login';
      }

      // Role-based route protection
      if (isAuthenticated) {
        // Teacher trying to access student routes
        if (currentAuthState.isTeacher && isStudentRoute) {
          return '/teacher/home';
        }
        // Student trying to access teacher routes
        if (currentAuthState.isStudent && isTeacherRoute) {
          return '/student/home';
        }
        // Admin trying to access non-admin routes
        if (currentAuthState.isAdmin && (isTeacherRoute || isStudentRoute)) {
          return '/admin/home';
        }
        // Non-admin trying to access admin routes
        if (!currentAuthState.isAdmin && isAdminRoute) {
          return currentAuthState.isTeacher ? '/teacher/home' : '/student/home';
        }
      }

      // If authenticated and accessing home, ensure correct role-based home
      if (isAuthenticated && isHomePage) {
        if (currentAuthState.isTeacher && state.uri.path == '/student-home') {
          return '/teacher/home';
        }
        if (currentAuthState.isAdmin && state.uri.path == '/student-home') {
          return '/admin/home';
        }
        if (currentAuthState.isStudent && (state.uri.path == '/teacher-home' || state.uri.path == '/teacher/home')) {
          return '/student/home';
        }
        if (currentAuthState.isAdmin && (state.uri.path == '/teacher-home' || state.uri.path == '/teacher/home')) {
          return '/admin/home';
        }
        // If role matches, allow navigation
        return null;
      }

      // If authenticated and on login/register page, redirect to appropriate home
      if (isAuthenticated && isLoginPage) {
        if (currentAuthState.isAdmin) {
          return '/admin/home';
        } else if (currentAuthState.isTeacher) {
          return '/teacher/home';
        } else {
          return '/student/home';
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
        redirect: (context, state) => '/teacher/home',
      ),
      GoRoute(
        path: '/student-home',
        redirect: (context, state) => '/student/home',
      ),
      GoRoute(
        path: '/admin-home',
        redirect: (context, state) => '/admin/home',
      ),

      // Teacher Routes
      GoRoute(
        path: '/teacher',
        redirect: (context, state) => '/teacher/home',
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/home',
      ),
      GoRoute(
        path: '/teacher/home',
        name: 'teacher-home',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/admin/home',
        name: 'admin-home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/teachers',
        name: 'admin-teachers',
        builder: (context, state) => const AdminTeachersScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'admin-reports',
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin-notifications',
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: '/teacher/courses',
        name: 'teacher-courses',
        builder: (context, state) => const teacher.MyCoursesScreen(),
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
          return teacher_course.CourseDetailScreen(courseId: courseId);
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
        path: '/teacher/requests',
        name: 'teacher-requests',
        builder: (context, state) => const EnrollmentRequestsScreen(),
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
          final classIdParam = state.uri.queryParameters['classId'];
          final classId = classIdParam != null ? int.tryParse(classIdParam) : null;
          return LiveClassJoinScreen(
            roomName: roomName,
            liveClassId: classId,
          );
        },
      ),
      GoRoute(
        path: '/teacher/profile',
        name: 'teacher-profile',
        builder: (context, state) => const TeacherProfileScreen(),
      ),
      GoRoute(
        path: '/teacher/notifications',
        name: 'teacher-notifications',
        builder: (context, state) => const NotificationsScreen(isTeacher: true),
      ),
      GoRoute(
        path: '/admin/rag-content',
        name: 'admin-rag-content',
        builder: (context, state) => const AdminRAGContentScreen(),
      ),
      // Student Routes
      GoRoute(
        path: '/student',
        redirect: (context, state) => '/student/home',
      ),
      GoRoute(
        path: '/student/home',
        name: 'student-home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/student/courses',
        name: 'student-my-courses',
        builder: (context, state) => const student.MyCoursesScreen(),
      ),
      GoRoute(
        path: '/student/browse',
        name: 'student-browse',
        builder: (context, state) => const BrowseCoursesScreen(),
      ),
      GoRoute(
        path: '/student/courses/:courseId',
        name: 'student-course-detail',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return student_course.CourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/student/content/:contentId',
        name: 'student-content-viewer',
        builder: (context, state) {
          final contentId = state.pathParameters['contentId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final type = (extra?['type'] as String?) ?? state.uri.queryParameters['type'] ?? 'video';
          final title = (extra?['title'] as String?) ?? 'Content $contentId';
          final url = (extra?['url'] as String?) ?? '';
          return ContentViewerScreen(
            contentId: contentId,
            title: title,
            type: type,
            url: url,
          );
        },
      ),
      GoRoute(
        path: '/student/exams',
        name: 'student-exams',
        builder: (context, state) {
          final courseId = state.uri.queryParameters['courseId'];
          return ExamsListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/student/exams/:examId/take',
        name: 'student-take-exam',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          return TakeExamScreen(examId: examId);
        },
      ),
      GoRoute(
        path: '/student/exams/:examId/results',
        name: 'student-exam-results',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final score = state.uri.queryParameters['score'];
          final extra = state.extra as Map<String, dynamic>?;
          final result = extra?['result'];
          final answers = extra?['answers'] as Map<String, String>?;
          return ExamResultsScreen(
            examId: examId,
            score: score,
            result: result,
            answers: answers,
          );
        },
      ),
      GoRoute(
        path: '/student/exams/:examId/review',
        name: 'student-exam-review',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final answers = extra?['answers'] as Map<String, String>?;
          return ReviewAnswersScreen(examId: examId, answers: answers);
        },
      ),
      GoRoute(
        path: '/student/live',
        name: 'student-live-classes',
        builder: (context, state) => const StudentLiveClassesScreen(),
      ),
      GoRoute(
        path: '/student/live/:roomName',
        name: 'student-live-class',
        builder: (context, state) {
          final roomName = state.pathParameters['roomName']!;
          final classIdParam = state.uri.queryParameters['classId'];
          final classId = classIdParam != null ? int.tryParse(classIdParam) : null;
          return StudentLiveClassJoinScreen(
            roomName: roomName,
            liveClassId: classId,
          );
        },
      ),
      GoRoute(
        path: '/student/profile',
        name: 'student-profile',
        builder: (context, state) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: '/student/notifications',
        name: 'student-notifications',
        builder: (context, state) => const NotificationsScreen(isTeacher: false),
      ),
      GoRoute(
        path: '/student/ai-chat',
        name: 'student-ai-chat',
        builder: (context, state) {
          // Get course parameters from query or use defaults
          final courseId = state.uri.queryParameters['courseId'] ?? '1';
          final courseTitle = state.uri.queryParameters['courseTitle'] ?? 'Course';
          return AIChatScreen(
            courseId: int.parse(courseId),
            courseTitle: courseTitle,
          );
        },
      ),

      // Legacy Routes (will be implemented later)
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
        } else if (previous?.user?.role != next.user?.role) {
          // Also notify if user role changed (e.g., after login)
          notifyListeners();
        }
      },
    );
  }
}
