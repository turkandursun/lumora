import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/goals_table.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/premium_button.dart';
import '../screens/goals_screen.dart' show frequencyLabelFor, unitLabelForUnit;

class GoalEditDraft {
  const GoalEditDraft({
    required this.title,
    required this.target,
    required this.unit,
    required this.customUnitLabel,
    required this.frequency,
  });

  final String title;
  final int target;
  final GoalUnit unit;
  final String? customUnitLabel;
  final GoalFrequency frequency;
}

class EditGoalSheet extends StatefulWidget {
  const EditGoalSheet({required this.goal, super.key});

  final GoalRow goal;

  static Future<GoalEditDraft?> show(BuildContext context, GoalRow goal) {
    return showModalBottomSheet<GoalEditDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGoalSheet(goal: goal),
    );
  }

  @override
  State<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends State<EditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _targetController;
  late final TextEditingController _customUnitController;
  late GoalUnit _unit;
  late GoalFrequency _frequency;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _targetController = TextEditingController(text: '${widget.goal.target}');
    _customUnitController =
        TextEditingController(text: widget.goal.customUnitLabel ?? '');
    _unit = widget.goal.unit;
    _frequency = widget.goal.frequency;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      GoalEditDraft(
        title: _titleController.text.trim(),
        target: int.parse(_targetController.text.trim()),
        unit: _unit,
        customUnitLabel:
            _unit == GoalUnit.custom ? _customUnitController.text.trim() : null,
        frequency: _frequency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = AstraThemeTokens.of(context);
    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: tokens.isDark
          ? tokens.palette.inputBackground
          : Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: tokens.isDark
              ? tokens.palette.softBorder
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: tokens.isDark
              ? tokens.palette.activeAccent
              : LumoraPalette.lightPurple,
        ),
      ),
    );
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.goalsEditSheetTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.isDark ? tokens.textPrimary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      color:
                          tokens.isDark ? tokens.textSecondary : Colors.white,
                    ),
                    decoration: fieldDecoration.copyWith(
                      hintText: l10n.goalsNewTitleHint,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.goalsNewTitleValidationEmpty
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color:
                          tokens.isDark ? tokens.textSecondary : Colors.white,
                    ),
                    decoration: fieldDecoration.copyWith(
                      hintText: l10n.goalsNewTargetHint,
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      return parsed == null || parsed <= 0
                          ? l10n.goalsNewTargetValidationInvalid
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GoalUnit>(
                    initialValue: _unit,
                    dropdownColor: tokens.isDark
                        ? tokens.palette.surfaceElevated
                        : LumoraPalette.nightBackground,
                    style: TextStyle(
                      color:
                          tokens.isDark ? tokens.textSecondary : Colors.white,
                    ),
                    decoration: fieldDecoration.copyWith(
                      labelText: l10n.goalsNewUnitPrompt,
                      labelStyle: TextStyle(
                        color:
                            tokens.isDark ? tokens.textMuted : Colors.white70,
                      ),
                    ),
                    items: [
                      for (final unit in GoalUnit.values)
                        DropdownMenuItem(
                          value: unit,
                          child: Text(
                            unit == GoalUnit.custom
                                ? l10n.goalsUnitCustomLabel
                                : unitLabelForUnit(l10n, unit, null),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _unit = value);
                    },
                  ),
                  if (_unit == GoalUnit.custom) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customUnitController,
                      style: TextStyle(
                        color:
                            tokens.isDark ? tokens.textSecondary : Colors.white,
                      ),
                      decoration: fieldDecoration.copyWith(
                        hintText: l10n.goalsNewCustomUnitHint,
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? l10n.goalsNewCustomUnitValidationEmpty
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GoalFrequency>(
                    initialValue: _frequency,
                    dropdownColor: tokens.isDark
                        ? tokens.palette.surfaceElevated
                        : LumoraPalette.nightBackground,
                    style: TextStyle(
                      color:
                          tokens.isDark ? tokens.textSecondary : Colors.white,
                    ),
                    decoration: fieldDecoration.copyWith(
                      labelText: l10n.goalsNewFrequencyPrompt,
                      labelStyle: TextStyle(
                        color:
                            tokens.isDark ? tokens.textMuted : Colors.white70,
                      ),
                    ),
                    items: [
                      for (final frequency in GoalFrequency.values)
                        DropdownMenuItem(
                          value: frequency,
                          child: Text(frequencyLabelFor(l10n, frequency)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _frequency = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  PremiumButton(
                    label: l10n.goalsEditSaveButton,
                    icon: Icons.save_outlined,
                    onPressed: _submit,
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
