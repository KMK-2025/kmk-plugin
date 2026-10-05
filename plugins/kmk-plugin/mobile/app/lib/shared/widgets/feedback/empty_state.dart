import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'state_message.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.inbox_outlined,
      message: message ?? AppLocalizations.of(context).stateEmpty,
    );
  }
}
