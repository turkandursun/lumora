import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/page_config.dart';

/// The whole "Sayfa Oluştur" screen state: the active tab plus the page being
/// built. Kept in one object so switching tabs never loses form state.
@immutable
class CreatePageState {
  const CreatePageState({
    this.tab = CreatePageTab.customize,
    this.config = PageConfig.initial,
  });

  final CreatePageTab tab;
  final PageConfig config;

  /// The "Sıfırla" button is enabled only once the user has changed something.
  bool get isDirty => !config.isDefault;

  CreatePageState copyWith({CreatePageTab? tab, PageConfig? config}) =>
      CreatePageState(
        tab: tab ?? this.tab,
        config: config ?? this.config,
      );
}

/// Drives every selection. Each mutation returns a fresh [PageConfig] so the
/// live preview (which watches this provider) re-renders instantly.
class CreatePageController extends StateNotifier<CreatePageState> {
  CreatePageController() : super(const CreatePageState());

  void setTab(CreatePageTab tab) => state = state.copyWith(tab: tab);

  void setSize(PageSizePreset size) =>
      state = state.copyWith(config: state.config.copyWith(size: size));

  void setFormat(PageFormat format) =>
      state = state.copyWith(config: state.config.copyWith(format: format));

  void setOrientation(PageOrientation orientation) => state =
      state.copyWith(config: state.config.copyWith(orientation: orientation));

  void setPaperStyle(PaperStyle style) => state = state.copyWith(
      config: state.config.copyWith(paperStyle: style, templateId: () => null));

  void setColor(Color? color) => state =
      state.copyWith(config: state.config.copyWith(color: () => color));

  void setBinding(BindingStyle binding) =>
      state = state.copyWith(config: state.config.copyWith(binding: binding));

  void setBackground(int? index) => state = state.copyWith(
      config: state.config.copyWith(backgroundIndex: () => index));

  void selectTemplate(TemplateModel template) =>
      state = state.copyWith(config: template.applyTo(state.config));

  void reset() =>
      state = state.copyWith(config: PageConfig.initial);
}

final createPageControllerProvider =
    StateNotifierProvider.autoDispose<CreatePageController, CreatePageState>(
  (ref) => CreatePageController(),
);
