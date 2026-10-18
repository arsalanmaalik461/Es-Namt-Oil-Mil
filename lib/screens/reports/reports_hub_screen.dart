import 'package:flutter/material.dart';
import 'package:namt_oil_mil/l10n/fragment_strings.dart';
import 'package:namt_oil_mil/navigation/routes.dart';
import 'package:namt_oil_mil/screens/reports/report_definitions.dart';

/// Reports hub — the grid of all 25 reports.
///
/// Imported directly by [AppShell] (navigation tab) and reachable via
/// [Routes.reports]. Each tile navigates to [Routes.reportDetail] with
/// `arguments: {'report': <key>}`.
class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = FragmentStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.reports_title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 2 columns on phones, 3 on small tablets, 4 on large tablets.
          final w = constraints.maxWidth;
          final columns = w < 600 ? 2 : (w < 900 ? 3 : 4);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // Roomy enough for the 44px icon + two title lines at 360px.
              childAspectRatio: columns == 2 ? 1.15 : 1.3,
            ),
            itemCount: reportDefinitions.length,
            itemBuilder: (context, i) {
              final def = reportDefinitions[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.reportDetail,
                    arguments: {'report': def.key},
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Icon(def.icon, color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          reportTitle(t, def.key),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
