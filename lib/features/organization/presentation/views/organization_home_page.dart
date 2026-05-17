import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationHomePage extends ConsumerWidget {
  const OrganizationHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Home'),
      ),
      body: const Center(
        child: Text('Organization Home Screen'),
      ),
    );
  }
}
