import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plastic_factory_management/domain/usecases/user_usecases.dart';
import 'package:plastic_factory_management/l10n/app_localizations.dart';
import 'package:plastic_factory_management/presentation/routes/app_router.dart';

class TermsOfUseScreen extends StatelessWidget {
  final String uid;
  const TermsOfUseScreen({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final userUseCases = Provider.of<UserUseCases>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.termsOfUseTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  appLocalizations.termsOfUseText,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await userUseCases.acceptTerms(uid);
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushReplacementNamed(AppRouter.homeRoute);
                  }
                },
                child: Text(appLocalizations.acceptTerms),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
