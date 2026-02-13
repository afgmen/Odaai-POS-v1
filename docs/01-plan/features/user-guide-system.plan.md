# Plan: User Guide System

## 1. Overview

### Feature Name
Interactive User Guide System (사용자 가이드 시스템)

### Purpose
Provide an interactive tutorial system that helps new users understand how to use the POS application by showing guided walkthroughs with images, arrows, popup notes, and slide navigation.

### Target Users
- New employees learning the POS system
- Managers training staff
- Users who need help with specific features

### Business Value
- Reduced training time and costs
- Improved user onboarding experience
- Decreased support requests
- Better feature discovery
- Increased user confidence and satisfaction

## 2. Requirements

### Functional Requirements

#### FR-01: Tutorial Package Integration
- Use Flutter showcase/tutorial packages (tutorial_coach_mark, showcaseview)
- Support overlay-based tutorials with customizable widgets
- Allow sequential step-by-step guidance

#### FR-02: Multi-Screen Coverage
- Main Dashboard tutorial
- Order Management screen tutorial
- Daily Closing screen tutorial
- Product Management screen tutorial
- Settings screen tutorial

#### FR-03: Interactive Elements
- **Arrows**: Point to specific UI elements
- **Popup Notes**: Show contextual information and instructions
- **Slide Navigation**: Previous/Next buttons to navigate tutorial steps
- **Skip Option**: Allow users to exit tutorial anytime
- **Progress Indicator**: Show current step (e.g., "3/10")

#### FR-04: Tutorial Content Management
- Multi-language support (Korean, English, Vietnamese)
- Configurable tutorial steps per screen
- Ability to enable/disable tutorials for specific screens

#### FR-05: User Preferences
- "Don't show again" option for each tutorial
- Remember which tutorials have been completed
- Reset tutorials option in Settings

#### FR-06: Tutorial Triggers
- Auto-show on first app launch (onboarding)
- Manual trigger via "Help" menu button
- Context-sensitive help button on each screen

### Non-Functional Requirements

#### NFR-01: Performance
- Tutorials should not impact app performance
- Smooth animations (60fps)
- Minimal memory footprint

#### NFR-02: Usability
- Clear and concise instructions
- Intuitive navigation
- Consistent visual design across all tutorials

#### NFR-03: Maintainability
- Easy to add new tutorial steps
- Centralized tutorial configuration
- Reusable tutorial components

## 3. Technical Approach

### Package Selection
**Primary Choice**: `tutorial_coach_mark` package
- Pros: Highly customizable, active maintenance, good documentation
- Features: Custom widgets, sequential steps, skip functionality
- Alternative: `showcaseview` (simpler but less flexible)

### Architecture

```
lib/features/user_guide/
├── data/
│   ├── tutorial_config.dart          # Tutorial step configurations
│   └── tutorial_preference_dao.dart  # SharedPreferences for user choices
├── domain/
│   ├── models/
│   │   └── tutorial_step.dart        # Tutorial step model
│   └── services/
│       └── tutorial_service.dart     # Business logic for tutorials
├── presentation/
│   ├── widgets/
│   │   ├── tutorial_overlay.dart     # Custom overlay widgets
│   │   ├── tutorial_arrow.dart       # Arrow indicators
│   │   └── tutorial_popup.dart       # Popup note widgets
│   └── controllers/
│       └── tutorial_controller.dart  # Riverpod provider for tutorial state
└── tutorial_registry.dart            # Central registry of all tutorials
```

### Tutorial Step Model

```dart
class TutorialStep {
  final String id;
  final GlobalKey targetKey;           // Widget to highlight
  final String titleKey;               // L10n key for title
  final String descriptionKey;         // L10n key for description
  final ContentPosition position;      // Where to show popup
  final Widget? customContent;         // Optional custom widget
  final Duration displayDuration;
  final bool enableSkip;
}
```

### Storage
- Use SharedPreferences to store:
  - Completed tutorials: `Set<String>` of tutorial IDs
  - Don't show again flags: `Map<String, bool>`
  - First launch flag: `bool`

## 4. User Stories

### US-01: First Time User Onboarding
**As a** new employee
**I want** to see a guided tutorial when I first open the app
**So that** I can quickly learn how to use the basic features

**Acceptance Criteria**:
- Tutorial auto-starts on first app launch
- Shows 5-7 essential steps covering main navigation
- User can skip or complete the tutorial
- Tutorial doesn't auto-show again after completion

### US-02: Feature-Specific Help
**As a** user learning a specific feature
**I want** to access help for the current screen
**So that** I can understand how to use that particular feature

**Acceptance Criteria**:
- Help button available on each major screen
- Tutorial shows relevant steps for that screen only
- User can navigate through steps at their own pace
- Clear visual indicators (arrows, highlights) point to UI elements

