import 'package:flutter/widgets.dart';

import '../../../../shared/widgets/pond_page_header.dart';

/// Auth page header: thin alias over the shared [PondPageHeader] so the auth
/// feature keeps its local name while the pattern lives in shared.
class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => PondPageHeader(title: title);
}
