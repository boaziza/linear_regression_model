import 'package:flutter/material.dart';
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

  bool _isLoading = false;
  double? _prediction;
  String? _errorMessage;

  String get _sex => _sexSelection[0] ? 'Female' : 'Male';
  String get _area => _areaSelection[0] ? 'Urban' : 'Rural';

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
        _errorMessage = 'Please enter an age.';
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
      appBar: AppBar(
        title: Text('Youth Wage Predictor'),
      ),
      body: Column(
        children: [
          Text('Estimate the monthly income for an employed adult (16-30) in Rwanda'),
          Text('Based on NISR household survey data.'),
          Padding(
            padding: EdgeInsetsGeometry.all(8.0),
            child: Column(
              children: [
                Text('Profile'),
                Text('Age'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'e.g. 25',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      )
                    ),
                    onSubmitted: null,
                  ),
                ),
                Text('Sex'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ToggleButtons(
                    isSelected: _sexSelection,
                    onPressed: (int index) {
                      setState(() {
                        _sexSelection = [index == 0, index == 1];
                      });
                    },
                    children: const [
                      Text('Female'),
                      Text('Male')
                    ])
                ),
                Row(
                  children: [
                    Text('Attended school in the last 12 months'),
                    Switch(
                      value: _attendedSchool,
                      onChanged: (bool value) {
                        setState(() {
                          _attendedSchool = value;
                        });
                      },
                    )
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.all(8.0),
            child: Column(
              children: [
                Text('Location'),
                Text('Area'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ToggleButtons(
                    isSelected: _areaSelection,
                    onPressed: (int index) {
                      setState(() {
                        _areaSelection = [index == 0, index == 1];
                      });
                    },
                    children: const [
                      Text('Urban'),
                      Text('Rural')
                    ])
                ),
                Text('Province'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
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
          Padding(
            padding: EdgeInsetsGeometry.all(8.0),
            child: Column(
              children: [
                Text('Household Welfare'),
                Text('Poverty status'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedPoverty,
                    // Styles the outline to match your TextField
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
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
                Text('Consumption quintile'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedQuintile,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
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
          ElevatedButton(
            onPressed: _isLoading ? null : _predict,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Predict'),
          ),
          if (_prediction != null)
            Text('Estimated monthly income: ${_prediction!.toStringAsFixed(0)} RWF'),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],        
      ), 
    );
  }
}