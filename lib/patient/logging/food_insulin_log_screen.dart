import 'dart:io';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:diabetes_management_system/models/log_entry_dto.dart';
import 'package:diabetes_management_system/repositories/log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/patient/logging/food_log_controller.dart';
import 'package:diabetes_management_system/services/open_food_facts_service.dart';

// --- MAIN SCREEN ---
class FoodInsulinLogScreen extends StatefulWidget {
  @override
  _FoodInsulinLogScreenState createState() => _FoodInsulinLogScreenState();
}

class _FoodInsulinLogScreenState extends State<FoodInsulinLogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: _MobileLogBody(),
        desktopBody: _DesktopLogBody(),
      ),
    );
  }
}

// --- RESPONSIVE LAYOUTS ---

class _MobileLogBody extends StatelessWidget {
  const _MobileLogBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
            flex: 6,
            child: _LogInputSection()
        ),
        Container(
          height: 8,
          color: AppColors.background,
        ),
        const Expanded(
            flex: 4,
            child: _RecentLogsSection(),
        ),
      ],
    );
  }
}

class _DesktopLogBody extends StatelessWidget {
  const _DesktopLogBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(35.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _LogInputSection()),
          SizedBox(width: 32),
          Expanded(flex: 2, child: _RecentLogsSection()),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppColors.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Meal Log'),
                Tab(text: 'Insulin Log'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MealLogView(),
              _InsulinLogView(),
            ],
          ),
        ),
      ],
    );
  }
}

// --- MEAL LOG VIEW ---

class _MealLogView extends ConsumerStatefulWidget {
  const _MealLogView();

  @override
  ConsumerState<_MealLogView> createState() => _MealLogViewState();
}

