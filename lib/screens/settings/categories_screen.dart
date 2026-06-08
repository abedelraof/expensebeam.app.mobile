import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/categories');
      final data = res.data;
      _categories = data is List
          ? data
          : (data['categories'] ?? data['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiClient.post('/categories',
                    data: {'name': nameCtrl.text.trim()});
                _load();
              } catch (_) {}
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(dynamic cat) async {
    final id = cat['_id'] ?? cat['id'];
    try {
      await ApiClient.delete('/categories/$id');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
          onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('No categories'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    return Dismissible(
                      key: Key(cat['_id']?.toString() ?? i.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(ctx).colorScheme.error,
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(cat),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.category),
                          title: Text(cat['name']?.toString() ?? ''),
                          subtitle: (cat['subcategories'] as List?)
                                      ?.isNotEmpty ==
                                  true
                              ? Text(
                                  (cat['subcategories'] as List)
                                      .map((s) => s['name'] ?? s)
                                      .join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
