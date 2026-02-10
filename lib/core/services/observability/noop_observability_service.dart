import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';

/// Implementação vazia do serviço de observabilidade
///
/// Usada em testes ou quando observabilidade está desabilitada.
/// Todos os métodos são no-op (não fazem nada).
class NoopObservabilityService implements ObservabilityService {
  @override
  Future<void> logError(
    Failure failure, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // Não faz nada
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    // Não faz nada
  }

  @override
  void logBreadcrumb(String message, {Map<String, dynamic>? data}) {
    // Não faz nada
  }

  @override
  void setCustomKey(String key, dynamic value) {
    // Não faz nada
  }

  @override
  void setUserId(String? userId) {
    // Não faz nada
  }

  @override
  void clearContext() {
    // Não faz nada
  }
}
