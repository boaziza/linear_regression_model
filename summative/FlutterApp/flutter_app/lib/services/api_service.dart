import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl = 'https://rwanda-youth-wage-api.onrender.com';

  static Future<double> predict({
    required int age,
    required String sex,
    required String area,
    required String province,
    required String povertyStatus,
    required bool attendedSchool,
    required String quintile,
    required String education,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'age': age,
              'sex': sex,
              'area': area,
              'province': province,
              'poverty_status': povertyStatus,
              'attended_school_last_12m': attendedSchool,
              'consumption_quintile': quintile,
              'education_level': education,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw PredictionException(
          'Could not reach the server. Check your connection and try again.');
    }

    if (response.statusCode != 200 && response.statusCode != 400) {
      throw PredictionException(
          'Server error (${response.statusCode}). Please try again.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 400) {
      final detail = data['detail'];
      if (detail is List) {
        throw PredictionException(
            detail.map((e) => '${e['field']}: ${e['message']}').join('\n'));
      }
      throw PredictionException(detail.toString());
    }

    return (data['predicted_monthly_income_rwf'] as num).toDouble();
  }
}

class PredictionException implements Exception {
  final String message;
  PredictionException(this.message);

  @override
  String toString() => message;
}
