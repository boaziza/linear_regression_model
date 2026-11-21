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
  List<bool> _sexSelection = [true, false];
  List<bool> _areaSelection = [true, false];
  bool _attendedSchool = false;

  String? _selectedProvince = 'City of Kigali';
  String? _selectedPoverty = 'Non Poor';
  String? _selectedQuintile = 'Mid';
  String? _selectedEducation = 'Primary';

  bool _isLoading = false;
  double? _prediction;
  String? _errorMessage;

  String get _sex => _sexSelection[0] ? 'Female' : 'Male';
  String get _area => _areaSelection[0] ? 'Urban' : 'Rural';

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

  // Design: one look for the three dropdowns
  static const _dropdownDecoration = InputDecoration(
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

  final TextEditingController _ageController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus();

    final age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      setState(() {
        _prediction = null;
        _errorMessage = _ageController.text.trim().isEmpty
            ? 'Please enter an age.'
            : 'Age must be a whole number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _prediction = null;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.predict(
        age: age,
        sex: _sex,
        area: _area,
        province: _selectedProvince!,
        povertyStatus: _selectedPoverty!,
        attendedSchool: _attendedSchool,
        quintile: _selectedQuintile!,
        education: _selectedEducation!,
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
                      const Text('Age', style: _labelStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF111111)),
                          decoration: InputDecoration(
                            hintText: 'e.g. 25',
                            helperText: '16–30 years',
                            errorText: _ageHasError ? 'Must be 16–30' : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: Color(0xFFD9D9DE)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide:
                                  BorderSide(color: Color(0xFF111111), width: 2),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide:
                                  BorderSide(color: Color(0xFFB42318), width: 2),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide:
                                  BorderSide(color: Color(0xFFB42318), width: 2),
                            ),
                          ),
                          onSubmitted: null,
                        ),
                      ),
                      const Text('Sex', style: _labelStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ToggleButtons(
                            isSelected: _sexSelection,
                            onPressed: (int index) {
                              setState(() {
                                _sexSelection = [index == 0, index == 1];
                              });
                            },
                            renderBorder: false,
                            borderRadius: BorderRadius.circular(6),
                            fillColor: Colors.white,
                            selectedColor: const Color(0xFF111111),
                            color: const Color(0xFF6E6E73),
                            textStyle: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                            constraints:
                                const BoxConstraints(minHeight: 38, minWidth: 90),
                            children: const [Text('Female'), Text('Male')],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Attended school in the last 12 months',
                                style: _labelStyle),
                          ),
                          Switch(
                            value: _attendedSchool,
                            onChanged: (bool value) {
                              setState(() {
                                _attendedSchool = value;
                              });
                            },
                            activeTrackColor: const Color(0xFF111111),
                            activeThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFD9D9DE),
                            inactiveThumbColor: Colors.white,
                            trackOutlineColor:
                                const WidgetStatePropertyAll(Colors.transparent),
                          ),
                        ],
                      ),
                      const Text('Highest school level attended',
                          style: _labelStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedEducation,
                          decoration: _dropdownDecoration,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF6E6E73)),
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF111111)),
                          items: educationOptions.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEducation = newValue;
                            });
                          },
                        ),
                      ),
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
                      const Text('Area', style: _labelStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ToggleButtons(
                            isSelected: _areaSelection,
                            onPressed: (int index) {
                              setState(() {
                                _areaSelection = [index == 0, index == 1];
                              });
                            },
                            renderBorder: false,
                            borderRadius: BorderRadius.circular(6),
                            fillColor: Colors.white,
                            selectedColor: const Color(0xFF111111),
                            color: const Color(0xFF6E6E73),
                            textStyle: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                            constraints:
                                const BoxConstraints(minHeight: 38, minWidth: 90),
                            children: const [Text('Urban'), Text('Rural')],
                          ),
                        ),
                      ),
                      const Text('Province', style: _labelStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProvince,
                          decoration: _dropdownDecoration,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF6E6E73)),
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF111111)),
                          // Builds the list of items from the array
                          items: provinces.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          // Updates the state when the user selects a new option
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedProvince = newValue;
                            });
                          },
                        ),
                      ),
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
                      const Text('Poverty status', style: _labelStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPoverty,
                          decoration: _dropdownDecoration,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF6E6E73)),
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF111111)),
                          // Builds the list of items from the array
                          items: povertyOptions.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPoverty = newValue;
                            });
                          },
                        ),
                      ),
                      const Text('Consumption quintile', style: _labelStyle),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedQuintile,
                          decoration: _dropdownDecoration,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF6E6E73)),
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF111111)),
                          items: quintileOptions.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedQuintile = newValue;
                            });
                          },
                        ),
                      ),
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
                          child: const Text('RWF',
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
