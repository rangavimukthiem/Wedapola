import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../data/job_models.dart';

final activeJobProvider = NotifierProvider<ActiveJobNotifier, ActiveJob?>(ActiveJobNotifier.new);
final workerLeadsProvider = NotifierProvider<WorkerLeadsNotifier, List<OpenJobLead>>(WorkerLeadsNotifier.new);

class ActiveJobNotifier extends Notifier<ActiveJob?> {
  static const _cacheKey = 'wedapola_cached_active_job';

  @override
  ActiveJob? build() {
    _restoreFromCache();
    return null;
  }

  Future<void> _restoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        state = ActiveJob.fromJson(jsonDecode(raw));
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(ActiveJob? job) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (job == null) {
        await prefs.remove(_cacheKey);
      } else {
        await prefs.setString(_cacheKey, jsonEncode(job.toJson()));
      }
    } catch (_) {}
  }

  Future<void> postJobRequest({
    required int categoryId,
    required String categoryName,
    required String description,
    required bool equipmentProvided,
    required bool nearHazard,
    required String locationLabel,
  }) async {
    final pin = (1000 + Random().nextInt(9000)).toString();
    final jobId = DateTime.now().millisecondsSinceEpoch % 100000;

    // Best-effort API sync (never blocks offline/guest demo)
    try {
      await ref.read(dioProvider).post('/requests', data: {
        'categoryId': categoryId,
        'description': description,
        'latitude': 6.9271,
        'longitude': 79.8612,
        'equipmentProvided': equipmentProvided,
        'nearHazard': nearHazard,
      });
    } catch (_) {}

    final sampleQuotes = [
      QuoteItem(
        id: 1,
        technicianId: 1,
        technicianName: 'Sunil Wickramasinghe',
        technicianPhone: '+94771234567',
        kycBadge: 'PRO',
        rating: 4.95,
        laborCost: 2500,
        materialCost: 500,
        etaText: '25 mins',
        notes: 'Can arrive immediately with full toolkit & safety gear.',
      ),
      QuoteItem(
        id: 2,
        technicianId: 2,
        technicianName: 'Kusal Perera',
        technicianPhone: '+94719876543',
        kycBadge: 'TRUSTED',
        rating: 4.85,
        laborCost: 2200,
        materialCost: 400,
        etaText: '40 mins',
        notes: 'Experienced with residential & commercial jobs.',
      ),
    ];

    final job = ActiveJob(
      id: jobId,
      categoryName: categoryName,
      description: description,
      status: JobStatus.openForQuotes,
      equipmentProvided: equipmentProvided,
      nearHazard: nearHazard,
      startPin: pin,
      clientName: 'You (Client)',
      clientPhone: '+94771112233',
      locationLabel: locationLabel,
      latitude: 6.9271,
      longitude: 79.8612,
      quotes: sampleQuotes,
    );

    state = job;
    await _saveToCache(job);
  }

  Future<void> acceptQuote(QuoteItem quote) async {
    if (state == null) return;
    final updated = state!.copyWith(
      status: JobStatus.accepted,
      workerName: quote.technicianName,
      workerPhone: quote.technicianPhone,
      workerKycBadge: quote.kycBadge,
      workerRating: quote.rating,
      baseQuoteTotal: quote.total,
    );
    state = updated;
    await _saveToCache(updated);
  }

  Future<void> markOnTheWay() async {
    if (state == null) return;
    final updated = state!.copyWith(status: JobStatus.onTheWay);
    state = updated;
    await _saveToCache(updated);
  }

  Future<void> markArrived() async {
    if (state == null) return;
    final updated = state!.copyWith(status: JobStatus.arrived);
    state = updated;
    await _saveToCache(updated);
  }

  Future<bool> verifyPinAndStart(String enteredPin) async {
    if (state == null) return false;
    if (enteredPin.trim() != state!.startPin) {
      return false;
    }
    final updated = state!.copyWith(
      status: JobStatus.inProgress,
      startedAt: DateTime.now(),
    );
    state = updated;
    await _saveToCache(updated);
    return true;
  }

  Future<void> requestExtraCost(double amount, String reason) async {
    if (state == null) return;
    final updated = state!.copyWith(
      pendingExtraCost: amount,
      pendingExtraReason: reason,
    );
    state = updated;
    await _saveToCache(updated);
  }

  Future<void> approveExtraCost(bool approve) async {
    if (state == null) return;
    final updated = state!.copyWith(
      approvedExtraCost: approve ? state!.approvedExtraCost + state!.pendingExtraCost : state!.approvedExtraCost,
      clearPendingExtra: true,
    );
    state = updated;
    await _saveToCache(updated);
  }

  Future<void> markAfterPhotoAndComplete() async {
    if (state == null) return;
    final updated = state!.copyWith(
      afterPhotoUploaded: true,
      status: JobStatus.pendingPayment,
    );
    state = updated;
    await _saveToCache(updated);
  }

  Future<void> confirmPayment() async {
    if (state == null) return;
    final updated = state!.copyWith(status: JobStatus.completed);
    state = updated;
    await _saveToCache(updated);
  }

  Future<void> submitReview({required bool isClient}) async {
    if (state == null) return;
    final updated = state!.copyWith(
      clientReviewed: isClient ? true : state!.clientReviewed,
      workerReviewed: !isClient ? true : state!.workerReviewed,
      status: isClient ? JobStatus.reviewed : state!.status,
    );
    state = updated;
    await _saveToCache(updated);
  }

  Future<void> clearJob() async {
    state = null;
    await _saveToCache(null);
  }
}

class WorkerLeadsNotifier extends Notifier<List<OpenJobLead>> {
  @override
  List<OpenJobLead> build() {
    return const [
      OpenJobLead(
        requestId: 501,
        categoryName: 'Electrical & Wiring',
        description: 'Main trip switch keeps tripping whenever water pump turns on.',
        areaName: 'Colombo 05 · Havelock Town',
        distanceKm: 2.1,
        equipmentProvided: false,
        nearHazard: false,
        urgency: 'HIGH',
      ),
      OpenJobLead(
        requestId: 502,
        categoryName: 'Tree Pruning & Felling',
        description: 'Large coconut & mango branches overhanging roof near CEB wire.',
        areaName: 'Nugegoda · Nawala',
        distanceKm: 4.3,
        equipmentProvided: false,
        nearHazard: true,
        urgency: 'EMERGENCY',
      ),
      OpenJobLead(
        requestId: 503,
        categoryName: 'Plumbing & Water Systems',
        description: 'Overhead 1000L tank ball-valve leaking, ladder available on site.',
        areaName: 'Dehiwala · Mount Lavinia',
        distanceKm: 5.8,
        equipmentProvided: true,
        nearHazard: false,
        urgency: 'MEDIUM',
      ),
    ];
  }

  void markQuoted(int requestId) {
    state = [
      for (final lead in state)
        if (lead.requestId == requestId) lead.copyWith(quoteSubmitted: true) else lead,
    ];
  }
}
