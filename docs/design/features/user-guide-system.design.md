# Design: User Guide System

## 1. Design Overview

### Reference Documents
- Plan Document: `docs/01-plan/features/user-guide-system.plan.md`
- Related Features: Daily Closing, Order Management, Product Management

### Design Principles
1. **Non-Intrusive**: Tutorials should not block critical workflows
2. **Context-Aware**: Show relevant help based on user's current screen
3. **Progressive Disclosure**: Start simple, provide details on demand
4. **Accessible**: Support keyboard navigation and screen readers
5. **Performant**: Minimal impact on app startup and runtime

## 2. Architecture Design

### 2.1 Directory Structure

```
lib/features/user_guide/
├── data/
│   ├── models/
│   │   └── tutorial_preference.dart         # Preference data model
│   ├── datasources/
│   │   └── tutorial_preference_local_source.dart  # SharedPreferences wrapper
│   └── repositories/
│       └── tutorial_repository.dart         # Repository pattern
├── domain/
│   ├── models/
│   │   ├── tutorial_step.dart               # Step definition
│   │   ├── tutorial_config.dart             # Tutorial configuration
│   │   └── tutorial_target.dart             # Target widget info
│   ├── repositories/
│   │   └── tutorial_repository_interface.dart  # Abstract repository
│   └── use_cases/
│       ├── get_tutorial_config.dart         # Get config for screen
│       ├── mark_tutorial_complete.dart      # Mark as completed
│       ├── reset_tutorials.dart             # Reset all tutorials
│       └── should_show_tutorial.dart        # Check if should show
├── presentation/
│   ├── providers/
│   │   ├── tutorial_state_provider.dart     # Tutorial state management
│   │   └── tutorial_preference_provider.dart # Preference state
│   ├── widgets/
│   │   ├── tutorial_coach_wrapper.dart      # Wrapper for tutorial_coach_mark
│   │   ├── tutorial_content_widget.dart     # Custom content widget
│   │   ├── tutorial_arrow_widget.dart       # Custom arrow widget
│   │   ├── tutorial_popup_widget.dart       # Custom popup widget
│   │   └── help_button.dart                 # Help icon button
│   └── screens/
│       └── tutorial_settings_screen.dart    # Tutorial management UI
└── configs/
    ├── daily_closing_tutorial.dart          # Daily Closing tutorial steps
    ├── order_management_tutorial.dart       # Order Management tutorial steps
    ├── dashboard_tutorial.dart              # Dashboard tutorial steps
    └── tutorial_registry.dart               # Central registry
```

### 2.2 Layer Responsibilities

#### Data Layer
- **Purpose**: Handle data persistence and retrieval
- **Components**:
  - `TutorialPreferenceLocalSource`: SharedPreferences operations
  - `TutorialRepository`: Implement repository interface
- **Data Stored**:
  - Completed tutorial IDs: `Set<String>`
  - First launch flag: `bool`
  - Tutorial-specific preferences: `Map<String, dynamic>`

#### Domain Layer
- **Purpose**: Business logic and core models
- **Components**:
  - Models: Define data structures
  - Use Cases: Encapsulate business operations
  - Repository Interface: Define data contract
- **No Dependencies**: Pure Dart, no Flutter dependencies

#### Presentation Layer
- **Purpose**: UI and state management
- **Components**:
  - Providers: Riverpod state management
  - Widgets: Reusable UI components
  - Screens: Full-screen UIs
- **Dependencies**: Flutter, Riverpod, tutorial_coach_mark

## 3. Data Models

### 3.1 TutorialStep Model

```dart
/// Represents a single step in a tutorial
class TutorialStep {
  /// Unique identifier for this step
  final String id;

  /// GlobalKey to identify the target widget
  final GlobalKey targetKey;

  /// L10n key for step title
  final String titleKey;

  /// L10n key for step description
  final String descriptionKey;

  /// Position of the content relative to target
  final ContentPosition position;

  /// Shape of the highlight (circle, rectangle, custom)
  final ShapeLightFocus shape;

  /// Custom padding around the target
  final EdgeInsets? padding;

  /// Optional custom content widget
  final Widget Function(BuildContext)? customContentBuilder;

  /// Whether user can skip this step
  final bool enableSkip;

  /// Whether to show previous button
  final bool enablePrevious;

  /// Step order in the tutorial
  final int order;

  const TutorialStep({
    required this.id,
    required this.targetKey,
    required this.titleKey,
    required this.descriptionKey,
    this.position = ContentPosition.bottom,
    this.shape = const ShapeLightFocus.RRect(),
    this.padding,
    this.customContentBuilder,
    this.enableSkip = true,
    this.enablePrevious = true,
    required this.order,
  });
}
```

