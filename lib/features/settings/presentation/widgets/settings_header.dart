import 'package:flutter/widgets.dart';

import '../../../../shared/widgets/pond_page_header.dart';

/// Settings page header: thin alias over the shared [PondPageHeader] so the
/// settings feature keeps its local name while the pattern lives in shared.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => PondPageHeader(title: title);
}
