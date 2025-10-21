import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

import './data/languages.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  void initState() {
    final user = context.read<UserProvider>().user;
    print("from translator_screen.dart widget: ${user?['username']}");
  }

  final TextEditingController _inputController = TextEditingController();

  String _translatedText = "";
  String _fromLang = "Filipino";
  String _toLang = "Cebuano";

  final List<String> _languages = languages;

  void _swapLanguages() {
    setState(() {
      final temp = _fromLang;
      _fromLang = _toLang;
      _toLang = temp;
    });
  }

  void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
  }

  Future<void> _translateText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final url = Uri.parse('${dotenv.env['API_URL']}/api/translate');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromLang': _fromLang,
          'toLang': _toLang,
          'textToTranslate': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _translatedText = data['translation'] ?? "No translation found";
        });
      } else {
        setState(() {
          _translatedText = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = "Error: $e";
      });
    }
  }

  Future<void> _addToFavorites(
    BuildContext context,
    String translatedText,
    String fromLang,
    String toLang,
  ) async {
    final user = context.read<UserProvider>().user;
    final userId = user?['id'];

    if (translatedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot add empty text to favorites."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("${dotenv.env["API_URL"]}/api/favorites"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'text': translatedText,
          'fromLang': fromLang,
          'toLang': toLang,
        }),
      );

      if (response.statusCode == 201) {
print("Response status: ${response.statusCode}");
print("Response body: ${response.body}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to favorites!"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add favorite. (${response.statusCode})"),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print("Response: ${response.body}");
    } catch (e) {
      print("Error adding favorite: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An error occurred. Please try again."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      // Drawer
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Usap Pinoy Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Translator'),
              onTap: () {
                Navigator.pushNamed(context, '/translator');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pushNamed(context, '/favorites');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _fromLang,
                    items: _languages
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _fromLang = value!),
                    decoration: const InputDecoration(labelText: "From"),
                  ),
                ),
                IconButton(
                  onPressed: _swapLanguages,
                  icon: const Icon(Icons.swap_horiz),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _toLang,
                    items: _languages
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _toLang = value!),
                    decoration: const InputDecoration(labelText: "To"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Enter text",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _translateText, // call the new function
              label: const Text("Translate"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The translated text
                    Expanded(
                      child: Text(
                        _translatedText.isEmpty
                            ? "Translation will appear here..."
                            : _translatedText,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // The copy button
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.blueGrey),
                          onPressed: () {
                            if (_translatedText.isNotEmpty) {
                              copyToClipboard(context, _translatedText);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Copied to clipboard!"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Empty"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () => _addToFavorites(
                            context,
                            _translatedText,
                            _fromLang,
                            _toLang,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
