import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/browse_view_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SearchView extends StatefulWidget {
  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic>? _results;
  bool _loading = false;
  String? _error;

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final browseViewModel = Provider.of<BrowseViewModel>(context, listen: false);
    final connectivity = Connectivity();
    final connectivityResults = await connectivity.checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    if (isOnline) {
      // Simula búsqueda online: filtra el catálogo
      final catalog = browseViewModel.getCachedCatalog();
      if (catalog == null) {
        setState(() {
          _results = null;
          _error = 'No catalog data.';
          _loading = false;
        });
        return;
      }
      final filtered = catalog.entries
          .where((entry) => (entry.value['title'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      setState(() {
        _results = filtered;
        _loading = false;
      });
      // Guarda en cache
      await browseViewModel.saveSearchHistoryAndCache(query, filtered.map((e) => e.value).toList());
    } else {
      // Offline: busca en cache de resultados
      final cached = await browseViewModel.getCachedSearchResults(query);
      if (cached != null && cached.isNotEmpty) {
        setState(() {
          _results = cached.map((e) => {'title': e.title, 'description': e.description}).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _results = null;
          _error = 'No cached results for "$query".';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Search...'),
                    onSubmitted: _search,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              Center(child: CircularProgressIndicator()),
            if (_error != null)
              Center(child: Text(_error!, style: TextStyle(color: Colors.red))),
            if (_results != null)
              Expanded(
                child: ListView(
                  children: _results!.map((entry) => ListTile(
                        title: Text(entry['title'] ?? 'Unknown'),
                        subtitle: Text(entry['description'] ?? 'No description'),
                      )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}