import 'package:flutter/material.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/patient/patient_main_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/main_navigation.dart';

class OnboardingKnowledgeScreen extends ConsumerStatefulWidget {
  const OnboardingKnowledgeScreen({super.key});

  @override
  ConsumerState<OnboardingKnowledgeScreen> createState() => _OnboardingKnowledgeScreenState();
}

class _OnboardingKnowledgeScreenState extends ConsumerState<OnboardingKnowledgeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<KnowledgeStep> _steps = [
    KnowledgeStep(
      title: "Welcome to BlueCircle",
      description: "Managing diabetes is a journey. We're here to help you track your meals, insulin, and glucose levels seamlessly.",
      icon: Icons.favorite_rounded,
      color: AppColors.primary,
    ),
    KnowledgeStep(
      title: "Carb Counting 101",
      description: "Carbohydrates have the biggest impact on blood sugar. Use our AI Camera to estimate carbs just by taking a photo of your plate.",
      icon: Icons.restaurant_rounded,
      color: Colors.orange,
    ),
    KnowledgeStep(
      title: "Logging Insulin",
      description: "Keep track of your bolus and basal doses. Consistent logging helps your doctor adjust your treatment plan effectively.",
      icon: Icons.medication_rounded,
      color: AppColors.skyBlue,
    ),
    KnowledgeStep(
      title: "Sick Day Rules",
      description: "When you're ill, your blood sugar often rises. Use our 'Sick Event' logger to keep notes for your physician during these times.",
      icon: Icons.sick_rounded,
      color: Colors.redAccent,
    ),
  ];

  void _onNext() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to Home
      ref.read(justRegisteredProvider.notifier).state = false;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PatientMainScreen()),
            (route) => false,
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: step.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(step.icon, size: 100, color: step.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          step.title,
                          style: AppTextStyles.headline1.copyWith(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          step.description,
                          style: AppTextStyles.bodyText1.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom UI
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (index) => _buildIndicator(index)),
                  ),
                  const SizedBox(height: 32),
                  CustomElevatedButton(
                    onPressed: _onNext,
                    text: _currentPage == _steps.length - 1 ? "Get Started" : "Next",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class KnowledgeStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  KnowledgeStep({required this.title, required this.description, required this.icon, required this.color});
}