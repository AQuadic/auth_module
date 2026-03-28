// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num?)?.toInt(),
  image: _$JsonConverterFromJson<Map<String, dynamic>, ResponsiveImageModel>(
    json['image'],
    const ResponsiveImageModelJsonConv().fromJson,
  ),
  name: json['name'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  type: json['type'] as String?,
  phoneNormalized: json['phone_normalized'] as String?,
  phoneE164: json['phone_e164'] as String?,
  phoneCountry: json['phone_country'] as String?,
  phoneNational: json['phone_national'] as String?,
  emailVerifiedAt: json['email_verified_at'] as String?,
  phoneVerifiedAt: json['phone_verified_at'] as String?,
  infoVerifiedAt: json['info_verified_at'] as String?,
  accountTypeId: json['account_type_id'],
  bio: json['bio'] as String?,
  language: json['language'] as String?,
  verificationStatus: json['verification_status'] as String?,
  cityId: (json['city_id'] as num?)?.toInt(),
  cityName: json['city_name'] as String?,
  countryId: (json['country_id'] as num?)?.toInt(),
  countryName: json['country_name'] as String?,
  whatsapp: json['whatsapp'] as String?,
  birthday: json['birthday'] == null
      ? null
      : DateTime.parse(json['birthday'] as String),
  gender: json['gender'] as String?,
  cover: _$JsonConverterFromJson<Map<String, dynamic>, ResponsiveImageModel>(
    json['cover'],
    const ResponsiveImageModelJsonConv().fromJson,
  ),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  unreadNotificationsCount: json['unread_notifications_count'] as num?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'image': _$JsonConverterToJson<Map<String, dynamic>, ResponsiveImageModel>(
    instance.image,
    const ResponsiveImageModelJsonConv().toJson,
  ),
  'cover': _$JsonConverterToJson<Map<String, dynamic>, ResponsiveImageModel>(
    instance.cover,
    const ResponsiveImageModelJsonConv().toJson,
  ),
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'phone_national': instance.phoneNational,
  'type': instance.type,
  'phone_normalized': instance.phoneNormalized,
  'phone_e164': instance.phoneE164,
  'phone_country': instance.phoneCountry,
  'email_verified_at': instance.emailVerifiedAt,
  'phone_verified_at': instance.phoneVerifiedAt,
  'info_verified_at': instance.infoVerifiedAt,
  'account_type_id': instance.accountTypeId,
  'bio': instance.bio,
  'language': instance.language,
  'city_id': instance.cityId,
  'city_name': instance.cityName,
  'country_id': instance.countryId,
  'country_name': instance.countryName,
  'verification_status': instance.verificationStatus,
  'unread_notifications_count': instance.unreadNotificationsCount,
  'whatsapp': instance.whatsapp,
  'birthday': instance.birthday?.toIso8601String(),
  'gender': instance.gender,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
