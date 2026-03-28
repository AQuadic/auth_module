import 'package:aq_tools/aq_tools.dart';
import 'package:json_annotation/json_annotation.dart';

class ResponsiveImageModelJsonConv
    extends JsonConverter<ResponsiveImageModel, Map<String, dynamic>> {
  const ResponsiveImageModelJsonConv();

  @override
  ResponsiveImageModel fromJson(Map<String, dynamic>? json) {
    return ResponsiveImageModel.fromResponsiveJson(json ?? {});
  }

  @override
  Map<String, dynamic> toJson(ResponsiveImageModel object) {
    return <String, dynamic>{};
  }
}