### 3.2 TutorialConfig Model

```dart
/// Configuration for a complete tutorial
class TutorialConfig {
  /// Unique ID for this tutorial (e.g., "daily_closing_tutorial")
  final String tutorialId;

  /// Screen this tutorial applies to
  final String screenName;

  /// L10n key for tutorial title
  final String titleKey;

  /// L10n key for tutorial description
  final String descriptionKey;

  /// Ordered list of tutorial steps
  final List<TutorialStep> steps;

  /// Whether to show on first launch
  final bool showOnFirstLaunch;

  /// Tutorial version (for update detection)
  final String version;

  /// Required user role (null = all users)
  final String? requiredRole;

  /// Icon to display in tutorial list
  final IconData icon;

  const TutorialConfig({
    required this.tutorialId,
    required this.screenName,
    required this.titleKey,
    required this.descriptionKey,
    required this.steps,
    this.showOnFirstLaunch = false,
    this.version = '1.0.0',
    this.requiredRole,
    required this.icon,
  });

  /// Get steps sorted by order
  List<TutorialStep> get sortedSteps {
    final sorted = List<TutorialStep>.from(steps);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }
}
```

### 3.3 TutorialPreference Model

```dart
/// User preferences for tutorials
class TutorialPreference {
  /// Set of completed tutorial IDs
  final Set<String> completedTutorials;

  /// Whether user has launched app before
  final bool isFirstLaunch;

  /// Tutorial-specific settings (e.g., "daily_closing_never_show")
  final Map<String, bool> neverShowAgain;

  /// Last tutorial version seen for each tutorial
  final Map<String, String> lastSeenVersions;

  /// Timestamp of last tutorial interaction
  final DateTime? lastInteraction;

  const TutorialPreference({
    this.completedTutorials = const {},
    this.isFirstLaunch = true,
    this.neverShowAgain = const {},
    this.lastSeenVersions = const {},
    this.lastInteraction,
  });

  /// Create copy with modified values
  TutorialPreference copyWith({
    Set<String>? completedTutorials,
    bool? isFirstLaunch,
    Map<String, bool>? neverShowAgain,
    Map<String, String>? lastSeenVersions,
    DateTime? lastInteraction,
  }) {
    return TutorialPreference(
      completedTutorials: completedTutorials ?? this.completedTutorials,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      neverShowAgain: neverShowAgain ?? this.neverShowAgain,
      lastSeenVersions: lastSeenVersions ?? this.lastSeenVersions,
      lastInteraction: lastInteraction ?? this.lastInteraction,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'completedTutorials': completedTutorials.toList(),
      'isFirstLaunch': isFirstLaunch,
      'neverShowAgain': neverShowAgain,
      'lastSeenVersions': lastSeenVersions,
      'lastInteraction': lastInteraction?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TutorialPreference.fromJson(Map<String, dynamic> json) {
    return TutorialPreference(
      completedTutorials: Set<String>.from(json['completedTutorials'] ?? []),
      isFirstLaunch: json['isFirstLaunch'] ?? true,
      neverShowAgain: Map<String, bool>.from(json['neverShowAgain'] ?? {}),
      lastSeenVersions: Map<String, String>.from(json['lastSeenVersions'] ?? {}),
      lastInteraction: json['lastInteraction'] != null
          ? DateTime.parse(json['lastInteraction'])
          : null,
    );
  }
}
```

## 4. State Management

### 4.1 Riverpod Providers

