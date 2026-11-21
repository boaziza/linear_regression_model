import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/constants/form_options.dart';
import 'package:flutter_app/services/api_service.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _povertyController = TextEditingController();
  final TextEditingController _quintileController = TextEditingController();

  bool _isLoading = false;
  double? _prediction;
  String? _errorMessage;

  String _toApiValue(TextEditingController controller, Map<String, String> options) {
    final typed = controller.text.trim();
    for (final entry in options.entries) {
      if (entry.key.toLowerCase() == typed.toLowerCase() ||
          entry.value.toLowerCase() == typed.toLowerCase()) {
        return entry.key;
      }
    }
    return typed;
  }

  // Hint under each field listing the values it accepts
  String _allowed(Map<String, String> options) => options.values.join(', ');

  // Design: which status the result card shows
  bool get _ageHasError => _errorMessage?.startsWith('age') ?? false;
  String get _statusText => _prediction != null
      ? '● ESTIMATE'
      : (_errorMessage != null ? '● ERROR' : '● NOT RUN');
  Color get _statusColor => _prediction != null
      ? const Color(0xFF1E7B4A)
      : (_errorMessage != null
          ? const Color(0xFFB42318)
          : const Color(0xFF6E6E73));

  // Design: text styles reused by the labels
  static const _sectionStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: Color(0xFF6E6E73));
  static const _labelStyle = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111111));

  // Design: one look for the text fields
  static const _fieldDecoration = InputDecoration(
    helperMaxLines: 2,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFFD9D9DE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Color(0xFF111111), width: 2),
    ),
  );

  // Design: white card with a thin border
  static final _cardDecoration = BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFE8E8EA)),
    borderRadius: BorderRadius.circular(16),
  );

  @override
  void dispose() {
    _ageController.dispose();
    _sexController.dispose();
    _schoolController.dispose();
    _educationController.dispose();
    _areaController.dispose();
    _provinceController.dispose();
    _povertyController.dispose();
    _quintileController.dispose();
    super.dispose();
  }

  // Label + text field with a hint, used for every input
  Widget _textInput(String label, TextEditingController controller,
      String hint, String helper,
      {TextInputType keyboard = TextInputType.text, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 16, color: Color(0xFF111111)),
            decoration: _fieldDecoration.copyWith(
              hintText: hint,
              helperText: helper,
              errorText: errorText,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    // Missing values
    final fields = {
      'Age': _ageController,
      'Sex': _sexController,
      'Attended school': _schoolController,
      'Highest school level': _educationController,
      'Area': _areaController,
      'Province': _provinceController,
      'Poverty status': _povertyController,
      'Consumption quintile': _quintileController,
    };
    final missing = fields.entries
        .where((field) => field.value.text.trim().isEmpty)
        .map((field) => field.key)
        .toList();
    if (missing.isNotEmpty) {
      setState(() {
        _prediction = null;
        _errorMessage = 'Please fill in: ${missing.join(', ')}.';
      });
      return;
    }

    // Wrong type for age
    final age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      setState(() {
        _prediction = null;
        _errorMessage = 'Age must be a whole number.';
      });
      return;
    }

    final school = _toApiValue(_schoolController, schoolOptions);

    setState(() {
      _isLoading = true;
      _prediction = null;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.predict(
        age: age,
        sex: _toApiValue(_sexController, sexOptions),
        area: _toApiValue(_areaController, areaOptions),
        province: _toApiValue(_provinceController, provinces),
        povertyStatus: _toApiValue(_povertyController, povertyOptions),
        attendedSchool:
            school == 'Yes' ? true : (school == 'No' ? false : school),
        quintile: _toApiValue(_quintileController, quintileOptions),
        education: _toApiValue(_educationController, educationOptions),
      );
      setState(() => _prediction = result);
    } on PredictionException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (replaces the AppBar)
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('W',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Wage Predictor',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111))),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Monthly income',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Color(0xFF111111))),
              const SizedBox(height: 4),
              const Text(
                  'Estimate the monthly income of an employed youth (16–30) in Rwanda, based on NISR household survey data.',
                  style: TextStyle(
                      fontSize: 14, height: 1.4, color: Color(0xFF6E6E73))),
              const SizedBox(height: 20),

              // Profile
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PROFILE', style: _sectionStyle),
                      const SizedBox(height: 12),
                      _textInput('Age', _ageController, 'e.g. 25', '16–30 years',
                          keyboard: TextInputType.number,
                          errorText: _ageHasError ? 'Must be 16–30' : null),
                      _textInput('Sex', _sexController, 'e.g. Female',
                          _allowed(sexOptions)),
                      _textInput('Attended school in the last 12 months',
                          _schoolController, 'e.g. No', _allowed(schoolOptions)),
                      _textInput('Highest school level attended',
                          _educationController, 'e.g. Primary',
                          _allowed(educationOptions)),
                    ],
                  ),
                ),
              ),

              // Location
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOCATION', style: _sectionStyle),
                      const SizedBox(height: 12),
                      _textInput('Area', _areaController, 'e.g. Urban',
                          _allowed(areaOptions)),
                      _textInput('Province', _provinceController,
                          'e.g. City of Kigali', _allowed(provinces)),
                    ],
                  ),
                ),
              ),

              // Household welfare
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HOUSEHOLD WELFARE', style: _sectionStyle),
                      const SizedBox(height: 12),
                      _textInput('Poverty status', _povertyController,
                          'e.g. Non poor', _allowed(povertyOptions)),
                      _textInput('Consumption quintile', _quintileController,
                          'e.g. Mid', _allowed(quintileOptions)),
                    ],
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: _isLoading ? null : _predict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF555555),
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Predict'),
              ),
              const SizedBox(height: 20),

              // Result card (replaces the two result Text lines)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Status',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111111))),
                        ),
                        Text(_statusText,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: _statusColor)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _prediction != null
                          ? 'RWF ${NumberFormat('#,##0').format(_prediction)}'
                          : 'RWF —',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: _prediction != null
                              ? const Color(0xFF111111)
                              : const Color(0xFF6E6E73)),
                    ),
                    const SizedBox(height: 4),
                    const Text('ESTIMATED MONTHLY INCOME',
                        style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 0.5,
                            color: Color(0xFF6E6E73))),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFEFEFF1)),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFFB42318)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Linear regression trained on 1,381 survey responses. '
                'Individual wages vary widely around the estimate.',
                style: TextStyle(
                    fontSize: 12, height: 1.5, color: Color(0xFF6E6E73)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
