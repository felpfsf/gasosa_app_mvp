abstract final class AuthStrings {
  static const loginTitle = 'Entrar no Gasosa';
  static const registerTitle = 'Crie sua conta';
  static const loginButton = 'Entrar';
  static const registerButton = 'Cadastrar';
  static const registerLink = 'Não tem uma conta? Cadastre-se';
  static const emailLabel = 'Email';
  static const emailRegisterLabel = 'E-mail';
  static const passwordLabel = 'Senha';
  static const confirmPasswordLabel = 'Confirmar Senha';
  static const nameLabel = 'Nome';

  // Hints
  static const nameHint = 'Ex: João Silva';
  static const emailHint = 'Ex: joao@email.com';
  static const passwordHint = 'Mínimo 6 caracteres';
  static const confirmPasswordHint = 'Repita a senha';

  // Forgot password
  static const forgotPasswordLink = 'Esqueci minha senha';
}

abstract final class ForgotPasswordStrings {
  static const appBarTitle = 'Redefinir senha';
  static const instructions = 'Digite o e-mail da sua conta. Enviaremos um link para redefinir sua senha.';
  static const emailLabel = 'E-mail';
  static const emailHint = 'Ex: joao@email.com';
  static const sendButton = 'Enviar link';
  static const successTitle = 'E-mail enviado!';
  static const successMessage = 'Verifique sua caixa de entrada (e o spam) e siga as instruções.';
  static const backToLoginButton = 'Voltar ao login';
}

abstract final class DashboardStrings {
  static const addVehicleLabel = 'Adicionar veículo';
  static const logoutTooltip = 'Sair';
  static const emptyStateTitle = 'Nenhum veículo cadastrado';
  static const emptyStateMessage = 'Cadastre seu primeiro veículo para começar a usar o app.';
  static const emptyStateAction = 'Cadastrar veículo';

  // Logout dialog
  static const logoutDialogTitle = 'Sair da conta';
  static const logoutDialogContent = 'Tem certeza que deseja sair?';
  static const logoutDialogConfirmLabel = 'Sair';

  static String greeting(String? name) => 'Olá, ${name ?? ''}!';
}

abstract final class VehicleStrings {
  static const appBarTitleCreate = 'Adicionar Veículo';
  static const appBarTitleEdit = 'Editar Veículo';
  static const appBarTitleDetail = 'Detalhes do Veículo';
  static const nameLabel = 'Nome';
  static const plateLabel = 'Placa (opcional)';
  static const tankCapacityLabel = 'Capacidade do Tanque (L) — opcional';
  static const fuelTypeLabel = 'Tipo de Combustível';
  static const photoLabel = 'Foto do Veículo - opcional';

  // Hints
  static const nameHint = 'Ex: Gol 1.0, Civic EX…';
  static const plateHint = 'Ex: ABC1D23';
  static const tankCapacityHint = 'Ex: 50';

  static const saveButton = 'Salvar';
  static const deleteButton = 'Excluir';
  static const saveSuccess = 'Veículo salvo com sucesso!';
  static const deleteSuccess = 'Veículo excluído!';
  static const editTooltip = 'Editar';
  static const deleteTooltip = 'Excluir';
  static const refuelsSectionTitle = 'Abastecimentos';

  // Delete confirm dialog
  static const deleteDialogTitle = 'Excluir veículo';
  static const deleteDialogConfirmLabel = 'Excluir';
  static const deleteDialogMessageCascade =
      'Essa ação também removerá todos os abastecimentos vinculados a este veículo.';
  static const deleteDialogMessageUndoable = 'Esta ação não pode ser desfeita.';
  static String deleteDialogMessage(String? vehicleName) => [
    if (vehicleName != null && vehicleName.isNotEmpty) 'Tem certeza que deseja excluir o veículo "$vehicleName"?',
    deleteDialogMessageCascade,
    deleteDialogMessageUndoable,
  ].join('\n\n');
}

abstract final class RefuelStrings {
  static const appBarTitleCreate = 'Adicionar Abastecimento';
  static const appBarTitleEdit = 'Editar Abastecimento';
  static const dateLabel = 'Data do Abastecimento';
  static const mileageLabel = 'KM atual';
  static const fuelTypeLabel = 'Tipo de Combustível';
  static const litersLabel = 'Litros abastecidos';
  static const totalValueLabel = 'Valor total';
  static const coldStartCheckboxLabel = 'Abasteceu partida a frio?';
  static const coldStartLitersLabel = 'Litros abastecidos (partida a frio)';
  static const coldStartValueLabel = 'Valor total (partida a frio)';
  static const receiptCheckboxLabel = 'Comprovante de Abastecimento?';
  static const receiptPhotoLabel = 'Comprovante de Abastecimento';

  // Hints
  static const mileageHint = 'Ex: 45000';
  static const litersHint = 'Ex: 40,00';
  static const totalValueHint = 'Ex: 280,00';
  static const coldStartLitersHint = 'Ex: 5,00';
  static const coldStartValueHint = 'Ex: 35,00';

