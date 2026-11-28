enum JobStatus {
  openForQuotes,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  pendingPayment,
  completed,
  reviewed,
}

extension JobStatusX on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.openForQuotes:
        return 'Open for Quotes';
      case JobStatus.accepted:
        return 'Accepted';
      case JobStatus.onTheWay:
        return 'Worker On The Way';
      case JobStatus.arrived:
        return 'Arrived at Site';
      case JobStatus.inProgress:
        return 'Work In Progress';
      case JobStatus.pendingPayment:
        return 'Pending Payment';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.reviewed:
        return 'Reviewed';
    }
  }
}

class QuoteItem {
  final int id;
  final int technicianId;
  final String technicianName;
  final String technicianPhone;
  final String kycBadge;
  final double rating;
  final double laborCost;
  final double materialCost;
  final String etaText;
  final String notes;

  const QuoteItem({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.technicianPhone,
    required this.kycBadge,
    required this.rating,
    required this.laborCost,
    required this.materialCost,
    required this.etaText,
    required this.notes,
  });

  double get total => laborCost + materialCost;

  Map<String, dynamic> toJson() => {
        'id': id,
        'technicianId': technicianId,
        'technicianName': technicianName,
        'technicianPhone': technicianPhone,
        'kycBadge': kycBadge,
        'rating': rating,
        'laborCost': laborCost,
        'materialCost': materialCost,
        'etaText': etaText,
        'notes': notes,
      };

  factory QuoteItem.fromJson(Map<String, dynamic> json) => QuoteItem(
        id: json['id'] ?? 0,
        technicianId: json['technicianId'] ?? 0,
        technicianName: json['technicianName'] ?? '',
        technicianPhone: json['technicianPhone'] ?? '',
        kycBadge: json['kycBadge'] ?? 'BASIC_VERIFIED',
        rating: (json['rating'] ?? 4.8).toDouble(),
        laborCost: (json['laborCost'] ?? 0).toDouble(),
        materialCost: (json['materialCost'] ?? 0).toDouble(),
        etaText: json['etaText'] ?? '30 mins',
        notes: json['notes'] ?? '',
      );
}

class OpenJobLead {
  final int requestId;
  final String categoryName;
  final String description;
  final String areaName;
  final double distanceKm;
  final bool equipmentProvided;
  final bool nearHazard;
  final String urgency;
  final bool quoteSubmitted;

  const OpenJobLead({
    required this.requestId,
    required this.categoryName,
    required this.description,
    required this.areaName,
    required this.distanceKm,
    required this.equipmentProvided,
    required this.nearHazard,
    required this.urgency,
    this.quoteSubmitted = false,
  });

  OpenJobLead copyWith({bool? quoteSubmitted}) => OpenJobLead(
        requestId: requestId,
        categoryName: categoryName,
        description: description,
        areaName: areaName,
        distanceKm: distanceKm,
        equipmentProvided: equipmentProvided,
        nearHazard: nearHazard,
        urgency: urgency,
        quoteSubmitted: quoteSubmitted ?? this.quoteSubmitted,
      );
}

class ActiveJob {
  final int id;
  final String categoryName;
  final String description;
  final JobStatus status;
  final bool equipmentProvided;
  final bool nearHazard;
  final String startPin;
  final String clientName;
  final String clientPhone;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final String? workerName;
  final String? workerPhone;
  final String? workerKycBadge;
  final double? workerRating;
  final double baseQuoteTotal;
  final double pendingExtraCost;
  final String? pendingExtraReason;
  final double approvedExtraCost;
  final bool afterPhotoUploaded;
  final DateTime? startedAt;
  final List<QuoteItem> quotes;
  final bool clientReviewed;
  final bool workerReviewed;

  const ActiveJob({
    required this.id,
    required this.categoryName,
    required this.description,
    required this.status,
    required this.equipmentProvided,
    required this.nearHazard,
    required this.startPin,
    required this.clientName,
    required this.clientPhone,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    this.workerName,
    this.workerPhone,
    this.workerKycBadge,
    this.workerRating,
    this.baseQuoteTotal = 0,
    this.pendingExtraCost = 0,
    this.pendingExtraReason,
    this.approvedExtraCost = 0,
    this.afterPhotoUploaded = false,
    this.startedAt,
    this.quotes = const [],
    this.clientReviewed = false,
    this.workerReviewed = false,
  });

  double get finalBillTotal => baseQuoteTotal + approvedExtraCost;

