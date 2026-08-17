import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/tables/reminders_table.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/lumora_palette.dart';
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

    final l10n = AppLocalizations.of(context);
    await ref.read(remindersRepositoryProvider).addCustomReminder(
          title: _titleController.text.trim(),
          frequency: _frequency,
          weekday: _frequency == ReminderFrequency.weekly ? _weekday : null,
          hour: _time.hour,
          minute: _time.minute,
          notificationBody: l10n.reminderCustomBody,
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
        decoration: BoxDecoration(
          color: tokens.isDark
              ? tokens.palette.surfaceElevated
              : LumoraPalette.nightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: tokens.isDark
                            ? tokens.textMuted.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.2),
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
                      color: tokens.isDark ? tokens.textPrimary : Colors.white,
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
                        color: tokens.isDark
                            ? tokens.textSecondary
                            : Colors.white.withValues(alpha: 0.75),
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
                      color: tokens.isDark
                          ? tokens.textSecondary
                          : Colors.white.withValues(alpha: 0.75),
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
      controller: controller,
      textInputAction: TextInputAction.done,
      style: TextStyle(
        color: tokens.isDark ? tokens.textSecondary : Colors.white,
      ),
      cursorColor: tokens.isDark
          ? tokens.palette.activeAccent
          : LumoraPalette.lightPurple,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: tokens.isDark
              ? tokens.textMuted
              : Colors.white.withValues(alpha: 0.45),
        ),
        filled: true,
        fillColor: tokens.isDark
            ? tokens.palette.inputBackground
            : Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: tokens.isDark
                ? tokens.palette.softBorder
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: tokens.isDark
                ? tokens.palette.softBorder
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: tokens.isDark
                ? tokens.palette.activeAccent
                : LumoraPalette.lightPurple,
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
                  ? (tokens.isDark
                      ? tokens.palette.chipSelected
                      : LumoraPalette.primaryPurple.withValues(alpha: 0.9))
                  : (tokens.isDark
                      ? tokens.palette.chipUnselected
                      : Colors.white.withValues(alpha: 0.06)),
              border: Border.all(
                color: isSelected
                    ? (tokens.isDark
                        ? tokens.palette.activeAccent
                        : LumoraPalette.lightPurple)
                    : (tokens.isDark
                        ? tokens.palette.softBorder
                        : Colors.white.withValues(alpha: 0.16)),
                width: 1.1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: dense ? 12.5 : 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: tokens.isDark ? tokens.textSecondary : Colors.white,
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: tokens.isDark
                ? tokens.palette.inputBackground
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tokens.isDark
                  ? tokens.palette.softBorder
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 20,
                color: tokens.isDark
                    ? tokens.palette.activeAccent
                    : LumoraPalette.lightPurple,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.isDark ? tokens.textSecondary : Colors.white,
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
    return PremiumButton(
      label: label,
      icon: Icons.check_rounded,
      loading: isSaving,
      onPressed: onTap,
    );
  }
}
