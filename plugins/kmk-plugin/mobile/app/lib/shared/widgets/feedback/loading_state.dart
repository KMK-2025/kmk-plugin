import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        semanticsLabel: AppLocalizations.of(context).stateLoading,
      ),
    );
  }
}
