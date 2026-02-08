import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:gasosa_app/core/errors/failure.dart';
import 'package:gasosa_app/core/services/observability/observability_service.dart';

/// Implementação do serviço de observabilidade usando Firebase
///
/// Usa:
/// - Firebase Crashlytics para crashes e erros não-fatais
/// - Firebase Analytics para eventos e funil
class FirebaseObservabilityService implements ObservabilityService {
  final FirebaseCrashlytics _crashlytics;
  final FirebaseAnalytics _analytics;

  FirebaseObservabilityService({
    FirebaseCrashlytics? crashlytics,
    FirebaseAnalytics? analytics,
  }) : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
       _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> logError(
    Failure failure, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    // Sanitizar contexto (remover PII)
    final sanitized = _sanitizeContext(context);

    // Adicionar tipo de falha
    _crashlytics.setCustomKey('failure_type', failure.runtimeType.toString());
    _crashlytics.setCustomKey('failure_message', failure.message);

    // Adicionar contexto adicional
    sanitized.forEach((key, value) {
      _crashlytics.setCustomKey(key, value.toString());
    });

    // Enviar como non-fatal
    await _crashlytics.recordError(
      failure,
      stackTrace ?? StackTrace.current,
      reason: failure.message,
      fatal: false,
    );
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    // Sanitizar parâmetros
    final sanitized = _sanitizeContext(parameters);

    await _analytics.logEvent(
      name: name,
      parameters: sanitized.cast<String, Object>(),
    );
  }

  @override
  void logBreadcrumb(
    String message, {
    Map<String, dynamic>? data,
  }) {
    final sanitized = _sanitizeContext(data);
    final breadcrumb = '$message ${sanitized.isNotEmpty ? sanitized.toString() : ''}';

    _crashlytics.log(breadcrumb);
  }

  @override
  void setCustomKey(String key, dynamic value) {
    // Não permitir keys sensíveis
    if (_isSensitiveKey(key)) return;

    _crashlytics.setCustomKey(key, value.toString());
  }

  @override
  void setUserId(String? userId) {
    _crashlytics.setUserIdentifier(userId ?? '');
    _analytics.setUserId(id: userId);
  }

  @override
  void clearContext() {
    setUserId(null);
    // Custom keys são limpos automaticamente ao limpar userId
  }

  // Helpers privados

  /// Sanitiza contexto/parâmetros removendo informações sensíveis (PII)
  Map<String, dynamic> _sanitizeContext(Map<String, dynamic>? context) {
    if (context == null) return {};

    return Map.fromEntries(
      context.entries.where((e) => !_isSensitiveKey(e.key)),
    );
  }

  /// Verifica se a key contém informação sensível (PII)
  ///
  /// Lista de termos sensíveis:
  /// - email, name, displayName
  /// - plate, licensePlate
  /// - photoPath, receiptPath, filePath
  /// - password, token
  bool _isSensitiveKey(String key) {
    const sensitive = [
      'email',
      'name',
      'displayname',
      'plate',
      'licenseplate',
      'photopath',
      'receiptpath',
      'password',
      'token',
      'filepath',
    ];

    final lowerKey = key.toLowerCase();
    return sensitive.any((s) => lowerKey.contains(s));
  }
}