```dart
// Preference state provider
final tutorialPreferenceProvider = StateNotifierProvider<TutorialPreferenceNotifier, TutorialPreference>((ref) {
  final repository = ref.watch(tutorialRepositoryProvider);
  return TutorialPreferenceNotifier(repository);
});

// Repository provider
final tutorialRepositoryProvider = Provider<TutorialRepository>((ref) {
  final localSource = TutorialPreferenceLocalSource();
  return TutorialRepository(localSource);
});

// Active tutorial state provider (null when no tutorial is active)
final activeTutorialProvider = StateProvider<String?>((ref) => null);

// Tutorial registry provider
final tutorialRegistryProvider = Provider<TutorialRegistry>((ref) {
  return TutorialRegistry();
});

// Check if tutorial should be shown for a specific screen
final shouldShowTutorialProvider = Provider.family<bool, String>((ref, tutorialId) {
  final preference = ref.watch(tutorialPreferenceProvider);
  final registry = ref.watch(tutorialRegistryProvider);
  final config = registry.getTutorialById(tutorialId);

  if (config == null) return false;

  // Don't show if completed
  if (preference.completedTutorials.contains(tutorialId)) {
    return false;
  }

  // Don't show if user selected "never show again"
  if (preference.neverShowAgain[tutorialId] == true) {
    return false;
  }

  // Check version mismatch (new version available)
  final lastSeenVersion = preference.lastSeenVersions[tutorialId];
  if (lastSeenVersion != null && lastSeenVersion != config.version) {
    return true; // New version available
  }

  // Show on first launch if configured
  if (config.showOnFirstLaunch && preference.isFirstLaunch) {
    return true;
  }

  return false;
});
```

### 4.2 TutorialPreferenceNotifier

```dart
class TutorialPreferenceNotifier extends StateNotifier<TutorialPreference> {
  final TutorialRepository _repository;

  TutorialPreferenceNotifier(this._repository) : super(const TutorialPreference()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final pref = await _repository.getPreferences();
    state = pref;
  }

  Future<void> markTutorialComplete(String tutorialId) async {
    final updatedCompleted = Set<String>.from(state.completedTutorials)..add(tutorialId);
    final newState = state.copyWith(
      completedTutorials: updatedCompleted,
      lastInteraction: DateTime.now(),
    );
    await _repository.savePreferences(newState);
    state = newState;
  }

  Future<void> setNeverShowAgain(String tutorialId, bool value) async {
    final updatedNeverShow = Map<String, bool>.from(state.neverShowAgain);
    updatedNeverShow[tutorialId] = value;
    final newState = state.copyWith(
      neverShowAgain: updatedNeverShow,
      lastInteraction: DateTime.now(),
    );
    await _repository.savePreferences(newState);
    state = newState;
  }

  Future<void> resetAllTutorials() async {
    final newState = TutorialPreference(
      isFirstLaunch: false, // Keep first launch status
      lastInteraction: DateTime.now(),
    );
    await _repository.savePreferences(newState);
    state = newState;
  }

  Future<void> updateLastSeenVersion(String tutorialId, String version) async {
    final updatedVersions = Map<String, String>.from(state.lastSeenVersions);
    updatedVersions[tutorialId] = version;
    final newState = state.copyWith(
      lastSeenVersions: updatedVersions,
      lastInteraction: DateTime.now(),
    );
    await _repository.savePreferences(newState);
    state = newState;
  }

  Future<void> markFirstLaunchComplete() async {
    final newState = state.copyWith(isFirstLaunch: false);
    await _repository.savePreferences(newState);
    state = newState;
  }
}
```

## 5. Custom Widgets

### 5.1 TutorialContentWidget

```dart
/// Custom content widget for tutorial popups
class TutorialContentWidget extends StatelessWidget {
  final String titleKey;
  final String descriptionKey;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onSkip;
  final bool showPrevious;
  final bool showNext;

  const TutorialContentWidget({
    super.key,
    required this.titleKey,
    required this.descriptionKey,
    required this.currentStep,
    required this.totalSteps,
    this.onNext,
    this.onPrevious,
    this.onSkip,
    this.showPrevious = true,
    this.showNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentStep + 1}/$totalSteps',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    l10n.skip,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            _getLocalizedText(context, titleKey),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            _getLocalizedText(context, descriptionKey),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showPrevious && onPrevious != null)
                OutlinedButton.icon(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(l10n.previous),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              else
                const SizedBox.shrink(),

              if (showNext && onNext != null)
                FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    currentStep == totalSteps - 1 ? l10n.finish : l10n.next,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    // Use reflection or a map to get localized text by key
    // This is a simplified version
    return key; // TODO: Implement proper L10n key lookup
  }
}
```

