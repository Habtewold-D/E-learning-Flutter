import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherBottomNav extends StatelessWidget {
  final int currentIndex;

  const TeacherBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/teacher/home');
            break;
          case 1:
            context.go('/teacher/courses');
            break;
          case 2:
            context.go('/teacher/live');
            break;
          case 3:
            context.go('/teacher/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_call),
          label: 'Live',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}






