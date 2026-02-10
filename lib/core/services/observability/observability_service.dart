import 'package:gasosa_app/core/errors/failure.dart';

/// Interface para serviço de observabilidade
///
/// Responsável por:
/// - Registrar erros não-fatais (Failures tratadas)
/// - Registrar eventos de analytics
/// - Registrar breadcrumbs (trilha de navegação/ações)
/// - Definir contexto (userId, custom keys)
abstract class ObservabilityService {
  /// Registra um erro não-fatal (Failure tratada)
  ///
  /// [failure] - Falha a ser registrada
  /// [stackTrace] - Stack trace opcional (se disponível)
  /// [context] - Contexto adicional (route, action, etc.)
  ///
  /// Importante: [context] será sanitizado automaticamente
  /// para remover informações sensíveis (PII)
  Future<void> logError(
    Failure failure, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  });

  /// Registra um evento de analytics
  ///
  /// [name] - Nome do evento (ex: 'login_success', 'vehicle_create_attempt')
  /// [parameters] - Parâmetros do evento
  ///
  /// Importante: [parameters] será sanitizado automaticamente
  /// para remover informações sensíveis (PII)
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  });

  /// Registra um breadcrumb (trilha)
  ///
  /// Usado para rastrear navegação, ações do usuário e mudanças de estado.
  /// Aparece na trilha de crashes/erros no Crashlytics.
  ///
  /// [message] - Mensagem descritiva (ex: 'Login attempt', 'Navigation')
  /// [data] - Dados adicionais (ex: {'method': 'email', 'route': '/login'})
  void logBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
  });

  /// Define custom key para contexto
  ///
  /// Usado para adicionar informação ao contexto de crashes/erros.
  /// Útil para correlacionar erros com estado da aplicação.
  ///
  /// [key] - Chave (ex: 'route', 'userId', 'vehicleId')
  /// [value] - Valor
  ///
  /// Importante: Keys sensíveis (email, name, plate, etc.) serão
  /// automaticamente ignoradas
  void setCustomKey(String key, dynamic value);

  /// Define userId (para correlação)
  ///
  /// Importante: Use apenas ID interno (UUID), nunca e-mail ou nome
  ///
  /// [userId] - ID do usuário (null para limpar)
  void setUserId(String? userId);

  /// Limpa contexto
  ///
  /// Deve ser chamado no logout para remover dados do usuário
  void clearContext();
}