  static const saveButton = 'Salvar';
  static const deleteButton = 'Excluir';
  static const saveSuccess = 'Abastecimento salvo com sucesso!';
  static const deleteSuccess = 'Abastecimento excluído com sucesso!';
  static const deleteDialogTitle = 'Excluir abastecimento';
  static const deleteDialogMessage =
      'Tem certeza que deseja excluir este abastecimento? Esta ação não pode ser desfeita.';
  static const deleteDialogConfirmLabel = 'Excluir';

  // Empty state (refuel list)
  static const emptyStateTitle = 'Nenhum abastecimento';
  static const emptyStateMessage = 'Quando você registrar um abastecimento, ele aparecerá aqui.';
  static const emptyStateAction = 'Adicionar';
}

abstract final class AppErrorStrings {
  static const pageNotFound = 'Página não encontrada';
  static const goToDashboard = 'Ir para a Dashboard';
}

// ---------------------------------------------------------------------------
// Validator messages
// ---------------------------------------------------------------------------

abstract final class UserValidatorStrings {
  static const nameRequired = 'Nome obrigatório';
  static const nameTooShort = 'Nome deve ter pelo menos 2 caracteres';
  static const nameTooLong = 'Nome deve ter no máximo 50 caracteres';
  static const emailRequired = 'Email obrigatório';
  static const emailInvalid = 'Email inválido';
  static const passwordRequired = 'Senha obrigatória';
  static const passwordTooShort = 'Senha deve ter pelo menos 6 caracteres';
  static const confirmPasswordRequired = 'Confirmação de senha obrigatória';
  static const confirmPasswordMismatch = 'As senhas não coincidem';
}

abstract final class VehicleValidatorStrings {
  static const nameRequired = 'Nome do veículo é obrigatório';
  static const nameTooShort = 'Nome deve ter pelo menos 3 caracteres';
  static const nameTooLong = 'Nome deve ter no máximo 50 caracteres';
  static const nameInvalidChars = 'Nome do veículo deve conter apenas caracteres alfanuméricos';
  static const plateTooLong = 'Placa deve ter no máximo 7 caracteres';
  static const plateInvalidChars = 'Placa deve conter apenas caracteres alfanuméricos';
  static const tankCapacityMin = 'Capacidade do tanque deve ser maior que 0';
}

abstract final class RefuelValidatorStrings {
  static const litersRequired = 'Litros abastecidos é obrigatório';
  static const litersTooLow = 'Litros abastecidos deve ser maior que 0';
  static const litersTooHigh = 'Litros abastecidos deve ser menor que 100';
  static const totalValueRequired = 'Valor total é obrigatório';
  static const totalValueTooLow = 'Valor total deve ser maior que 0';
  static const mileageRequired = 'KM é obrigatória';
  static const mileageTooLow = 'KM deve ser maior ou igual a 0';
  static const mileageTooHigh = 'KM deve ser menor que 1.000.000';
  static const coldStartLitersRequired = 'Litros partida frio é obrigatório';
  static const coldStartLitersTooLow = 'Litros partida frio deve ser maior ou igual a 0';
  static const coldStartLitersTooHigh = 'Litros partida frio deve ser menor que 100';
  static const coldStartValueRequired = 'Valor partida frio é obrigatório';
  static const coldStartValueTooLow = 'Valor partida frio deve ser maior que 0';
  static const fuelTypeRequired = 'Selecione o tipo de combustível';
  static const dateRequired = 'Data do abastecimento é obrigatória';
}

// ---------------------------------------------------------------------------
// Auth error messages
// ---------------------------------------------------------------------------

abstract final class AuthErrorStrings {
  // Firebase Auth errors
  static const invalidCredentials = 'Email ou senha inválidos';
  static const emailAlreadyInUse = 'Email já está em uso';
  static const networkFailed = 'Falha na conexão com a internet';
  static const accountLinkedToDifferentProvider =
      'Este e-mail já está vinculado a outro método de login. '
      'Entre pelo método original e depois vincule o Google nas Configurações.';
  static const userDisabled = 'Usuário desativado';
  static const unexpectedAuth = 'Erro inesperado de autenticação';

  // Google Sign-In errors
  static const googleSignInConfig =
      'Erro de configuração do Google Sign-In. '
      'Verifique as credenciais SHA no Firebase Console.';
  static String googleSignInFailedWithDetail(String detail) => 'Falha no Google Sign-In: $detail';
  static const googleSignInCanceled = 'Login cancelado pelo usuário';
  static const googleSignInInterrupted = 'Login interrompido. Tente novamente.';
  static const googleSignInUiUnavailable = 'UI de login indisponível.';
  static const googleSignInFailed = 'Falha no Google Sign-In';

  // Auth service errors
  static const googleCredentialsMissing = 'Erro ao obter credenciais do Google';
  static const nullUser = 'Falha de autenticação, usuário nulo';
  static const logoutFailed = 'Falha ao sair';
  static const passwordResetFailed = 'Erro ao enviar e-mail de redefinição';
  static const googleCredentialsMissingLink = 'Sem credenciais do Google';
  static const googleLinkFailed = 'Falha ao vincular com o Google';
}
