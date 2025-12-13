import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onItemSelected,
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onItemSelected,
              destinations: destinations,
            ),
    );
  }
}
