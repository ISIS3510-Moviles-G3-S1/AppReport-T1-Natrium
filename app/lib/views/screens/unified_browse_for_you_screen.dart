import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/browse_view_model.dart';

class UnifiedBrowseForYouScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final browseViewModel = Provider.of<BrowseViewModel>(context);
    final catalog = browseViewModel.getCachedCatalog();
    final recommendations = browseViewModel.getCachedRecommendations();

    return Scaffold(
      appBar: AppBar(
        title: Text('For You'),
      ),
      body: catalog == null || recommendations == null
          ? Center(
              child: Text('No cached data available. Please connect to the internet.'),
            )
          : ListView(
              children: [
                Text('Catalog:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...catalog.entries.map((entry) => ListTile(
                      title: Text(entry.value['title'] ?? 'Unknown'),
                      subtitle: Text(entry.value['description'] ?? 'No description'),
                    )),
                Divider(),
                Text('Recommendations:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...recommendations.entries.map((entry) => ListTile(
                      title: Text(entry.value['title'] ?? 'Unknown'),
                      subtitle: Text(entry.value['description'] ?? 'No description'),
                    )),
              ],
            ),
    );
  }
}
