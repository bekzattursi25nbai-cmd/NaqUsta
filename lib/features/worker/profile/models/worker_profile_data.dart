class WorkerPortfolioItem {
  final String title;
  final String description;
  final List<String> images;

  const WorkerPortfolioItem({
    required this.title,
    required this.description,
    required this.images,
  });

  factory WorkerPortfolioItem.fromMap(Map<String, dynamic> map) {
    return WorkerPortfolioItem(
      title: _asString(map['title']),
      description: _asString(map['description']),
      images: _asStringList(map['images']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'images': images,
    };
  }
}

class WorkerExperienceItem {
  final String company;
  final String role;
  final String years;
  final String description;

  const WorkerExperienceItem({
    required this.company,
    required this.role,
    required this.years,
    required this.description,
  });

  factory WorkerExperienceItem.fromMap(Map<String, dynamic> map) {
    return WorkerExperienceItem(
      company: _asString(map['company']),
      role: _asString(map['role']),
      years: _asString(map['years']),
      description: _asString(map['description']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'company': company,
      'role': role,
      'years': years,
      'description': description,
    };
  }
}

class WorkerEducationItem {
  final String institution;
  final String degree;
  final String years;
  final String description;

  const WorkerEducationItem({
    required this.institution,
    required this.degree,
    required this.years,
    required this.description,
  });

  factory WorkerEducationItem.fromMap(Map<String, dynamic> map) {
    return WorkerEducationItem(
      institution: _asString(map['institution']),
      degree: _asString(map['degree']),
      years: _asString(map['years']),
      description: _asString(map['description']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'institution': institution,
      'degree': degree,
      'years': years,
      'description': description,
    };
  }
}

class WorkerCertificateItem {
  final String title;
  final String issuer;
  final String year;
  final String description;

  const WorkerCertificateItem({
    required this.title,
    required this.issuer,
    required this.year,
    required this.description,
  });

  factory WorkerCertificateItem.fromMap(Map<String, dynamic> map) {
    return WorkerCertificateItem(
      title: _asString(map['title']),
      issuer: _asString(map['issuer']),
      year: _asString(map['year']),
      description: _asString(map['description']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'issuer': issuer,
      'year': year,
      'description': description,
    };
  }
}

class WorkerServiceItem {
  final String name;
  final String description;
  final String rate;

  const WorkerServiceItem({
    required this.name,
    required this.description,
    required this.rate,
  });

  factory WorkerServiceItem.fromMap(Map<String, dynamic> map) {
    return WorkerServiceItem(
      name: _asString(map['name']),
      description: _asString(map['description']),
      rate: _asString(map['rate']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'rate': rate,
    };
  }
}

class WorkerReviewItem {
  final String author;
  final String text;
  final String date;
  final double rating;

  const WorkerReviewItem({
    required this.author,
    required this.text,
    required this.date,
    required this.rating,
  });

  factory WorkerReviewItem.fromMap(Map<String, dynamic> map) {
    return WorkerReviewItem(
      author: _asString(map['author'], fallback: 'Client'),
      text: _asString(map['text']),
      date: _asString(map['date']),
      rating: _asDouble(map['rating'], fallback: 5.0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'author': author,
      'text': text,
      'date': date,
      'rating': rating,
    };
  }
}

class WorkerProfileData {
  final String id;
  final String fullName;
  final String avatarUrl;
  final String specialty;
  final String bio;
  final String city;
  final String district;
  final String village;
  final String addressNote;
  final String location;
  final String phone;
  final String email;
  final bool showPhone;
  final bool showEmail;
  final bool isPromoted;
  final String hourlyRate;
  final double rating;
  final int reviewCount;
  final int completedOrders;
  final String experience;
  final String availabilityStatus;
  final List<String> availabilitySlots;
  final List<String> skills;
  final List<String> specialties;
  final List<String> primaryCategoryIds;
  final List<String> canDoCategoryIds;
  final List<WorkerPortfolioItem> portfolio;
  final List<WorkerExperienceItem> experiences;
  final List<WorkerEducationItem> educations;
  final List<WorkerCertificateItem> certificates;
  final List<WorkerServiceItem> services;
  final bool hasBrigade;
  final String brigadeName;
  final int? brigadeSize;
  final String brigadeRole;
  final List<WorkerReviewItem> reviews;
  final Map<String, dynamic> raw;

  const WorkerProfileData({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.specialty,
    required this.bio,
    required this.city,
    required this.district,
    required this.village,
    required this.addressNote,
    required this.location,
    required this.phone,
    required this.email,
    required this.showPhone,
    required this.showEmail,
    required this.isPromoted,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.completedOrders,
    required this.experience,
    required this.availabilityStatus,
    required this.availabilitySlots,
    required this.skills,
    required this.specialties,
    required this.primaryCategoryIds,
    required this.canDoCategoryIds,
    required this.portfolio,
    required this.experiences,
    required this.educations,
    required this.certificates,
    required this.services,
    required this.hasBrigade,
    required this.brigadeName,
    required this.brigadeSize,
    required this.brigadeRole,
    required this.reviews,
    required this.raw,
  });

  factory WorkerProfileData.fromMap(Map<String, dynamic> source, String id) {
    final data = Map<String, dynamic>.from(source);
    final experienceRaw = data['experience'] ?? data['experienceYear'];
    final experienceLabel = experienceRaw is int
        ? '${experienceRaw.toString()} yr'
        : _asString(experienceRaw, fallback: '1 yr');

    final parsedReviews = _asMapList(data['reviews'])
        .map(WorkerReviewItem.fromMap)
        .where((item) => item.text.isNotEmpty)
        .toList();

    final parsedServicesFromMap = _asMapList(data['services'])
        .map(WorkerServiceItem.fromMap)
        .where((item) => item.name.isNotEmpty)
        .toList();
    final parsedServicesFromString = _asServiceStringList(data['services'])
        .map((item) => WorkerServiceItem(name: item, description: '', rate: ''))
        .toList();
    final parsedServices = parsedServicesFromMap.isNotEmpty
        ? parsedServicesFromMap
        : parsedServicesFromString;

    final parsedSpecialties = _asStringList(data['specialties']);
    final parsedSkills = _asStringList(data['skills']);
    final parsedTags = _asStringList(data['tags']);
    final parsedPrimaryCategoryIds = _asStringList(data['primaryCategoryIds']);
    final parsedCanDoCategoryIds = _asStringList(
      data['canDoCategoryIds'],
    ).where((id) => !parsedPrimaryCategoryIds.contains(id)).toList();

    final allSkills = <String>{
      ...parsedSpecialties,
      ...parsedSkills,
      ...parsedTags,
    }.where((item) => item.trim().isNotEmpty).toList();
    final effectiveSpecialties = parsedSpecialties.isNotEmpty
        ? parsedSpecialties
        : allSkills;

    final aboutValue = data['bio'] ?? data['about'];
    String aboutText;
    if (aboutValue is List) {
      aboutText = _asStringList(aboutValue).join('\n');
    } else {
      aboutText = _asString(aboutValue);
    }

    final computedRating = _asDouble(data['rating'], fallback: 0.0);
    final reviewCountField = _asInt(data['reviewCount'], fallback: 0);
    final locationMap = _asMap(data['location']);
    final locationShort = _asString(
      data['locationShort'] ??
          data['locationLabel'] ??
          locationMap['shortLabel'],
    );
    final locationFull = _asString(
      data['locationFullLabel'] ?? locationMap['fullLabel'],
    );
    final legacyLocationString = data['location'] is String
        ? _asString(data['location'])
        : '';

    final effectiveReviewCount = reviewCountField > 0
        ? reviewCountField
        : parsedReviews.length;
    final city = _asString(
      data['city'],
      fallback: _asString(locationMap['regionLabel'], fallback: 'Not set'),
    );
    final district = _asString(
      data['district'],
      fallback: _asString(locationMap['districtLabel']),
    );
    final village = _asString(
      data['village'],
      fallback: _asString(
        locationMap['localityLabel'] ?? locationMap['settlementLabel'],
      ),
    );
    final addressNote = _asString(data['addressNote']);

    return WorkerProfileData(
      id: id,
      fullName: _asString(
        data['fullName'] ?? data['firstName'] ?? data['name'],
        fallback: 'No name',
      ),
      avatarUrl: _asString(data['avatarUrl']),
      specialty: _asString(
        data['specialty'],
        fallback: effectiveSpecialties.isNotEmpty
            ? effectiveSpecialties.first
            : 'Specialist',
      ),
      bio: aboutText,
      city: city,
      district: district,
      village: village,
      addressNote: addressNote,
      location: _composeLocationLabel(
        explicitLocation: _firstNonEmpty(<String?>[
          locationShort,
          locationFull,
          legacyLocationString,
        ]),
        city: city,
        district: district,
        village: village,
      ),
      phone: _asString(data['phone']),
      email: _asString(data['email']),
      showPhone: _asBool(data['showPhone']),
      showEmail: _asBool(data['showEmail']),
      isPromoted: _asBool(data['isPromoted'], fallback: true),
      hourlyRate: _asString(
        data['hourlyRate'] ?? data['price'] ?? data['rate'],
        fallback: 'By agreement',
      ),
      rating: computedRating > 0
          ? computedRating
          : _averageRating(parsedReviews, fallback: 5.0),
      reviewCount: effectiveReviewCount,
      completedOrders: _asInt(data['completedOrders'], fallback: 0),
      experience: experienceLabel,
      availabilityStatus: _asString(
        data['availabilityStatus'],
        fallback: 'available',
      ),
      availabilitySlots: _asStringList(data['availabilitySlots']),
      skills: allSkills,
      specialties: effectiveSpecialties,
      primaryCategoryIds: parsedPrimaryCategoryIds,
      canDoCategoryIds: parsedCanDoCategoryIds,
      portfolio: _asMapList(data['portfolio'])
          .map(WorkerPortfolioItem.fromMap)
          .where((item) => item.title.isNotEmpty || item.description.isNotEmpty)
          .toList(),
      experiences: _asMapList(data['experiences'])
          .map(WorkerExperienceItem.fromMap)
          .where((item) => item.company.isNotEmpty || item.role.isNotEmpty)
          .toList(),
      educations: _asMapList(data['educations'])
          .map(WorkerEducationItem.fromMap)
          .where(
            (item) => item.institution.isNotEmpty || item.degree.isNotEmpty,
          )
          .toList(),
      certificates: _asMapList(data['certificates'])
          .map(WorkerCertificateItem.fromMap)
          .where((item) => item.title.isNotEmpty)
          .toList(),
      services: parsedServices,
      hasBrigade: _asBool(data['hasBrigade']),
      brigadeName: _asString(data['brigadeName']),
      brigadeSize: _nullablePositiveInt(data['brigadeSize']),
      brigadeRole: _asString(data['brigadeRole']),
      reviews: parsedReviews,
      raw: data,
    );
  }

  static Map<String, dynamic> fromHomeWorker({
    required String id,
    required String fullName,
    required String avatarUrl,
    required String specialty,
    required String city,
    required String experience,
    required double rating,
    required int completedOrders,
    required int reviewCount,
    required String price,
    required List<String> tags,
    required List<String> about,
  }) {
    return <String, dynamic>{
      'uid': id,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'specialty': specialty,
      'city': city,
      'experience': experience,
      'rating': rating,
      'completedOrders': completedOrders,
      'reviewCount': reviewCount,
      'hourlyRate': price,
      'skills': tags,
      'specialties': tags,
      'primaryCategoryIds': <String>[],
      'canDoCategoryIds': <String>[],
      'about': about,
      'services': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': specialty,
          'description': about.isNotEmpty ? about.first : '',
          'rate': price,
        },
      ],
    };
  }

  static double _averageRating(
    List<WorkerReviewItem> reviews, {
    required double fallback,
  }) {
    if (reviews.isEmpty) return fallback;
    final total = reviews.fold<double>(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final raw = value.toString().toLowerCase();
  if (raw == 'true' || raw == '1' || raw == 'yes') return true;
  if (raw == 'false' || raw == '0' || raw == 'no') return false;
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return <String>[];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return <String>[];
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map(
        (item) =>
            item.map((key, itemValue) => MapEntry(key.toString(), itemValue)),
      )
      .toList()
      .cast<Map<String, dynamic>>();
}

List<String> _asServiceStringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return <String>[];
    return <String>[text];
  }
  return <String>[];
}

int? _nullablePositiveInt(dynamic value) {
  final parsed = _asInt(value, fallback: 0);
  if (parsed <= 0) return null;
  return parsed;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, itemValue) => MapEntry(key.toString(), itemValue));
  }
  return <String, dynamic>{};
}

String _firstNonEmpty(Iterable<String?> values) {
  for (final raw in values) {
    final value = (raw ?? '').trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _composeLocationLabel({
  required String explicitLocation,
  required String city,
  required String district,
  required String village,
}) {
  if (explicitLocation.trim().isNotEmpty) return explicitLocation.trim();
  final parts = <String>[
    city,
    district,
    village,
  ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  if (parts.isEmpty) return 'Not set';
  return parts.join(', ');
}