class _MealLogViewState extends ConsumerState<_MealLogView> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _barcodeInputController = TextEditingController();

  bool _isBarcodeMode = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
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
    if (!_isBarcodeMode && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please provide a photo.")));
      return;
    }
    if (_isBarcodeMode && _barcodeInputController.text.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a barcode or scan it.")));
      return;
    }

    if (_isBarcodeMode) {
      try {
        String codeToSearch = _barcodeInputController.text;
        final result = await _openFoodService.getProductFromBarcode(codeToSearch);
        if (result != null) {
          setState(() {
            _descController.text = result['description'] ?? '';
            _carbsController.text = result['carbs']?.toString() ?? '';
            _caloriesController.text = result['calories']?.toString() ?? '';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Product not found.")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } else {
      ref.read(foodLogControllerProvider.notifier).analyzeImage(_imageFile!);
    }
  }

  void _submitLog() {
    ref.read(foodLogControllerProvider.notifier).submitLog(
      description: _descController.text,
      carbsStr: _carbsController.text,
      caloriesStr: _caloriesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FoodLogState>(foodLogControllerProvider, (previous, next) {
      if (next is FoodAnalysisSuccess) {
        _descController.text = next.description;
        _carbsController.text = next.carbs;
        _caloriesController.text = next.calories;
      } else if (next is FoodLogSuccess) {
        _descController.clear();
        _carbsController.clear();
        _caloriesController.clear();
        _barcodeInputController.clear();
        setState(() => _imageFile = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meal Logged!"), backgroundColor: Colors.green));
        ref.read(foodLogControllerProvider.notifier).resetState();
      } else if (next is FoodLogError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.red));
      }
    });

    final state = ref.watch(foodLogControllerProvider);
    final bool isLoading = state is FoodLogLoading || state is FoodAnalysisLoading;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Selection
          _buildModeSelector(),
          SizedBox(height: 16),

          // Media Section
          _buildMediaCard(isLoading),
          SizedBox(height: 20),

          // Barcode Manual Entry
          if (_isBarcodeMode) ...[
            // Wrapped in Padding to match the Card's internal padding (20.0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomTextFormField(
                labelText: 'Manual Barcode',
                controller: _barcodeInputController,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(height: 16),
          ],

          // Analysis Results Card
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.border.withOpacity(0.5))),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Meal Details", style: AppTextStyles.headline2.copyWith(fontSize: 18)),
                  SizedBox(height: 16),
                  CustomTextFormField(labelText: 'Description', controller: _descController),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: CustomTextFormField(labelText: 'Carbs (g)', controller: _carbsController, keyboardType: TextInputType.number)),
                      SizedBox(width: 12),
                      Expanded(child: CustomTextFormField(labelText: 'Calories', controller: _caloriesController, keyboardType: TextInputType.number)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),
          CustomElevatedButton(
              onPressed: isLoading ? null : _submitLog,
              text: 'Save Meal Log',
              height: 56.0
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.border.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _modeButton("AI Camera", !_isBarcodeMode, Icons.auto_awesome),
          _modeButton("Barcode", _isBarcodeMode, Icons.qr_code_scanner),
        ],
      ),
    );
  }

  Widget _modeButton(String title, bool active, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isBarcodeMode = (title == "Barcode");
          _imageFile = null;
        }),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: AppColors.shadow, blurRadius: 4)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textSecondary),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? AppColors.textPrimary : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCard(bool isLoading) {
    return Column(
      children: [
        if (_imageFile == null)
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _mediaOption(Icons.camera_alt_rounded, "Camera", () => _pickImage(ImageSource.camera)),
                Container(width: 1, height: 80, color: AppColors.border),
                _mediaOption(Icons.photo_library_rounded, "Gallery", () => _pickImage(ImageSource.gallery)),
              ],
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  child: kIsWeb ? Image.network(_imageFile!.path, fit: BoxFit.cover) : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: IconButton(
                  icon: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.close, size: 20, color: Colors.red)),
                  onPressed: () => setState(() => _imageFile = null),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(24)),
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
            ],
          ),
        if (_imageFile != null && !isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: CustomElevatedButton(
              onPressed: _analyzeData,
              text: _isBarcodeMode ? "Scan Barcode" : "Identify Food",
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28, 
            backgroundColor: AppColors.primary.withOpacity(0.1), 
            child: Icon(icon, size: 28, color: AppColors.primary)
          ),
          SizedBox(height: 10),
          Text(label, style: AppTextStyles.bodyText1.copyWith(
            fontWeight: FontWeight.w600, 
            color: AppColors.textPrimary,
            fontSize: 14
          )),
        ],
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
  String? _selectedName;
  String? _selectedId;

  void _submitDose() {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select medication")));
      return;
    }
    ref.read(foodLogControllerProvider.notifier).submitInsulin(
      medicationId: _selectedId!, medicationName: _selectedName!, unitsStr: _doseController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FoodLogState>(foodLogControllerProvider, (previous, next) {
      if (next is FoodLogSuccess) {
        _doseController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Insulin Logged!"), backgroundColor: Colors.green));
        ref.read(foodLogControllerProvider.notifier).resetState();
      }
    });

    final medicationsAsync = ref.watch(medicationsProvider);
    final state = ref.watch(foodLogControllerProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Log Insulin Dose", style: AppTextStyles.headline2),
              SizedBox(height: 20),
              medicationsAsync.when(
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading meds'),
                data: (meds) => DropdownButtonFormField<String>(
                  value: _selectedId,
                  decoration: InputDecoration(labelText: 'Insulin Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  items: meds.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                  onChanged: (v) => setState(() { _selectedId = v; _selectedName = meds.firstWhere((m) => m.id == v).name; }),
                ),
              ),
              SizedBox(height: 16),
              CustomTextFormField(labelText: 'Dose (Units)', controller: _doseController, keyboardType: TextInputType.numberWithOptions(decimal: true)),
              SizedBox(height: 24),
              CustomElevatedButton(onPressed: state is FoodLogLoading ? null : _submitDose, text: 'Log Dose'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- RECENT LOGS SECTION ---
class _RecentLogsSection extends StatelessWidget {
  const _RecentLogsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: AppTextStyles.headline2),
              Icon(Icons.history, color: AppColors.textSecondary),
            ],
          ),
          SizedBox(height: 16),
          const Expanded(child: _RecentLogsList()),
        ],
      ),
    );
  }
}

class _RecentLogsList extends ConsumerWidget {
  const _RecentLogsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsyncValue = ref.watch(recentLogsProvider);

    return logsAsyncValue.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading logs')),
      data: (logs) {
        if (logs.isEmpty) return Center(child: Text("No logs yet today."));

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final bool isInsulin = log.type == 'Insulin';
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isInsulin ? AppColors.skyBlue : AppColors.mint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withOpacity(0.02))
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(
                    isInsulin ? Icons.medication_rounded : Icons.restaurant_rounded, 
                    color: isInsulin ? Color(0xFF42A5F5) : Color(0xFF66BB6A), 
                    size: 22
                  ),
                ),
                title: Text(log.description, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(DateFormat('h:mm a').format(log.timestamp), style: AppTextStyles.bodyText2),
                trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary.withOpacity(0.5)),
              ),
            );
          },
        );
      },
    );
  }
}
