part of '../main.dart';

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontFamily: 'Lato'))),
        ]),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('SPIT Pvt. Ltd.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Lato',
                letterSpacing: 0.8)),
      );
}

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  final String password;
  const _PasswordStrengthBar({required this.strength, required this.password});

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.accent;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }

  String get _label {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak — add uppercase, numbers, symbols';
      case PasswordStrength.medium:
        return 'Medium — getting there!';
      case PasswordStrength.strong:
        return 'Strong ✓';
    }
  }

  double get _fraction {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: _fraction,
              backgroundColor: Colors.grey.shade200,
              color: _color,
              minHeight: 6)),
      const SizedBox(height: 4),
      Text(_label,
          style: TextStyle(fontSize: 12, color: _color, fontFamily: 'Lato')),
    ]);
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData prefixIcon;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const _DropdownField({
    required this.label,
    required this.prefixIcon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        value: value,
        decoration:
            InputDecoration(labelText: label, prefixIcon: Icon(prefixIcon)),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i.toString())))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      );
}

extension StringX on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
