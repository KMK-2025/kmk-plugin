import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'state_message.dart';

class UnauthorizedState extends StatelessWidget {
  const UnauthorizedState({super.key});

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.lock_outline,
      message: AppLocalizations.of(context).stateUnauthorized,
    );
  }
}