  ActiveJob copyWith({
    JobStatus? status,
    String? workerName,
    String? workerPhone,
    String? workerKycBadge,
    double? workerRating,
    double? baseQuoteTotal,
    double? pendingExtraCost,
    String? pendingExtraReason,
    bool clearPendingExtra = false,
    double? approvedExtraCost,
    bool? afterPhotoUploaded,
    DateTime? startedAt,
    List<QuoteItem>? quotes,
    bool? clientReviewed,
    bool? workerReviewed,
  }) {
    return ActiveJob(
      id: id,
      categoryName: categoryName,
      description: description,
      status: status ?? this.status,
      equipmentProvided: equipmentProvided,
      nearHazard: nearHazard,
      startPin: startPin,
      clientName: clientName,
      clientPhone: clientPhone,
      locationLabel: locationLabel,
      latitude: latitude,
      longitude: longitude,
      workerName: workerName ?? this.workerName,
      workerPhone: workerPhone ?? this.workerPhone,
      workerKycBadge: workerKycBadge ?? this.workerKycBadge,
      workerRating: workerRating ?? this.workerRating,
      baseQuoteTotal: baseQuoteTotal ?? this.baseQuoteTotal,
      pendingExtraCost: clearPendingExtra ? 0 : (pendingExtraCost ?? this.pendingExtraCost),
      pendingExtraReason: clearPendingExtra ? null : (pendingExtraReason ?? this.pendingExtraReason),
      approvedExtraCost: approvedExtraCost ?? this.approvedExtraCost,
      afterPhotoUploaded: afterPhotoUploaded ?? this.afterPhotoUploaded,
      startedAt: startedAt ?? this.startedAt,
      quotes: quotes ?? this.quotes,
      clientReviewed: clientReviewed ?? this.clientReviewed,
      workerReviewed: workerReviewed ?? this.workerReviewed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryName': categoryName,
        'description': description,
        'status': status.index,
        'equipmentProvided': equipmentProvided,
        'nearHazard': nearHazard,
        'startPin': startPin,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'locationLabel': locationLabel,
        'latitude': latitude,
        'longitude': longitude,
        'workerName': workerName,
        'workerPhone': workerPhone,
        'workerKycBadge': workerKycBadge,
        'workerRating': workerRating,
        'baseQuoteTotal': baseQuoteTotal,
        'pendingExtraCost': pendingExtraCost,
        'pendingExtraReason': pendingExtraReason,
        'approvedExtraCost': approvedExtraCost,
        'afterPhotoUploaded': afterPhotoUploaded,
        'startedAt': startedAt?.toIso8601String(),
        'quotes': quotes.map((q) => q.toJson()).toList(),
        'clientReviewed': clientReviewed,
        'workerReviewed': workerReviewed,
      };

  factory ActiveJob.fromJson(Map<String, dynamic> json) => ActiveJob(
        id: json['id'] ?? 0,
        categoryName: json['categoryName'] ?? '',
        description: json['description'] ?? '',
        status: JobStatus.values[(json['status'] ?? 0) as int],
        equipmentProvided: json['equipmentProvided'] ?? false,
        nearHazard: json['nearHazard'] ?? false,
        startPin: json['startPin'] ?? '4829',
        clientName: json['clientName'] ?? 'Customer',
        clientPhone: json['clientPhone'] ?? '+94770000000',
        locationLabel: json['locationLabel'] ?? 'Colombo 05',
        latitude: (json['latitude'] ?? 6.8906).toDouble(),
        longitude: (json['longitude'] ?? 79.8744).toDouble(),
        workerName: json['workerName'],
        workerPhone: json['workerPhone'],
        workerKycBadge: json['workerKycBadge'],
        workerRating: json['workerRating'] != null ? (json['workerRating'] as num).toDouble() : null,
        baseQuoteTotal: (json['baseQuoteTotal'] ?? 0).toDouble(),
        pendingExtraCost: (json['pendingExtraCost'] ?? 0).toDouble(),
        pendingExtraReason: json['pendingExtraReason'],
        approvedExtraCost: (json['approvedExtraCost'] ?? 0).toDouble(),
        afterPhotoUploaded: json['afterPhotoUploaded'] ?? false,
        startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
        quotes: (json['quotes'] as List? ?? [])
            .map((q) => QuoteItem.fromJson(Map<String, dynamic>.from(q)))
            .toList(),
        clientReviewed: json['clientReviewed'] ?? false,
        workerReviewed: json['workerReviewed'] ?? false,
      );
}
