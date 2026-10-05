import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'state_message.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({this.message, this.onRetry, super.key});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onRetry = this.onRetry;

    return StateMessage(
      icon: Icons.error_outline,
      message: message ?? l10n.stateError,
      action: onRetry == null
          ? null
          : FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
    );
  }
}