### 5.2 HelpButton Widget

```dart
/// Help button to trigger tutorials
class HelpButton extends ConsumerWidget {
  final String tutorialId;
  final Color? iconColor;
  final double? iconSize;

  const HelpButton({
    super.key,
    required this.tutorialId,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowTutorialProvider(tutorialId));

    return IconButton(
      icon: Badge(
        isLabelVisible: shouldShow,
        backgroundColor: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.help_outline,
          color: iconColor,
          size: iconSize,
        ),
      ),
      tooltip: AppLocalizations.of(context)!.help,
      onPressed: () => _showTutorial(context, ref),
    );
  }

  void _showTutorial(BuildContext context, WidgetRef ref) {
    ref.read(activeTutorialProvider.notifier).state = tutorialId;
    // Trigger tutorial display logic
  }
}
```

## 6. Tutorial Configurations

### 6.1 Daily Closing Tutorial

```dart
class DailyClosingTutorial {
  static final GlobalKey dateSelectionKey = GlobalKey();
  static final GlobalKey summaryCardKey = GlobalKey();
  static final GlobalKey cashManagementKey = GlobalKey();
  static final GlobalKey performClosingKey = GlobalKey();

  static TutorialConfig get config {
    return TutorialConfig(
      tutorialId: 'daily_closing_tutorial',
      screenName: 'DailyClosingScreen',
      titleKey: 'tutorial_daily_closing_title',
      descriptionKey: 'tutorial_daily_closing_desc',
      icon: Icons.lock_clock,
      showOnFirstLaunch: false,
      version: '1.0.0',
      steps: [
        TutorialStep(
          id: 'daily_closing_step_1',
          targetKey: dateSelectionKey,
          titleKey: 'tutorial_daily_closing_step1_title',
          descriptionKey: 'tutorial_daily_closing_step1_desc',
          position: ContentPosition.bottom,
          shape: ShapeLightFocus.RRect(borderRadius: BorderRadius.circular(12)),
          order: 0,
          enablePrevious: false,
        ),
        TutorialStep(
          id: 'daily_closing_step_2',
          targetKey: summaryCardKey,
          titleKey: 'tutorial_daily_closing_step2_title',
          descriptionKey: 'tutorial_daily_closing_step2_desc',
          position: ContentPosition.bottom,
          order: 1,
        ),
        TutorialStep(
          id: 'daily_closing_step_3',
          targetKey: cashManagementKey,
          titleKey: 'tutorial_daily_closing_step3_title',
          descriptionKey: 'tutorial_daily_closing_step3_desc',
          position: ContentPosition.top,
          order: 2,
        ),
        TutorialStep(
          id: 'daily_closing_step_4',
          targetKey: performClosingKey,
          titleKey: 'tutorial_daily_closing_step4_title',
          descriptionKey: 'tutorial_daily_closing_step4_desc',
          position: ContentPosition.top,
          order: 3,
        ),
      ],
    );
  }
}
```

### 6.2 Tutorial Registry

```dart
/// Central registry of all tutorials
class TutorialRegistry {
  final Map<String, TutorialConfig> _tutorials = {};

  TutorialRegistry() {
    _registerTutorials();
  }

  void _registerTutorials() {
    // Register all tutorials
    register(DailyClosingTutorial.config);
    register(OrderManagementTutorial.config);
    register(DashboardTutorial.config);
    // Add more tutorials as needed
  }

  void register(TutorialConfig config) {
    _tutorials[config.tutorialId] = config;
  }

  TutorialConfig? getTutorialById(String id) {
    return _tutorials[id];
  }

  TutorialConfig? getTutorialByScreen(String screenName) {
    return _tutorials.values.firstWhere(
      (config) => config.screenName == screenName,
      orElse: () => null as TutorialConfig,
    );
  }

  List<TutorialConfig> getAllTutorials() {
    return _tutorials.values.toList();
  }
}
```

