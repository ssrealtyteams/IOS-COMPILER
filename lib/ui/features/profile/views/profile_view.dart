import 'package:flutter/material.dart';
import '../view_models/profile_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.viewModel});

  final ProfileViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadProfile('usr_101'),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final user = viewModel.user;
        if (user == null) {
          return Center(
            child: ElevatedButton(
              onPressed: () => viewModel.loadProfile('usr_101'),
              child: const Text('Load Profile'),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  user.name.substring(0, 1),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => viewModel.loadProfile(user.id),
                child: const Text('Refresh'),
              ),
            ],
          ),
        );
      },
    );
  }
}