### US-03: Tutorial Management
**As a** user
**I want** to manage my tutorial preferences
**So that** I can control when and how tutorials appear

**Acceptance Criteria**:
- Settings screen has tutorial management section
- Option to reset all tutorials
- List of available tutorials with completion status
- Ability to replay any tutorial on demand

## 5. Screens Affected

### Primary Screens (Must Have Tutorials)
1. **Main Dashboard** - App navigation basics
2. **Order Management** - Creating and managing orders
3. **Daily Closing** - End-of-day procedures
4. **Product Management** - Adding/editing products

### Secondary Screens (Nice to Have)
5. **Settings** - App configuration
6. **Reports** - Viewing sales reports
7. **Customer Management** - Customer data management

## 6. Dependencies

### Flutter Packages
```yaml
dependencies:
  tutorial_coach_mark: ^1.2.11  # Main tutorial package
  shared_preferences: ^2.2.2    # Already in project (for preferences)

  # Already available in project:
  flutter_riverpod: ^2.4.9      # State management
  intl: ^0.18.1                 # Internationalization
```

### Internal Dependencies
- L10n system (for multi-language support)
- SharedPreferences for persistence
- Existing navigation system
- Theme system (for consistent styling)

## 7. Implementation Phases

### Phase 1: Foundation (Days 1-2)
- Add tutorial_coach_mark package
- Create basic data models and services
- Set up tutorial registry structure
- Implement SharedPreferences storage

### Phase 2: Core Widgets (Days 3-4)
- Create custom tutorial overlay widgets
- Implement arrow and popup components
- Build tutorial controller with Riverpod
- Add navigation controls (prev/next/skip)

### Phase 3: Content Creation (Days 5-6)
- Define tutorial steps for Main Dashboard
- Define tutorial steps for Daily Closing screen
- Define tutorial steps for Order Management
- Add all L10n translations

### Phase 4: Integration (Days 7-8)
- Integrate tutorials into screens
- Add help buttons to AppBar
- Implement first-launch detection
- Create Settings UI for tutorial management

### Phase 5: Testing & Polish (Days 9-10)
- Test all tutorials on different screen sizes
- Verify L10n coverage
- Performance testing
- Bug fixes and refinements

## 8. Success Metrics

### Quantitative Metrics
- Tutorial completion rate > 70%
- Average tutorial duration < 3 minutes per screen
- Reduced support tickets related to basic usage by 40%
- New user activation rate increase by 25%

### Qualitative Metrics
- User feedback on tutorial helpfulness
- Ease of adding new tutorial steps
- Developer satisfaction with tutorial system

## 9. Risks and Mitigations

### Risk 1: Poor Package Maintenance
**Impact**: Medium
**Probability**: Low
**Mitigation**: Choose well-maintained packages with recent updates; prepare to fork if needed

### Risk 2: Performance Impact on Older Devices
**Impact**: Medium
**Probability**: Medium
**Mitigation**: Optimize animations; test on low-end devices; provide option to disable animations

### Risk 3: L10n Content Explosion
**Impact**: Low
**Probability**: High
**Mitigation**: Keep tutorial text concise; use shared phrases where possible; prioritize Korean initially

### Risk 4: Tutorial Becomes Outdated
**Impact**: High
**Probability**: High
**Mitigation**: Create maintenance schedule; document tutorial update process; version tutorial content

## 10. Future Enhancements

### V2 Features (Post-MVP)
- Video tutorials embedded in popups
- Interactive practice mode (sandbox)
- Adaptive tutorials based on user role
- Analytics tracking for tutorial effectiveness
- Remote configuration of tutorial content
- Gamification (badges for completing tutorials)
- Screen recording to create custom tutorials

### Integration Opportunities
- Integrate with onboarding checklist
- Link to detailed help documentation
- Connect to customer support chat
- Embed in employee training system

## 11. Open Questions

1. Should tutorials be mandatory for first-time users or optional?
2. How often should we prompt users to complete uncompleted tutorials?
3. Should we track analytics on tutorial usage (privacy considerations)?
4. Do we need admin controls to customize tutorials per location/franchise?
5. Should we support custom tutorials created by managers?

## 12. Stakeholder Review

### Questions for Product Owner
- Which screens are highest priority for tutorials?
- What is acceptable tutorial length (number of steps)?
- Should tutorials be required before using sensitive features (e.g., Daily Closing)?

### Questions for UX Designer
- Preferred visual style for arrows and popups?
- Animation preferences (duration, easing)?
- Color scheme for tutorial overlays?

### Questions for Development Team
- Any concerns about the chosen package?
- Preferred state management approach for tutorial state?
- Testing strategy for tutorials?

---

**Document Version**: 1.0
**Created**: 2026-02-10
**Status**: Draft
**Next Steps**: Design phase - Create detailed technical design document
