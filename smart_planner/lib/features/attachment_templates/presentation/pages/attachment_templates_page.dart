import 'package:flutter/material.dart';
import 'package:smart_planner/features/templates/presentation/pages/library_page.dart';
/// Opens the attachments tab on the unified templates hub.
class AttachmentTemplatesPage extends StatelessWidget {
  const AttachmentTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LibraryPage(initialTabIndex: 1);
  }
}
