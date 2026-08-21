import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/tables/reminders_table.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/premium_button.dart';
import '../providers/reminders_providers.dart';

/// Bottom sheet for creating a custom reminder: title, frequency (daily /
/// a specific weekday / one-time), and a time picker.
class NewReminderSheet extends ConsumerStatefulWidget {
  const NewReminderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewReminderSheet(),
    );
  }

  @override
  ConsumerState<NewReminderSheet> createState() => _NewReminderSheetState();
}

class _NewReminderSheetState extends ConsumerState<NewReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  ReminderFrequency _frequency = ReminderFrequency.daily;
  int _weekday = DateTime.monday;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;
    setState(() => _isSaving = true);

    await ref.read(remindersRepositoryProvider).addCustomReminder(
          title: _titleController.text.trim(),
          frequency: _frequency,
          weekday: _frequency == ReminderFrequency.weekly ? _weekday : null,
          hour: _time.hour,
          minute: _time.minute,
        );

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = AstraThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        key: const ValueKey('new-reminder-sheet-surface'),
        decoration: BoxDecoration(
          color: tokens.palette.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: tokens.palette.softBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.palette.focusGlow.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.textMuted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.remindersNewSheetTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TitleField(
                    controller: _titleController,
                    hint: l10n.remindersNewTitleHint,
                    validationEmpty: l10n.remindersNewTitleValidationEmpty,
                  ),
                  const SizedBox(height: 20),
                  _FrequencySelector(
                    selected: _frequency,
                    onSelected: (frequency) =>
                        setState(() => _frequency = frequency),
                  ),
                  if (_frequency == ReminderFrequency.weekly) ...[
                    const SizedBox(height: 18),
                    Text(
                      l10n.remindersNewWeekdayPrompt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _WeekdaySelector(
                      selected: _weekday,
                      onSelected: (weekday) =>
                          setState(() => _weekday = weekday),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    l10n.remindersNewTimePrompt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TimeField(time: _time, onTap: _pickTime),
                  const SizedBox(height: 26),
                  _SubmitButton(
                    label: l10n.remindersNewSubmitButton,
                    isSaving: _isSaving,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({
    required this.controller,
    required this.hint,
    required this.validationEmpty,
  });

  final TextEditingController controller;
  final String hint;
  final String validationEmpty;

  @override
  Widget build(BuildContext context) {
    final tokens = AstraThemeTokens.of(context);
    return TextFormField(
      key: const ValueKey('new-reminder-title-field'),
      controller: controller,
      textInputAction: TextInputAction.done,
      style: TextStyle(color: tokens.textPrimary),
      cursorColor: tokens.palette.activeAccent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: tokens.textMuted,
        ),
        filled: true,
        fillColor: tokens.palette.inputBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: tokens.palette.softBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: tokens.palette.softBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: tokens.palette.activeAccent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFBE3D4C)),
        ),
      ),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? validationEmpty : null,
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.selected, required this.onSelected});

  final ReminderFrequency selected;
  final ValueChanged<ReminderFrequency> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = {
      ReminderFrequency.daily: l10n.remindersFrequencyDaily,
      ReminderFrequency.weekly: l10n.remindersFrequencyWeekly,
      ReminderFrequency.once: l10n.remindersFrequencyOnce,
    };
    return Row(
      children: [
        for (final entry in options.entries)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: entry.key == ReminderFrequency.once ? 0 : 8),
              child: _Pill(
                label: entry.value,
                isSelected: entry.key == selected,
                onTap: () => onSelected(entry.key),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        for (var weekday = DateTime.monday;
            weekday <= DateTime.sunday;
            weekday++)
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: weekday == DateTime.sunday ? 0 : 6),
              child: _Pill(
                label: DateFormat.E(locale).format(
                  DateTime(2024, 1, 1).add(Duration(days: weekday - 1)),
                ),
                isSelected: weekday == selected,
                onTap: () => onSelected(weekday),
                dense: true,
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = AstraThemeTokens.of(context);
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(vertical: dense ? 10 : 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSelected
                  ? tokens.palette.chipSelected
                  : tokens.palette.chipUnselected,
              border: Border.all(
                color: isSelected
                    ? tokens.palette.activeAccent
                    : tokens.palette.softBorder,
                width: 1.1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: dense ? 12.5 : 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? tokens.textOnAccent : tokens.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AstraThemeTokens.of(context);
    final label =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          key: const ValueKey('new-reminder-time-field'),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: tokens.palette.inputBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tokens.palette.softBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 20,
                color: tokens.palette.activeAccent,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton(
      {required this.label, required this.isSaving, required this.onTap});

  final String label;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AstraThemeTokens.of(context);
    return PremiumButton(
      key: const ValueKey('new-reminder-submit-button'),
      label: label,
      icon: Icons.check_rounded,
      loading: isSaving,
      gradient: [
        tokens.palette.buttonPrimary,
        tokens.palette.secondary,
      ],
      onPressed: onTap,
    );
  }
}
