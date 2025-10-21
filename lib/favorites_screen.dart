import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http; // for HTTP requests
import 'package:provider/provider.dart'; // for UserProvider access
import 'package:flutter/services.dart';
import 'user_provider.dart'; // your UserProvider file

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> favorites = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final user = context.read<UserProvider>().user;
    final userId = user?['id'];
    final apiUrl = dotenv.env['API_URL'];

    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/favorites/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        setState(() {
          favorites = data['favorites'];
        });
      } else {
        print('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching favorites: $e');
    }
  }

  Future<void> _deleteFavorite(int id) async {
    final apiUrl = dotenv.env['API_URL'];

    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/api/favorites/$id'),
      );

      if (response.statusCode == 200) {
        setState(() {
          favorites.removeWhere((item) => item['id'] == id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Favorite deleted successfully!"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete favorite (${response.statusCode})"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An error occurred while deleting."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                final text = item['text'];

                return Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              "${item['from_to']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Copied to clipboard!"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final item = favorites[index];
                              final favoriteId = item['id'];
                              print(favoriteId);

                              // optional confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Favorite'),
                                  content: const Text(
                                    'Are you sure you want to delete this favorite?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _deleteFavorite(favoriteId);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
