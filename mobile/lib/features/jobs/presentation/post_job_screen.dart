import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/providers/home_provider.dart';
import '../providers/active_job_provider.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Colombo 05 · Havelock Town');
  int _selectedCategoryId = 14;
  String _selectedCategoryName = 'Electrical & Wiring';
  bool _equipmentProvided = false;
  bool _nearHazard = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Post Job Request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Service Category', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          catsAsync.when(
            data: (cats) => DropdownButtonFormField<int>(
              initialValue: cats.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : cats.first.id,
              items: cats
                  .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nameEn} (${c.nameSi})')))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                final found = cats.firstWhere((c) => c.id == val);
                setState(() {
                  _selectedCategoryId = found.id;
                  _selectedCategoryName = found.nameEn;
                });
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Using default Electrical category'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Describe the issue / work needed',
              hintText: 'e.g. Trip switch trips whenever AC is turned on',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'GPS Pin / Landmark',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Equipment / Ladder Provided'),
            subtitle: const Text('Turn ON if customer already has tools/ladder on site'),
            value: _equipmentProvided,
            onChanged: (v) => setState(() => _equipmentProvided = v),
          ),
          SwitchListTile(
            title: const Text('Near Power Lines / Fragile Roof'),
            subtitle: const Text('Alerts worker to bring safety gear'),
            value: _nearHazard,
            onChanged: (v) => setState(() => _nearHazard = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _submitting
                ? null
                : () async {
                    if (_descCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a job description')),
                      );
                      return;
                    }
                    setState(() => _submitting = true);
                    await ref.read(activeJobProvider.notifier).postJobRequest(
                          categoryId: _selectedCategoryId,
                          categoryName: _selectedCategoryName,
                          description: _descCtrl.text.trim(),
                          equipmentProvided: _equipmentProvided,
                          nearHazard: _nearHazard,
                          locationLabel: _locationCtrl.text.trim(),
                        );
                    if (context.mounted) {
                      context.go('/active-job');
                    }
                  },
            icon: const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Matching Nearby Workers...' : 'Post Request & Get Quotes'),
          ),
        ],
      ),
    );
  }
}
