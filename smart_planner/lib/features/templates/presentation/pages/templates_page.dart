import 'package:smart_planner/features/templates/presentation/pages/library_page.dart';

export 'library_page.dart' show LibraryPage;

/// @deprecated Use [LibraryPage] instead.
@Deprecated('Use LibraryPage')
class TemplatesPage extends LibraryPage {
  const TemplatesPage({super.initialTabIndex = 0, super.key});
}
