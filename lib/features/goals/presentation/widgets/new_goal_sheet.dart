import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/tables/goals_table.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/premium_button.dart';
import '../../presentation/screens/goals_screen.dart' show unitLabelForUnit;
import '../providers/goals_providers.dart';

/// Bottom sheet for creating a custom goal: title, target number, unit
/// (glasses/minutes/pages/books/custom), and frequency (daily/weekly/
/// monthly). Mirrors `NewReminderSheet`'s structure and styling so the two
/// sheets feel like the same app.
class NewGoalSheet extends ConsumerStatefulWidget {
  const NewGoalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewGoalSheet(),
    );
  }

  @override
  ConsumerState<NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends ConsumerState<NewGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _customUnitController = TextEditingController();

  GoalUnit _unit = GoalUnit.glasses;
  GoalFrequency _frequency = GoalFrequency.daily;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;
    setState(() => _isSaving = true);

    await ref.read(goalsRepositoryProvider).addCustomGoal(
          title: _titleController.text.trim(),
          unit: _unit,
          customUnitLabel: _unit == GoalUnit.custom
              ? _customUnitController.text.trim()
              : null,
          target: int.parse(_targetController.text.trim()),
          frequency: _frequency,
        );

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: LumoraPalette.nightBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.goalsNewSheetTitle,
                    style: LumoraPalette.bodyStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TextField(
                    controller: _titleController,
                    hint: l10n.goalsNewTitleHint,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.goalsNewTitleValidationEmpty
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _TextField(
                    controller: _targetController,
                    hint: l10n.goalsNewTargetHint,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final trimmed = (value ?? '').trim();
                      if (trimmed.isEmpty) {
                        return l10n.goalsNewTargetValidationEmpty;
                      }
                      final parsed = int.tryParse(trimmed);
                      if (parsed == null || parsed <= 0) {
                        return l10n.goalsNewTargetValidationInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.goalsNewUnitPrompt,
                    style: LumoraPalette.bodyStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _UnitSelector(
                    selected: _unit,
                    onSelected: (unit) => setState(() => _unit = unit),
                  ),
                  if (_unit == GoalUnit.custom) ...[
                    const SizedBox(height: 14),
                    _TextField(
                      controller: _customUnitController,
                      hint: l10n.goalsNewCustomUnitHint,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? l10n.goalsNewCustomUnitValidationEmpty
                          : null,
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    l10n.goalsNewFrequencyPrompt,
                    style: LumoraPalette.bodyStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FrequencySelector(
                    selected: _frequency,
                    onSelected: (frequency) =>
                        setState(() => _frequency = frequency),
                  ),
                  const SizedBox(height: 26),
                  _SubmitButton(
                    label: l10n.goalsNewSubmitButton,
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

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.done,
      style: LumoraPalette.bodyStyle(color: Colors.white),
      cursorColor: LumoraPalette.lightPurple,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: LumoraPalette.bodyStyle(
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.45),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: LumoraPalette.lightPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
              color: LumoraPalette.accentPink.withValues(alpha: 0.7)),
        ),
      ),
      validator: validator,
    );
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({required this.selected, required this.onSelected});

  final GoalUnit selected;
  final ValueChanged<GoalUnit> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = {
      GoalUnit.glasses: unitLabelForUnit(l10n, GoalUnit.glasses, null),
      GoalUnit.minutes: unitLabelForUnit(l10n, GoalUnit.minutes, null),
      GoalUnit.pages: unitLabelForUnit(l10n, GoalUnit.pages, null),
      GoalUnit.books: unitLabelForUnit(l10n, GoalUnit.books, null),
      GoalUnit.custom: l10n.goalsUnitCustomLabel,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in options.entries)
          _Pill(
            label: entry.value,
            isSelected: entry.key == selected,
            onTap: () => onSelected(entry.key),
          ),
      ],
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.selected, required this.onSelected});

  final GoalFrequency selected;
  final ValueChanged<GoalFrequency> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = {
      GoalFrequency.daily: l10n.goalsFrequencyDaily,
      GoalFrequency.weekly: l10n.goalsFrequencyWeekly,
      GoalFrequency.monthly: l10n.goalsFrequencyMonthly,
    };
    return Row(
      children: [
        for (final entry in options.entries)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: entry.key == GoalFrequency.monthly ? 0 : 8),
              child: _Pill(
                label: entry.value,
                isSelected: entry.key == selected,
                onTap: () => onSelected(entry.key),
                expand: true,
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
    this.expand = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.center,
            width: expand ? double.infinity : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSelected
                  ? LumoraPalette.primaryPurple.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: isSelected
                    ? LumoraPalette.lightPurple
                    : Colors.white.withValues(alpha: 0.16),
                width: 1.1,
              ),
            ),
            child: Text(
              label,
              style: LumoraPalette.bodyStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
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
