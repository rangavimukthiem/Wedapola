import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { client, worker }

enum AppLanguage { en, si, ta }

extension AppLanguageX on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.en:
        return 'English';
      case AppLanguage.si:
        return 'සිංහල';
      case AppLanguage.ta:
        return 'தமிழ்';
    }
  }

  String get code => name;
}

class AppModeState {
  final AppRole role;
  final AppLanguage language;
  final bool onboardingDone;
  final bool workerAvailable;
  final String workerKycStatus;

  const AppModeState({
    this.role = AppRole.client,
    this.language = AppLanguage.en,
    this.onboardingDone = false,
    this.workerAvailable = true,
    this.workerKycStatus = 'BASIC_VERIFIED',
  });

  AppModeState copyWith({
    AppRole? role,
    AppLanguage? language,
    bool? onboardingDone,
    bool? workerAvailable,
    String? workerKycStatus,
  }) {
    return AppModeState(
      role: role ?? this.role,
      language: language ?? this.language,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      workerAvailable: workerAvailable ?? this.workerAvailable,
      workerKycStatus: workerKycStatus ?? this.workerKycStatus,
    );
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppModeState>(AppModeNotifier.new);

class AppModeNotifier extends Notifier<AppModeState> {
  static const _roleKey = 'wedapola_role';
  static const _langKey = 'wedapola_lang';
  static const _onboardKey = 'wedapola_onboard_done';
  static const _availKey = 'wedapola_worker_avail';
  static const _kycKey = 'wedapola_worker_kyc';

  @override
  AppModeState build() {
    _load();
    return const AppModeState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleStr = prefs.getString(_roleKey);
      final langStr = prefs.getString(_langKey);
      final onboard = prefs.getBool(_onboardKey) ?? false;
      final avail = prefs.getBool(_availKey) ?? true;
      final kyc = prefs.getString(_kycKey) ?? 'BASIC_VERIFIED';

      state = state.copyWith(
        role: roleStr == 'worker' ? AppRole.worker : AppRole.client,
        language: langStr == 'si'
            ? AppLanguage.si
            : langStr == 'ta'
                ? AppLanguage.ta
                : AppLanguage.en,
        onboardingDone: onboard,
        workerAvailable: avail,
        workerKycStatus: kyc,
      );
    } catch (_) {}
  }

  Future<void> setRole(AppRole role) async {
    state = state.copyWith(role: role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  Future<void> toggleRole() async {
    final next = state.role == AppRole.client ? AppRole.worker : AppRole.client;
    await setRole(next);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang.code);
  }

  Future<void> completeOnboarding(AppRole role, AppLanguage lang) async {
    state = state.copyWith(role: role, language: lang, onboardingDone: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
    await prefs.setString(_langKey, lang.code);
    await prefs.setBool(_onboardKey, true);
  }

  Future<void> toggleWorkerAvailability(bool available) async {
    state = state.copyWith(workerAvailable: available);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_availKey, available);
  }

  Future<void> setWorkerKycStatus(String status) async {
    state = state.copyWith(workerKycStatus: status);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kycKey, status);
  }
}
