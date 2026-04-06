import 'package:flutter/material.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';

/// [NavigatorObserver] que registra breadcrumbs de navegação no serviço de observabilidade.
///
/// Rastreia pushes e pops de rotas para que a trilha apareça nos relatórios
/// de crashes/erros do Crashlytics.
class ObservabilityNavigatorObserver extends NavigatorObserver {
  ObservabilityNavigatorObserver(this._observability);

  final ObservabilityService _observability;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _observability.logBreadcrumb(
        'navigation_push',
        data: {'route': name, 'previous': previousRoute?.settings.name ?? ''},
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _observability.logBreadcrumb(
        'navigation_pop',
        data: {'route': name, 'previous': previousRoute?.settings.name ?? ''},
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final name = newRoute?.settings.name;
    if (name != null && name.isNotEmpty) {
      _observability.logBreadcrumb(
        'navigation_replace',
        data: {'route': name, 'previous': oldRoute?.settings.name ?? ''},
      );
    }
  }
}
