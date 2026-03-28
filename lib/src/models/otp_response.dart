import 'package:json_annotation/json_annotation.dart';

part 'otp_response.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class OtpResponse {
  dynamic reference;
  String? message;
  String? phone;
  String? url;
  String? scheme;

  OtpResponse({
    this.reference,
    this.message,
    this.phone,
    this.url,
    this.scheme,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return _$OtpResponseFromJson(json);
  }

  Map<String, dynamic> toJson() => _$OtpResponseToJson(this);
}
