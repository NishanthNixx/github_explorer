import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Explorer (Starter)',
      home: const SearchScreen(),
    );
  }
}

/// NOTE FOR CANDIDATE:
/// This screen is intentionally minimal and un-architected. It works, but:
///  - There's no debouncing, so every keystroke fires a network request.
///  - There's no pagination; only the first page of results is ever shown.
///  - There's no distinction between "no results" and "error" states.
///  - Everything lives in setState() — no Bloc/Riverpod/etc.
///  - There's no persistence, no routing, no detail screen, no native integration.
///
/// Your job is to build all of that on top of (or in place of) this screen.
/// Feel free to delete/rewrite this file entirely if that fits your architecture better.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // NOTE: Unauthenticated GitHub API requests are limited to 60/hour.
      // Add a personal access token as a header if you hit rate limits:
      // headers: {'Authorization': 'token YOUR_TOKEN_HERE'}
      final uri = Uri.parse(
        'https://api.github.com/search/users?q=${Uri.encodeQueryComponent(query)}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['items'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Request failed with status ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub User Search (Starter)')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search GitHub usernames...',
                border: OutlineInputBorder(),
              ),
              onChanged: _search, // fires on every keystroke - no debounce!
            ),
            const SizedBox(height: 12),
            if (_isLoading) const CircularProgressIndicator(),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user['avatar_url']),
                    ),
                    title: Text(user['login']),
                    // No tap handler / detail screen / navigation yet.
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
