const int authMinimumPasswordLength = 8;
const int passwordRecoveryOtpLength = 8;

final RegExp _authEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidAuthEmail(String value) => _authEmailPattern.hasMatch(value.trim());

enum PasswordRecoveryValidationIssue {
  emailRequired,
  emailInvalid,
  otpInvalid,
  passwordRequired,
  passwordTooShort,
  confirmationRequired,
  passwordMismatch,
}

PasswordRecoveryValidationIssue? validatePasswordRecoveryInput({
  required String email,
  required String otp,
  required String password,
  required String confirmation,
}) {
  if (email.trim().isEmpty) {
    return PasswordRecoveryValidationIssue.emailRequired;
  }
  if (!isValidAuthEmail(email)) {
    return PasswordRecoveryValidationIssue.emailInvalid;
  }
  if (!RegExp(r'^\d{8}$').hasMatch(otp.trim())) {
    return PasswordRecoveryValidationIssue.otpInvalid;
  }
  if (password.trim().isEmpty) {
    return PasswordRecoveryValidationIssue.passwordRequired;
  }
  if (password.length < authMinimumPasswordLength) {
    return PasswordRecoveryValidationIssue.passwordTooShort;
  }
  if (confirmation.trim().isEmpty) {
    return PasswordRecoveryValidationIssue.confirmationRequired;
  }
  if (confirmation != password) {
    return PasswordRecoveryValidationIssue.passwordMismatch;
  }
  return null;
}
