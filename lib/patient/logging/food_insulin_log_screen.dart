import 'dart:io';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Services
import 'package:diabetes_management_system/services/spoonacular_service.dart';
import 'package:diabetes_management_system/services/open_food_facts_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:diabetes_management_system/models/food_log_request.dart';
import 'package:diabetes_management_system/repositories/log_repository.dart';


// --- MAIN SCREEN ---
class FoodInsulinLogScreen extends StatefulWidget {
  @override
  _FoodInsulinLogScreenState createState() => _FoodInsulinLogScreenState();
}

class _FoodInsulinLogScreenState extends State<FoodInsulinLogScreen> {
  // This list holds the logs for the current session
  final List<Map<String, String>> _recentLogs = [
    {'title': '6 Units Rapid', 'time': '12:45 PM'},
    {'title': '50g Carbs - Oatmeal', 'time': '12:30 PM'},
  ];

  // Method to add a new log instantly
  void _addNewLog(String title) {
    setState(() {
      _recentLogs.insert(0, {
        'title': title,
        'time': 'Just now',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _MobileLogBody(logs: _recentLogs, onLogAdded: _addNewLog),
      desktopBody: _DesktopLogBody(logs: _recentLogs, onLogAdded: _addNewLog),
    );
  }
}

// --- RESPONSIVE LAYOUTS ---

class _MobileLogBody extends StatelessWidget {
  final List<Map<String, String>> logs;
  final Function(String) onLogAdded;

  const _MobileLogBody({required this.logs, required this.onLogAdded});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _LogInputSection(onLogAdded: onLogAdded),
            SizedBox(height: 24),
            _RecentLogsList(logs: logs),
          ],
        ),
      ),
    );
  }
}

class _DesktopLogBody extends StatelessWidget {
  final List<Map<String, String>> logs;
  final Function(String) onLogAdded;

  const _DesktopLogBody({required this.logs, required this.onLogAdded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _LogInputSection(onLogAdded: onLogAdded)),
          SizedBox(width: 24),
          Expanded(flex: 1, child: _RecentLogsList(logs: logs)),
        ],
      ),
    );
  }
}

// --- INPUT SECTION ---

class _LogInputSection extends StatefulWidget {
  final Function(String) onLogAdded;
  const _LogInputSection({required this.onLogAdded});

  @override
  __LogInputSectionState createState() => __LogInputSectionState();
}

class __LogInputSectionState extends State<_LogInputSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Remove SingleChildScrollView.
    // We want the Column to fill the screen height exactly.
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: [Tab(text: 'Meal Log'), Tab(text: 'Insulin Log')],
        ),
        SizedBox(height: 16),

        // 2. Use Expanded instead of SizedBox
        // This tells TabBarView: "Take up all the remaining screen space below the tabs"
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 3. Make sure these widgets handle their own scrolling!
              // (e.g., they should return a ListView or SingleChildScrollView)
              _MealLogView(onLogAdded: widget.onLogAdded),
              _InsulinLogView(onLogAdded: widget.onLogAdded),
            ],
          ),
        ),
      ],
    );
  }
}

// --- MEAL LOG VIEW (HANDLES PHOTOS & BARCODES) ---

class _MealLogView extends ConsumerStatefulWidget {
  final Function(String) onLogAdded;
  const _MealLogView({required this.onLogAdded});

  @override
  ConsumerState<_MealLogView> createState() => _MealLogViewState();
}

class _MealLogViewState extends ConsumerState<_MealLogView> {
  // Controllers
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _barcodeInputController = TextEditingController(); // NEW: For manual barcode entry

  // State
  bool _isBarcodeMode = false;
  bool _isLoading = false;
  XFile? _imageFile;