## 7. Integration Points

### 7.1 Screen Integration

```dart
// In DailyClosingScreen
class DailyClosingScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DailyClosingScreen> createState() => _DailyClosingScreenState();
}

class _DailyClosingScreenState extends ConsumerState<DailyClosingScreen> {
  @override
  void initState() {
    super.initState();

    // Check if tutorial should be shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shouldShow = ref.read(
        shouldShowTutorialProvider('daily_closing_tutorial'),
      );

      if (shouldShow) {
        _showTutorial();
      }
    });
  }

  void _showTutorial() {
    final registry = ref.read(tutorialRegistryProvider);
    final config = registry.getTutorialById('daily_closing_tutorial');

    if (config == null) return;

    // Create and show tutorial coach mark
    final targets = config.sortedSteps.map((step) {
      return TargetFocus(
        identify: step.id,
        keyTarget: step.targetKey,
        shape: step.shape,
        contents: [
          TargetContent(
            align: _contentAlignFromPosition(step.position),
            builder: (context, controller) {
              return TutorialContentWidget(
                titleKey: step.titleKey,
                descriptionKey: step.descriptionKey,
                currentStep: config.sortedSteps.indexOf(step),
                totalSteps: config.steps.length,
                onNext: controller.next,
                onPrevious: controller.previous,
                onSkip: () {
                  controller.skip();
                  _onTutorialSkipped(config.tutorialId);
                },
                showPrevious: step.enablePrevious,
              );
            },
          ),
        ],
      );
    }).toList();

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.8,
      paddingFocus: 10,
      onFinish: () => _onTutorialComplete(config.tutorialId),
      onSkip: () => _onTutorialSkipped(config.tutorialId),
    ).show(context: context);
  }

  void _onTutorialComplete(String tutorialId) {
    ref.read(tutorialPreferenceProvider.notifier).markTutorialComplete(tutorialId);
  }

  void _onTutorialSkipped(String tutorialId) {
    // Optionally prompt "Don't show again"
    // For now, just close
  }

  ContentAlign _contentAlignFromPosition(ContentPosition position) {
    switch (position) {
      case ContentPosition.top:
        return ContentAlign.top;
      case ContentPosition.bottom:
        return ContentAlign.bottom;
      case ContentPosition.left:
        return ContentAlign.left;
      case ContentPosition.right:
        return ContentAlign.right;
      default:
        return ContentAlign.bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyClosing),
        actions: [
          // Add help button
          HelpButton(tutorialId: 'daily_closing_tutorial'),
          // ... other actions
        ],
      ),
      body: Column(
        children: [
          // Date selection with key
          Card(
            key: DailyClosingTutorial.dateSelectionKey,
            child: ListTile(/* ... */),
          ),

          // Summary card with key
          ClosingSummaryCard(
            key: DailyClosingTutorial.summaryCardKey,
            aggregation: aggregation,
          ),

          // Cash management with key
          Card(
            key: DailyClosingTutorial.cashManagementKey,
            child: /* ... */,
          ),

          // Perform closing button with key
          FilledButton(
            key: DailyClosingTutorial.performClosingKey,
            onPressed: _performClosing,
            child: Text(l10n.performClosing),
          ),
        ],
      ),
    );
  }
}
```

### 7.2 Settings Screen Integration

