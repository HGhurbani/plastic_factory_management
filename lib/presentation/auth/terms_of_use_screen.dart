import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';
import 'package:plastic_factory_management/theme/app_colors.dart'; // Import your app colors

class TermsOfUseScreen extends StatelessWidget {
  final String uid;
  const TermsOfUseScreen({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final userUseCases = Provider.of<UserUseCases>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appLocalizations.termsOfUseTitle,
          style: const TextStyle(
            color: Colors.white, // White text for title
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary, // Use primary color for AppBar
        elevation: 0, // No shadow for a cleaner look
      ),
      body: Container(
        // Add a subtle gradient or background for visual appeal
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.lightGrey, // Use a light background color
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), // Add bounce effect for scrolling
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch text for better alignment
                    children: [
                      // Add an introductory icon or image
                      Icon(
                        Icons.privacy_tip_outlined, // A clear icon for terms/privacy
                        size: 80,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        appLocalizations.termsOfUseTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        appLocalizations.termsOfUseText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify, // Justify text for a cleaner paragraph look
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5, // Improve line spacing for readability
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            // Accept Button section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              color: Colors.white, // Solid background for the button area
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "بالموافقة، فإنك تقر بأنك قد قرأت وفهمت ووافقت على جميع الشروط والأحكام المذكورة أعلاه.", // Emphasize understanding
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, // Make button fill width
                    height: 50, // Set a fixed height for the button
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Don't allow accepting if no user ID provided (before login)
                        if (uid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يجب تسجيل الدخول أولاً لقبول الشروط.')),
                          );
                          return;
                        }

                        // Show a loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext loadingContext) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          },
                        );
                        try {
                          await userUseCases.acceptTerms(uid);
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Dismiss loading indicator
                            // Show a success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم قبول الشروط بنجاح!'), duration: const Duration(seconds: 2)),
                            );
                            Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Dismiss loading indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('حدث خطأ أثناء قبول الشروط: ${e.toString()}')),
                            );
                          }
                          print('Error accepting terms: $e'); // For debugging
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        appLocalizations.acceptTerms,
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Use primary color for button
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Slightly more rounded corners
                        ),
                        elevation: 5, // Add subtle shadow
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}