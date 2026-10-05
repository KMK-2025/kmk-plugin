import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({this.storeUrl, super.key});

  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = storeUrl;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.system_update,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.updateRequiredTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.updateRequiredBody, textAlign: TextAlign.center),
              if (url != null) ...[
                const SizedBox(height: AppSpacing.md),
                SelectableText(url, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