```dart
// Tutorial Settings Screen
class TutorialSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preference = ref.watch(tutorialPreferenceProvider);
    final registry = ref.watch(tutorialRegistryProvider);
    final allTutorials = registry.getAllTutorials();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tutorial_settings),
        actions: [
          TextButton(
            onPressed: () => _showResetConfirmation(context, ref),
            child: Text(l10n.reset_all),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Tutorial list
          ...allTutorials.map((config) {
            final isCompleted = preference.completedTutorials.contains(config.tutorialId);
            final neverShow = preference.neverShowAgain[config.tutorialId] ?? false;

            return ListTile(
              leading: Icon(config.icon),
              title: Text(_getLocalizedText(context, config.titleKey)),
              subtitle: Text(_getLocalizedText(context, config.descriptionKey)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green),
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    tooltip: l10n.play_tutorial,
                    onPressed: () => _playTutorial(context, ref, config.tutorialId),
                  ),
                ],
              ),
              onTap: () => _showTutorialDetails(context, ref, config),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reset_tutorials),
        content: Text(AppLocalizations.of(context)!.reset_tutorials_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(tutorialPreferenceProvider.notifier).resetAllTutorials();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.reset),
          ),
        ],
      ),
    );
  }

  void _playTutorial(BuildContext context, WidgetRef ref, String tutorialId) {
    // Navigate to the screen and trigger tutorial
    // Implementation depends on navigation structure
  }

  void _showTutorialDetails(BuildContext context, WidgetRef ref, TutorialConfig config) {
    // Show detailed view of tutorial steps
  }

  String _getLocalizedText(BuildContext context, String key) {
    // Implement L10n key lookup
    return key;
  }
}
```

## 8. Localization Keys

### 8.1 Required L10n Keys

Add to `app_ko.arb`, `app_en.arb`, `app_vi.arb`:

```json
{
  "help": "도움말",
  "skip": "건너뛰기",
  "next": "다음",
  "previous": "이전",
  "finish": "완료",
  "tutorial_settings": "튜토리얼 설정",
  "reset_all": "모두 초기화",
  "reset_tutorials": "튜토리얼 초기화",
  "reset_tutorials_confirm": "모든 튜토리얼을 초기화하시겠습니까?",
  "play_tutorial": "튜토리얼 재생",

  "tutorial_daily_closing_title": "일일 마감 가이드",
  "tutorial_daily_closing_desc": "일일 마감 프로세스를 단계별로 안내합니다",
  "tutorial_daily_closing_step1_title": "날짜 선택",
  "tutorial_daily_closing_step1_desc": "마감할 날짜를 선택하세요. 오늘 날짜가 기본으로 선택됩니다.",
  "tutorial_daily_closing_step2_title": "매출 요약",
  "tutorial_daily_closing_step2_desc": "당일 총 거래 건수, 매출액, 세금, 할인 등을 확인할 수 있습니다.",
  "tutorial_daily_closing_step3_title": "시재 관리",
  "tutorial_daily_closing_step3_desc": "실제 현금 금액을 입력하여 시재 차액을 확인하세요.",
  "tutorial_daily_closing_step4_title": "마감 수행",
  "tutorial_daily_closing_step4_desc": "모든 정보를 확인한 후 마감을 수행하세요. 마감 후에는 수정할 수 없습니다."
}
```

## 9. Performance Considerations

### 9.1 Lazy Loading
- Tutorial configs are registered on-demand
- GlobalKeys are created once and reused
- Tutorial coach mark package is only imported when needed

### 9.2 Memory Management
- Dispose tutorial coach mark after use
- Clear references to prevent memory leaks
- Use weak references for GlobalKeys where possible

### 9.3 Animation Performance
- Use `RepaintBoundary` for complex tutorial overlays
- Limit animation FPS to 60
- Disable animations on low-end devices (detect via `Platform`)

## 10. Testing Strategy

### 10.1 Unit Tests
```dart
// Test TutorialPreferenceNotifier
test('should mark tutorial as complete', () async {
  final notifier = TutorialPreferenceNotifier(mockRepository);
  await notifier.markTutorialComplete('test_tutorial');

  expect(
    notifier.state.completedTutorials,
    contains('test_tutorial'),
  );
});

// Test shouldShowTutorialProvider
test('should not show completed tutorial', () {
  final container = ProviderContainer(
    overrides: [
      tutorialPreferenceProvider.overrideWith((ref) {
        return TutorialPreferenceNotifier(mockRepository)
          ..state = TutorialPreference(
            completedTutorials: {'test_tutorial'},
          );
      }),
    ],
  );

  final shouldShow = container.read(
    shouldShowTutorialProvider('test_tutorial'),
  );

  expect(shouldShow, false);
});
```

### 10.2 Widget Tests
```dart
testWidgets('HelpButton shows badge when tutorial should be shown', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shouldShowTutorialProvider.overrideWith((ref, arg) => true),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HelpButton(tutorialId: 'test_tutorial'),
        ),
      ),
    ),
  );

  expect(find.byType(Badge), findsOneWidget);
});
```

