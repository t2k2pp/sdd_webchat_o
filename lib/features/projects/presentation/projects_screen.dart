import 'package:flutter/material.dart';

import '../../../app/widgets/app_drawer.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentPath: '/projects'),
      appBar: AppBar(title: const Text('Projects')),
      body: const Center(child: Text('Phase 0: プロジェクト管理画面の骨格')),
    );
  }
}
