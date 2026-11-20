import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../enums/backend_enums.dart';
import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import 'brand_logo.dart';

class _NavDestination {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool showChatBadge;

  const _NavDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.showChatBadge = false,
  });
}

/// Contenedor principal adaptativo con navegación inferior en móvil y
/// `NavigationRail` en pantallas amplias, adaptado automáticamente al rol del usuario.
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  List<_NavDestination> _destinationsForRole(UserRole role) {
    if (role == UserRole.especialista) {
      return const [
        _NavDestination(
          route: AppRoutes.dashboard,
          label: 'Inicio',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        _NavDestination(
          route: AppRoutes.catalog,
          label: 'Catálogo',
          icon: Icons.photo_library_outlined,
          selectedIcon: Icons.photo_library_rounded,
        ),
        _NavDestination(
          route: AppRoutes.chat,
          label: 'Mensajes',
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
          showChatBadge: true,
        ),
        _NavDestination(
          route: AppRoutes.wallet,
          label: 'Billetera',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet_rounded,
        ),
        _NavDestination(
          route: AppRoutes.profile,
          label: 'Perfil',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];
    }

    return const [
      _NavDestination(
        route: AppRoutes.dashboard,
        label: 'Inicio',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      _NavDestination(
        route: AppRoutes.search,
        label: 'Buscar',
        icon: Icons.search_rounded,
        selectedIcon: Icons.manage_search_rounded,
      ),
      _NavDestination(
        route: AppRoutes.chat,
        label: 'Mensajes',
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        showChatBadge: true,
      ),
      _NavDestination(
        route: AppRoutes.jobs,
        label: 'Trabajos',
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
      ),
      _NavDestination(
        route: AppRoutes.profile,
        label: 'Perfil',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];
  }

  int _resolveSelectedIndex(List<_NavDestination> items) {
    for (var i = 0; i < items.length; i++) {
      if (currentLocation == items[i].route ||
          currentLocation.startsWith('${items[i].route}/')) {
        return i;
      }
    }
    return 0;
  }

  Widget _buildIcon(IconData icon, {required int unreadCount}) {
    if (unreadCount <= 0) return Icon(icon);
    return Badge(
      backgroundColor: AppColors.error,
      textColor: AppColors.white,
      label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final role = auth.user?.role ?? UserRole.empleador;
    final unreadCount = chat.unreadRoomsCount(auth.user?.id);
    final destinations = _destinationsForRole(role);
    final selectedIndex = _resolveSelectedIndex(destinations);
    final isWide = MediaQuery.sizeOf(context).width >= 860;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].route),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: BrandLogo(size: 42),
              ),
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: _buildIcon(
                        d.icon,
                        unreadCount: d.showChatBadge ? unreadCount : 0,
                      ),
                      selectedIcon: _buildIcon(
                        d.selectedIcon,
                        unreadCount: d.showChatBadge ? unreadCount : 0,
                      ),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            VerticalDivider(
              width: 1,
              color: isDark ? AppColors.graySurface : AppColors.silver,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.graySurface : AppColors.silver,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              context.go(destinations[index].route),
          destinations: destinations
              .map(
                (d) => NavigationDestination(
                  icon: _buildIcon(
                    d.icon,
                    unreadCount: d.showChatBadge ? unreadCount : 0,
                  ),
                  selectedIcon: _buildIcon(
                    d.selectedIcon,
                    unreadCount: d.showChatBadge ? unreadCount : 0,
                  ),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
