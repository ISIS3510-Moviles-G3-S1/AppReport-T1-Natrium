import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/browse_view_model.dart';

class SearchView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final browseViewModel = Provider.of<BrowseViewModel>(context);
    final catalog = browseViewModel.getCachedCatalog();

    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: catalog == null
          ? Center(
              child: Text('No cached data available. Please connect to the internet.'),
            )
          : ListView(
              children: catalog.entries.map((entry) => ListTile(
                    title: Text(entry.value['title'] ?? 'Unknown'),
                    subtitle: Text(entry.value['description'] ?? 'No description'),
                  )).toList(),
            ),
    );
  }
}