  // Services
  final ImagePicker _picker = ImagePicker();
  final SpoonacularService _spoonacularService = SpoonacularService();
  final OpenFoodFactsService _openFoodService = OpenFoodFactsService();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error accessing camera.")));
    }
  }

  Future<void> _analyzeData() async {
    // Validation
    if (!_isBarcodeMode && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please take a photo first.")));
      return;
    }
    if (_isBarcodeMode && _barcodeInputController.text.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a barcode or take a photo.")));
      return;
    }

    setState(() => _isLoading = true);
    Map<String, dynamic>? result;

    if (_isBarcodeMode) {
      // --- BARCODE MODE ---
      String codeToSearch = _barcodeInputController.text;

      // Note: If we had a real ML Kit scanner, we would extract code from _imageFile here.
      // For now, we rely on the manual input if the image isn't processed.
      if (codeToSearch.isEmpty) {
        // Fallback for demo if they took a photo but didn't type (Simulated)
        codeToSearch = "5900001001001"; // Example Polish Barcode
      }

      result = await _openFoodService.getProductFromBarcode(codeToSearch);

    } else {
      // --- SPOONACULAR PHOTO MODE ---
      result = await _spoonacularService.analyzeFoodImage(_imageFile!);
    }

    setState(() => _isLoading = false);

    if (result != null) {
      _descController.text = result['description'] ?? '';
      _carbsController.text = result['carbs'] ?? '';
      _caloriesController.text = result['calories'] ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Found: ${result['description']}")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isBarcodeMode ? "Product not found. Check code." : "Could not identify food."))
      );
    }
  }

  Future<void> _submitLog() async {
    if (_descController.text.isNotEmpty && _carbsController.text.isNotEmpty) {

      final String description = _descController.text;
      final int carbs = int.tryParse(_carbsController.text) ?? 0;
      final int calories = int.tryParse(_caloriesController.text) ?? 0;

      final request = FoodLogRequest(
        description: description,
        carbs: carbs,
        calories: calories,
      );

      // 2. TODO: Get actual Patient ID from Auth Provider
      const String patientId = "b9255850-8b6a-4643-b26a-4f810e755533"; // Temporary hardcoded UUID

      setState(() => _isLoading = true); // Show loading state if you want

      try {
        // 3. Call the Repository using 'ref'
        await ref.read(logRepositoryProvider).createFoodLog(patientId, request);

        // 4. Update UI on Success
        String entry = "${carbs}g Carbs - $description";
        widget.onLogAdded(entry);

        // Reset inputs
        _descController.clear();
        _carbsController.clear();
        _caloriesController.clear();
        _barcodeInputController.clear();
        setState(() => _imageFile = null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meal Logged Successfully!")));
        }

      } catch (e) {
        // 5. Handle Errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to save log: ${e.toString()}"),
            backgroundColor: Colors.red,
          ));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter at least description and carbs.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. MODE TOGGLE
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: _buildModeButton("AI Food Camera", false)),
                Expanded(child: _buildModeButton("Barcode Scanner", true)),
              ],
            ),
          ),

          // 2. IMAGE PREVIEW (Shows for both modes)
          if (_imageFile != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                  ),
                ),
                IconButton(
                  icon: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.close, size: 20)),
                  onPressed: () => setState(() => _imageFile = null),
                )
              ],
            ),

          // 3. MEDIA BUTTONS
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery' , style: TextStyle(color: Colors.black))
                )
            ),
            SizedBox(width: 16),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt_outlined),
                    label: Text('Camera', style: TextStyle(color: Colors.black))
                )
            ),
          ]),

          SizedBox(height: 16),

          // 4. MANUAL BARCODE INPUT (Only visible in Barcode Mode)
          if (_isBarcodeMode)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFormField(
                        labelText: 'Enter Barcode Manually',
                        controller: _barcodeInputController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Small hint text
                    Tooltip(
                      message: "Type the numbers under the barcode",
                      child: Icon(Icons.help_outline, color: Colors.grey),
                    )
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),

          // 5. ACTION BUTTON (Calls API)
          CustomElevatedButton(
            onPressed: _isLoading ? null : _analyzeData,
            height: 50.0,
            child: Text(_isBarcodeMode ? "Search Barcode" : "Identify Food"),
          ),

          SizedBox(height: 24),

          // 6. RESULT FIELDS
          CustomTextFormField(labelText: 'Description', controller: _descController),
          SizedBox(height: 16),
          CustomTextFormField(labelText: 'Carbs (g)', controller: _carbsController, keyboardType: TextInputType.number),
          SizedBox(height: 16),
          CustomTextFormField(labelText: 'Calories', controller: _caloriesController, keyboardType: TextInputType.number),

          SizedBox(height: 24),
          CustomElevatedButton(
              onPressed: _submitLog,
              text: 'Log Meal',
              height: 50.0
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, bool isBarcode) {
    bool isActive = _isBarcodeMode == isBarcode;
    return GestureDetector(
      onTap: () => setState(() {
        _isBarcodeMode = isBarcode;
        _imageFile = null;
        _barcodeInputController.clear();
      }),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
        ),
        child: Center(
          child: Text(title, style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.grey[600]
          )),
        ),
      ),
    );
  }
}

// --- INSULIN LOG VIEW ---
class _InsulinLogView extends StatefulWidget {
  final Function(String) onLogAdded;
  const _InsulinLogView({required this.onLogAdded});

  @override
  State<_InsulinLogView> createState() => _InsulinLogViewState();
}

class _InsulinLogViewState extends State<_InsulinLogView> {
  final TextEditingController _doseController = TextEditingController();
  String _insulinType = 'Rapid-acting';

  void _submitDose() {
    if (_doseController.text.isNotEmpty) {
      widget.onLogAdded("${_doseController.text} Units $_insulinType");
      _doseController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dose Logged!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _insulinType,
            items: ['Rapid-acting', 'Basal'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) => setState(() => _insulinType = val!),
            decoration: InputDecoration(labelText: 'Insulin Type', border: OutlineInputBorder()),
          ),
          SizedBox(height: 16),
          CustomTextFormField(labelText: 'Dose (Units)', controller: _doseController, keyboardType: TextInputType.number),
          SizedBox(height: 16),
          CustomElevatedButton(onPressed: _submitDose, text: 'Log Dose'),
        ],
      ),
    );
  }
}

// --- RECENT LOGS LIST (Fix for Overflow) ---
class _RecentLogsList extends StatelessWidget {
  final List<Map<String, String>> logs;

  const _RecentLogsList({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Logs', style: AppTextStyles.headline2),
        SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return ListTile(
                // 1. Allow the title to wrap if it's too long
                title: Text(
                  logs[index]['title']!,
                  style: AppTextStyles.bodyText1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // 2. Move time to subtitle (below) instead of trailing (side)
                // This prevents the "RenderFlex overflow" crash in narrow columns
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    logs[index]['time']!,
                    style: AppTextStyles.bodyText2.copyWith(color: Colors.grey),
                  ),
                ),
                // trailing: Text(...), // <--- REMOVED THIS CAUSE OF ERROR
              );
            },
            separatorBuilder: (context, index) => Divider(height: 1),
          ),
        ),
      ],
    );
  }
}