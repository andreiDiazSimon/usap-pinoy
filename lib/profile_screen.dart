import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No user data found. Please log in.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile avatar with gradient background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.person, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Username
            Text(
              user['username'] ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              user['email'] ?? 'No email provided',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    _buildProfileAction(
                      icon: Icons.email_outlined,
                      title: 'Change Email',
                      color: Colors.blueAccent,
                      onTap: () {
                        _showChangeEmailDialog(context);
                      },
                    ),
                    const Divider(height: 25),
                    _buildProfileAction(
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      color: Colors.redAccent,
                      onTap: () {
                        _showDeleteAccountDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Logout button
            ElevatedButton.icon(
              onPressed: () {
                context.read<UserProvider>().clearUser();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable profile action tile
  Widget _buildProfileAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // Change Email Dialog
  void _showChangeEmailDialog(BuildContext context) {
    final controller = TextEditingController();
    final user = context.read<UserProvider>().user!;
    final userId = user['id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Email"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter new email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isEmpty) return;

              try {
                final response = await http.put(
                  Uri.parse(
                    '${dotenv.env['API_URL']}/api/profile/$userId/email',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'email': newEmail}),
                );

                if (response.statusCode == 200) {
                  final updatedUser = jsonDecode(response.body)['user'];

                  // Update the provider
                  context.read<UserProvider>().setUser(updatedUser);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email updated successfully")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update email")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Delete Account Dialog
void _showDeleteAccountDialog(BuildContext context) {
  final user = context.read<UserProvider>().user!;
  final userId = user['id'];
  final apiUrl = dotenv.env['API_URL'] ?? '';

  // First confirmation dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Account"),
      content: const Text(
        "Are you sure you want to permanently delete your account? This action cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // close first dialog
            // Show second confirmation
            _showFinalDeleteConfirmation(context, apiUrl, userId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text("Yes, Delete"),
        ),
      ],
    ),
  );
}

// Second confirmation modal
void _showFinalDeleteConfirmation(
    BuildContext context, String apiUrl, dynamic userId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Delete"),
      content: const Text(
        "This is your last chance. Are you really sure you want to delete your account?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // close confirmation
            try {
              final response = await http.delete(
                Uri.parse('$apiUrl/api/profile/$userId'),
              );

              if (response.statusCode == 200) {
                context.read<UserProvider>().clearUser();
                Navigator.pushReplacementNamed(context, '/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account deleted successfully"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Failed to delete account. (${response.statusCode})"),
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error: $e")),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}

}
