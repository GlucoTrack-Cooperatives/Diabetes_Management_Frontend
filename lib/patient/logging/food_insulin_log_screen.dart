import 'dart:io';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


// Services
import 'package:diabetes_management_system/services/spoonacular_service.dart';
import 'package:diabetes_management_system/services/open_food_facts_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/patient/logging/food_log_controller.dart';


// --- MAIN SCREEN ---
class FoodInsulinLogScreen extends StatefulWidget {
  @override
  _FoodInsulinLogScreenState createState() => _FoodInsulinLogScreenState();
}

class _FoodInsulinLogScreenState extends State<FoodInsulinLogScreen> {

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _MobileLogBody(),
      desktopBody: _DesktopLogBody(),
    );
  }
}

// --- RESPONSIVE LAYOUTS ---

class _MobileLogBody extends StatelessWidget {

  const _MobileLogBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _LogInputSection(),
            SizedBox(height: 24),
            _RecentLogsList(),
          ],
        ),
      ),
    );
  }
}

class _DesktopLogBody extends StatelessWidget {

  const _DesktopLogBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _LogInputSection()),
          SizedBox(width: 24),
          Expanded(flex: 1, child: _RecentLogsList()),
        ],
      ),
    );
  }
}

// --- INPUT SECTION ---

class _LogInputSection extends StatefulWidget {

  const _LogInputSection();

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
              _MealLogView(),
              _InsulinLogView(),
            ],
          ),
        ),
      ],
    );
  }
}

// --- MEAL LOG VIEW (HANDLES PHOTOS & BARCODES) ---

class _MealLogView extends ConsumerStatefulWidget {
  const _MealLogView();

  @override
  ConsumerState<_MealLogView> createState() => _MealLogViewState();
}

class _MealLogViewState extends ConsumerState<_MealLogView> {
  // Controllers
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _barcodeInputController = TextEditingController();

  // State (UI specific)
  bool _isBarcodeMode = false;
  // bool _isLoading = false; // <-- REMOVED: Managed by Controller now
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

  void _submitLog() {
    // We just pass the raw text to the controller. The controller handles validation & API.
    ref.read(foodLogControllerProvider.notifier).submitLog(
      description: _descController.text,
      carbsStr: _carbsController.text,
      caloriesStr: _caloriesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to the Controller State
    ref.listen<FoodLogState>(foodLogControllerProvider, (previous, next) {
      if (next is FoodLogSuccess) {
        // Success Logic

        // Clear forms
        _descController.clear();
        _carbsController.clear();
        _caloriesController.clear();
        _barcodeInputController.clear();
        setState(() => _imageFile = null);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meal Logged Successfully!")));

        // Reset controller state so we don't trigger success again accidentally
        ref.read(foodLogControllerProvider.notifier).resetState();
      }
      else if (next is FoodLogError) {
        // Error Logic
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: Colors.red,
        ));
      }
    });

    // 2. Watch the state to handle Loading UI
    // final state = ref.watch(foodLogControllerProvider);
    // final bool isLoading = state is FoodLogLoading;

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
            onPressed:  _analyzeData,
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
class _InsulinLogView extends ConsumerStatefulWidget {
  const _InsulinLogView();

  @override
  ConsumerState<_InsulinLogView> createState() => _InsulinLogViewState();
}

class _InsulinLogViewState extends ConsumerState<_InsulinLogView> {
  final TextEditingController _doseController = TextEditingController();

  // Map Display Name -> Backend UUID
  // In a real app, you would fetch this Map from the backend (GET /patients/{id}/medications)
  // For now, we hardcode popular Polish brands with Placeholder UUIDs.
  // REPLACE THESE UUID STRINGS with actual IDs from your 'medication' table in Postgres.
  final Map<String, String> _insulinOptions = {
    'Novorapid (Aspart)': '11111111-1111-1111-1111-111111111111',
    'Humalog (Lispro)':   '22222222-2222-2222-2222-222222222222',
    'Fiasp (Fast Aspart)':'33333333-3333-3333-3333-333333333333',
    'Lantus (Glargine)':  '44444444-4444-4444-4444-444444444444',
    'Abasaglar (Glargine)':'55555555-5555-5555-5555-555555555555',
    'Toujeo':             '66666666-6666-6666-6666-666666666666',
    'Tresiba (Degludec)': '77777777-7777-7777-7777-777777777777',
    'Mixtard 30':         '88888888-8888-8888-8888-888888888888',
  };

  String? _selectedName;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    // Default to the first one
    _selectedName = _insulinOptions.keys.first;
    _selectedId = _insulinOptions.values.first;
  }

  void _submitDose() {
    if (_selectedId == null) return;

    // Call the controller
    ref.read(foodLogControllerProvider.notifier).submitInsulin(
      medicationId: _selectedId!,
      medicationName: _selectedName!,
      unitsStr: _doseController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen for Success/Error (reusing the same controller state as Food)
    ref.listen<FoodLogState>(foodLogControllerProvider, (previous, next) {
      if (next is FoodLogSuccess) {
        _doseController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Insulin Logged: ${next.message}"),
          backgroundColor: Colors.green,
        ));
        ref.read(foodLogControllerProvider.notifier).resetState();
      } else if (next is FoodLogError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: Colors.red,
        ));
      }
    });

    final state = ref.watch(foodLogControllerProvider);
    final bool isLoading = state is FoodLogLoading;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. BRAND DROPDOWN
          DropdownButtonFormField<String>(
            value: _selectedName,
            isExpanded: true,
            items: _insulinOptions.keys.map((String key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(key, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedName = val;
                _selectedId = _insulinOptions[val];
              });
            },
            decoration: InputDecoration(
                labelText: 'Insulin Type (Poland)',
                border: OutlineInputBorder()
            ),
          ),

          SizedBox(height: 16),

          // 2. DOSE INPUT
          CustomTextFormField(
            labelText: 'Dose (Units)',
            controller: _doseController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),

          SizedBox(height: 16),

          // 3. SUBMIT BUTTON
          CustomElevatedButton(
              onPressed: isLoading ? () {} : _submitDose,
              text: isLoading ? 'Saving...' : 'Log Dose'
          ),
        ],
      ),
    );
  }
}

// --- RECENT LOGS LIST
class _RecentLogsList extends ConsumerWidget {
  const _RecentLogsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsyncValue = ref.watch(recentLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Logs', style: AppTextStyles.headline2),
        SizedBox(height: 12),

        logsAsyncValue.when(
          loading: () => Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err', style: TextStyle(color: Colors.red)),
          data: (logs) {
            if (logs.isEmpty) return Text("No recent logs found.");

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final timeStr = DateFormat('h:mm a').format(log.timestamp);

                  // Logic to check if the description already has "Carbs" text to avoid duplication
                  // (Assuming backend might send "45g Carbs" or just "45")

                  return ListTile(
                    leading: Icon(
                      log.type == 'Insulin' ? Icons.medication : Icons.restaurant,
                      color: log.type == 'Insulin' ? Colors.blue : Colors.green,
                    ),
                    title: Text(
                      log.description, // Backend sends "45g Carbs" based on your previous java code
                      style: AppTextStyles.bodyText1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      timeStr, // Just the time, removed the type
                      style: AppTextStyles.bodyText2.copyWith(color: Colors.grey),
                    ),
                  );
                },
                separatorBuilder: (context, index) => Divider(height: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}