import 'package:aq_tools/aq_tools.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'responsive_image_model_json_conv.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class UserModel {
  int? id;

  @ResponsiveImageModelJsonConv()
  ResponsiveImageModel? image;

  @ResponsiveImageModelJsonConv()
  ResponsiveImageModel? cover;

  String? name;
  String? email;
  String? phone;
  String? type;
  LangModel? position;
  String? phoneNormalized;
  String? phoneNational;
  String? phoneE164;
  String? phoneCountry;
  String? emailVerifiedAt;
  String? phoneVerifiedAt;
  String? infoVerifiedAt;
  dynamic accountTypeId;
  String? bio;
  String? language;
  int? cityId;
  String? cityName;
  int? countryId;
  String? countryName;
  String? verificationStatus;
  num? unreadNotificationsCount;
  String? whatsapp;
  DateTime? birthday;
  String? gender;
  String? createdAt;
  String? updatedAt;

  bool get isDefaultName {
    final value = name?.trim().toLowerCase() ?? '';
    return value.isEmpty || value.contains('user');
  }

  bool get isVerified => phoneVerifiedAt != null || emailVerifiedAt != null;

  UserModel({
    this.id,
    this.image,
    this.cover,
    this.name,
    this.email,
    this.phone,
    this.type,
    this.position,
    this.phoneNormalized,
    this.phoneNational,
    this.phoneE164,
    this.phoneCountry,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.infoVerifiedAt,
    this.accountTypeId,
    this.bio,
    this.language,
    this.cityId,
    this.cityName,
    this.countryId,
    this.countryName,
    this.verificationStatus,
    this.unreadNotificationsCount,
    this.whatsapp,
    this.createdAt,
    this.updatedAt,
    this.birthday,
    this.gender
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? token,
    String? resetPassToken,
  }) {
    if (token != null && token.isNotEmpty) {
      saveToken(token);
    }
    if (resetPassToken != null && resetPassToken.isNotEmpty) {
      saveResetPassToken(resetPassToken);
    }
    return _$UserModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  static Future<String?> get getToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> get getResetPassToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('resetPassToken');
  }

  static Future<bool> get isLoggedIn async => await getToken != null;

  static Future<void> saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove('token');
      return;
    }
    await prefs.setString('token', token);
  }

  static Future<void> saveResetPassToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resetPassToken', token);
  }
}
