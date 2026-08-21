import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'whatsapp_templates.dart';

class ManageTemplatesPage extends StatefulWidget {
  const ManageTemplatesPage({super.key});

  @override
  State<ManageTemplatesPage> createState() => _ManageTemplatesPageState();
}

class _ManageTemplatesPageState extends State<ManageTemplatesPage> {
  List<String> _templates = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(savedWhatsAppTemplatesKey);
    if (!mounted) return;
    setState(() {
      _templates = List<String>.from(stored ?? defaultWhatsAppTemplates);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(savedWhatsAppTemplatesKey, _templates);
  }

  Future<void> _openEditor({int? index}) async {
    final controller = TextEditingController(
      text: index == null ? '' : _templates[index],
    );
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              index == null ? 'Add template' : 'Edit template',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type your WhatsApp message…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(context, value);
              },
              child: const Text('Save template'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;

    setState(() {
      if (index == null) {
        _templates = [result, ..._templates.where((item) => item != result)];
      } else {
        _templates = List<String>.from(_templates)..[index] = result;
      }
    });
    await _persist();
  }

  Future<void> _delete(int index) async {
    final removed = _templates[index];
    setState(() => _templates = List<String>.from(_templates)..removeAt(index));
    await _persist();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Template deleted.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            setState(() {
              final restored = List<String>.from(_templates);
              restored.insert(index.clamp(0, restored.length), removed);
              _templates = restored;
            });
            await _persist();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WhatsApp templates',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        foregroundColor: const Color(0xFF075E54),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _openEditor,
            tooltip: 'Add template',
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 44),
                  const SizedBox(height: 10),
                  const Text('No saved templates'),
                  TextButton.icon(
                    onPressed: _openEditor,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add a template'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(
                    Icons.chat_outlined,
                    color: Color(0xFF128C7E),
                  ),
                  title: Text(_templates[index]),
                  onTap: () => _openEditor(index: index),
                  trailing: IconButton(
                    onPressed: () => _delete(index),
                    tooltip: 'Delete template',
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
            ),
      floatingActionButton: _templates.isEmpty
          ? null
          : FloatingActionButton.small(
              onPressed: _openEditor,
              tooltip: 'Add template',
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}