### 10.3 Integration Tests
- Test complete tutorial flow from start to finish
- Verify tutorial state persistence
- Test navigation between tutorial steps
- Verify L10n key coverage

## 11. Implementation Order

### Phase 1: Foundation (Priority: High)
1. Add `tutorial_coach_mark` to `pubspec.yaml`
2. Create data models (`TutorialStep`, `TutorialConfig`, `TutorialPreference`)
3. Implement `TutorialPreferenceLocalSource` with SharedPreferences
4. Implement `TutorialRepository`
5. Create Riverpod providers

### Phase 2: Core Widgets (Priority: High)
1. Create `TutorialContentWidget`
2. Create `HelpButton`
3. Implement tutorial trigger logic
4. Add L10n keys

### Phase 3: Tutorial Configs (Priority: Medium)
1. Create `DailyClosingTutorial` config
2. Create `TutorialRegistry`
3. Integrate into `DailyClosingScreen`
4. Test on device

### Phase 4: Additional Tutorials (Priority: Medium)
1. Create `OrderManagementTutorial` config
2. Create `DashboardTutorial` config
3. Integrate into respective screens

### Phase 5: Settings & Polish (Priority: Low)
1. Create `TutorialSettingsScreen`
2. Add first-launch detection
3. Implement "Don't show again" dialog
4. Performance optimization
5. Accessibility improvements

## 12. Dependencies

### 12.1 Add to pubspec.yaml

```yaml
dependencies:
  tutorial_coach_mark: ^1.2.11  # Tutorial package
  shared_preferences: ^2.2.2    # Already exists
  flutter_riverpod: ^2.4.9      # Already exists

dev_dependencies:
  mockito: ^5.4.3                # For testing
```

### 12.2 Run Commands

```bash
flutter pub add tutorial_coach_mark
flutter pub get
flutter gen-l10n  # Generate L10n files after adding keys
```

## 13. File Checklist

- [ ] `lib/features/user_guide/data/models/tutorial_preference.dart`
- [ ] `lib/features/user_guide/data/datasources/tutorial_preference_local_source.dart`
- [ ] `lib/features/user_guide/data/repositories/tutorial_repository.dart`
- [ ] `lib/features/user_guide/domain/models/tutorial_step.dart`
- [ ] `lib/features/user_guide/domain/models/tutorial_config.dart`
- [ ] `lib/features/user_guide/presentation/providers/tutorial_state_provider.dart`
- [ ] `lib/features/user_guide/presentation/providers/tutorial_preference_provider.dart`
- [ ] `lib/features/user_guide/presentation/widgets/tutorial_content_widget.dart`
- [ ] `lib/features/user_guide/presentation/widgets/help_button.dart`
- [ ] `lib/features/user_guide/presentation/screens/tutorial_settings_screen.dart`
- [ ] `lib/features/user_guide/configs/daily_closing_tutorial.dart`
- [ ] `lib/features/user_guide/configs/tutorial_registry.dart`
- [ ] `lib/l10n/app_ko.arb` (add tutorial keys)
- [ ] `lib/l10n/app_en.arb` (add tutorial keys)
- [ ] `lib/l10n/app_vi.arb` (add tutorial keys)

## 14. Edge Cases

### 14.1 Screen Rotation
- Tutorial adapts to new screen size
- Content position adjusts automatically
- Progress is not lost

### 14.2 App Backgrounding
- Tutorial state is preserved
- Resume from same step when app returns

### 14.3 Multiple Tutorials
- Only one tutorial active at a time
- Queue tutorials if multiple are triggered
- Prioritize based on importance

### 14.4 Missing Targets
- Gracefully handle missing GlobalKeys
- Skip steps with missing targets
- Log warnings for debugging

### 14.5 Version Updates
- Detect tutorial version mismatches
- Offer to replay updated tutorials
- Migrate old preferences to new format

---

**Document Version**: 1.0
**Created**: 2026-02-10
**Status**: Ready for Implementation
**Next Steps**: Implementation phase - Start with Phase 1 (Foundation)
