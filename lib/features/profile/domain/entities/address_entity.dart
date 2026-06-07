import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String region;
  final String postalCode;
  final String country;
  final bool isDefault;

  const AddressEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    this.region = '',
    this.postalCode = '',
    this.country = 'Egypt',
    this.isDefault = false,
  });

  String get formatted {
    return [
      line1,
      if (line2.isNotEmpty) line2,
      city,
      if (region.isNotEmpty) region,
      if (postalCode.isNotEmpty) postalCode,
      country,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  String get normalizedCity => city.trim().toLowerCase();
  String get normalizedRegion => region.trim().toLowerCase();

  AddressEntity copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? region,
    String? postalCode,
    String? country,
    bool? isDefault,
  }) {
    return AddressEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      region: region ?? this.region,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        line1,
        line2,
        city,
        region,
        postalCode,
        country,
        isDefault,
      ];
}
