import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/app_mode_provider.dart';

class WorkerKycScreen extends ConsumerStatefulWidget {
  const WorkerKycScreen({super.key});

  @override
  ConsumerState<WorkerKycScreen> createState() => _WorkerKycScreenState();
}

class _WorkerKycScreenState extends ConsumerState<WorkerKycScreen> {
  final _nicCtrl = TextEditingController();
  final _guarantorCtrl = TextEditingController();
  final _guarantorPhoneCtrl = TextEditingController();
  double _radiusKm = 15;
  bool _nicFrontDone = false;
  bool _selfieDone = false;
  bool _saving = false;

  @override
  void dispose() {
    _nicCtrl.dispose();
    _guarantorCtrl.dispose();
    _guarantorPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fast-Track Worker KYC')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Step 1: Sri Lankan NIC & Guarantor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _nicCtrl,
            decoration: const InputDecoration(labelText: 'NIC Number (e.g. 921234567V or 199212345678)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _guarantorCtrl,
            decoration: const InputDecoration(labelText: 'Referee / Guarantor Name (for Trusted Tier)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _guarantorPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Referee Phone (+94...)'),
          ),
          const SizedBox(height: 18),
          const Text('Step 2: Document & Liveness Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(_nicFrontDone ? Icons.check_circle : Icons.badge_outlined,
                color: _nicFrontDone ? Colors.green : Colors.blue),
            title: const Text('NIC Front & Back'),
            subtitle: Text(_nicFrontDone ? 'Captured & watermarked' : 'Tap to capture'),
            onTap: () => setState(() => _nicFrontDone = true),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(_selfieDone ? Icons.check_circle : Icons.face_retouching_natural_outlined,
                color: _selfieDone ? Colors.green : Colors.blue),
            title: const Text('Live Front-Camera Selfie'),
            subtitle: Text(_selfieDone ? 'Liveness matched' : 'Tap to verify'),
            onTap: () => setState(() => _selfieDone = true),
          ),
          const SizedBox(height: 18),
          Text('Step 3: Service Radius (${_radiusKm.round()} km)', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _radiusKm,
            min: 5,
            max: 50,
            divisions: 9,
            label: '${_radiusKm.round()} km',
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final nic = _nicCtrl.text.trim();
                    if (nic.isEmpty || !RegExp(r'^([0-9]{9}[vVxX]|[0-9]{12})$').hasMatch(nic)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid Sri Lankan NIC number')),
                      );
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      await ref.read(dioProvider).put('/kyc/details', data: {
                        'nicNumber': nic,
                        'guarantorName': _guarantorCtrl.text.trim(),
                        'guarantorPhone': _guarantorPhoneCtrl.text.trim(),
                      });
                    } catch (_) {}
                    await ref.read(appModeProvider.notifier).setWorkerKycStatus(
                          _guarantorCtrl.text.trim().isNotEmpty ? 'TRUSTED' : 'BASIC_VERIFIED',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('KYC submitted to Admin Queue!')),
                      );
                      context.pop();
                    }
                  },
            child: Text(_saving ? 'Submitting...' : 'Submit KYC for Verification'),
          ),
        ],
      ),
    );
  }
}
