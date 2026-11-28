import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class ServiceCategory {
  final int id;
  final String nameEn;
  final String nameSi;
  final String groupNameEn;

  const ServiceCategory({
    required this.id,
    required this.nameEn,
    required this.nameSi,
    required this.groupNameEn,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nameEn: json['name_en']?.toString() ?? '',
      nameSi: json['name_si']?.toString() ?? '',
      groupNameEn: json['group_name_en']?.toString() ?? '',
    );
  }
}

class TechnicianItem {
  final int id;
  final String name;
  final String phone;
  final String bio;
  final String verificationStatus;
  final double rating;
  final int totalReviews;
  final int completedJobsCount;
  final double? distance;
  final List<String> categoryNames;

  const TechnicianItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.bio,
    required this.verificationStatus,
    required this.rating,
    required this.totalReviews,
    required this.completedJobsCount,
    this.distance,
    required this.categoryNames,
  });

  factory TechnicianItem.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final List<String> catNames = [];
    if (rawCats is List) {
      for (final c in rawCats) {
        if (c is Map && c['name_en'] != null) {
          catNames.add(c['name_en'].toString());
        } else if (c is String) {
          catNames.add(c);
        }
      }
    }

    return TechnicianItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? 'Worker',
      phone: json['phone']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      verificationStatus: json['verification_status']?.toString() ?? 'BASIC_VERIFIED',
      rating: double.tryParse('${json['rating'] ?? 0}') ?? 0.0,
      totalReviews: int.tryParse('${json['total_reviews'] ?? 0}') ?? 0,
      completedJobsCount: int.tryParse('${json['completed_jobs_count'] ?? 0}') ?? 0,
      distance: json['distance'] != null ? double.tryParse('${json['distance']}') : null,
      categoryNames: catNames,
    );
  }
}

final homeRepositoryProvider = Provider((ref) => HomeRepository(ref.watch(dioProvider)));

class HomeRepository {
  final Dio _dio;
  HomeRepository(this._dio);

  static const List<ServiceCategory> _fallbackCategories = [
    ServiceCategory(id: 14, nameEn: 'Electrical & Wiring', nameSi: 'විදුලි කාර්මික', groupNameEn: 'Core Technical Trades'),
    ServiceCategory(id: 15, nameEn: 'Plumbing & Water Systems', nameSi: 'ජලනල කාර්මික', groupNameEn: 'Core Technical Trades'),
    ServiceCategory(id: 16, nameEn: 'AC & Refrigeration', nameSi: 'වායු සමීකරණ', groupNameEn: 'Core Technical Trades'),
    ServiceCategory(id: 1, nameEn: 'Tree Pruning & Felling', nameSi: 'ගස් කැපීම', groupNameEn: 'Garden & Estate'),
    ServiceCategory(id: 5, nameEn: 'Deep House Cleaning', nameSi: 'නිවෙස් පිරිසිදු කිරීම', groupNameEn: 'Cleaning'),
    ServiceCategory(id: 9, nameEn: 'Mobile Mechanic', nameSi: 'වාහන අලුත්වැඩියාව', groupNameEn: 'Vehicle Care'),
    ServiceCategory(id: 18, nameEn: 'Masonry & Tiling', nameSi: 'පෙදරේරු සහ ටයිල්', groupNameEn: 'Construction'),
  ];

  static const List<TechnicianItem> _fallbackTechnicians = [
    TechnicianItem(
      id: 1,
      name: 'Sunil Wickramasinghe',
      phone: '+94771234567',
      bio: 'Certified Master Electrician with 14+ years experience. Panel boards, short-circuit diagnostics, solar inverter wiring.',
      verificationStatus: 'PRO',
      rating: 4.95,
      totalReviews: 64,
      completedJobsCount: 82,
      distance: 1.8,
      categoryNames: ['Electrical & Wiring', 'AC & Refrigeration'],
    ),
    TechnicianItem(
      id: 2,
      name: 'Kusal Perera',
      phone: '+94719876543',
      bio: 'Expert plumbing contractor. Leak detection, bathroom fittings, water pump & overhead tank repairs.',
      verificationStatus: 'TRUSTED',
      rating: 4.88,
      totalReviews: 42,
      completedJobsCount: 55,
      distance: 3.2,
      categoryNames: ['Plumbing & Water Systems'],
    ),
    TechnicianItem(
      id: 3,
      name: 'Nuwan Bandara',
      phone: '+94765432109',
      bio: 'Tree cutting, coconut harvesting, garden landscaping & grass clearing with safety equipment.',
      verificationStatus: 'PRO',
      rating: 4.92,
      totalReviews: 37,
      completedJobsCount: 49,
      distance: 4.5,
      categoryNames: ['Tree Pruning & Felling'],
    ),
  ];

  Future<List<ServiceCategory>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.data is List && (response.data as List).isNotEmpty) {
        return (response.data as List)
            .map((e) => ServiceCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return _fallbackCategories;
  }

  Future<List<TechnicianItem>> getAvailableTechnicians({
    int? categoryId,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{'radius': 50};
      if (categoryId != null) query['categoryId'] = categoryId;
      if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();

      final response = await _dio.get('/technicians/available', queryParameters: query);
      final raw = response.data is Map ? response.data['data'] : response.data;
      if (raw is List) {
        return raw.map((e) => TechnicianItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Local fallback filter if API is unreachable
    return _fallbackTechnicians.where((t) {
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        final match = t.name.toLowerCase().contains(q) ||
            t.bio.toLowerCase().contains(q) ||
            t.categoryNames.any((c) => c.toLowerCase().contains(q));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> submitInquiry({
    required String customerName,
    required String customerPhone,
    required String description,
    int? technicianId,
    int? categoryId,
    String urgency = 'MEDIUM',
  }) async {
    await _dio.post('/technicians/inquiry', data: {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'description': description,
      'technicianId': technicianId,
      'categoryId': categoryId,
      'urgency': urgency,
    });
  }
}
