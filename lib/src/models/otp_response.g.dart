// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_response.dart';

OtpResponse _$OtpResponseFromJson(Map<String, dynamic> json) => OtpResponse(
  reference: json['reference'],
  message: json['message'] as String?,
  phone: json['phone'] as String?,
  url: json['url'] as String?,
  scheme: json['scheme'] as String?,
);

Map<String, dynamic> _$OtpResponseToJson(OtpResponse instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'message': instance.message,
      'phone': instance.phone,
      'url': instance.url,
      'scheme': instance.scheme,
    };
