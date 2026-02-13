import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../domain/models/tutorial_config.dart';
import '../domain/models/tutorial_step.dart';

/// GlobalKeys for Daily Closing Screen tutorial targets
class DailyClosingTutorialKeys {
  static final dateSelector = GlobalKey();
  static final summaryCard = GlobalKey();
  static final paymentBreakdown = GlobalKey();
  static final cashReconciliation = GlobalKey();
  static final actualCashButton = GlobalKey();
  static final notesSection = GlobalKey();
  static final performClosingButton = GlobalKey();
  static final historyButton = GlobalKey();
}

/// Tutorial configuration for Daily Closing Screen
class DailyClosingTutorial {
  static TutorialConfig get config {
    return TutorialConfig(
      tutorialId: 'daily_closing_tutorial',
      screenName: 'DailyClosingScreen',
      showOnFirstLaunch: false,
      version: '1.0.0',
      steps: [
        // Step 1: Welcome and Overview
        TutorialStep(
          id: 'daily_closing_welcome',
          targetKey: DailyClosingTutorialKeys.dateSelector,
          titleKey: 'tutorial_daily_closing_welcome_title',
          descriptionKey: 'tutorial_daily_closing_welcome_desc',
          position: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
          order: 1,
        ),

        // Step 2: Date Selection
        TutorialStep(
          id: 'daily_closing_date',
          targetKey: DailyClosingTutorialKeys.dateSelector,
          titleKey: 'tutorial_daily_closing_date_title',
          descriptionKey: 'tutorial_daily_closing_date_desc',
          position: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
          order: 2,
        ),

        // Step 3: Summary Card
        TutorialStep(
          id: 'daily_closing_summary',
          targetKey: DailyClosingTutorialKeys.summaryCard,
          titleKey: 'tutorial_daily_closing_summary_title',
          descriptionKey: 'tutorial_daily_closing_summary_desc',
          position: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
          order: 3,
        ),

        // Step 4: Payment Breakdown
        TutorialStep(
          id: 'daily_closing_payment',
          targetKey: DailyClosingTutorialKeys.paymentBreakdown,
          titleKey: 'tutorial_daily_closing_payment_title',
          descriptionKey: 'tutorial_daily_closing_payment_desc',
          position: ContentAlign.bottom,
          shape: ShapeLightFocus.RRect,
          order: 4,
        ),

        // Step 5: Cash Reconciliation
        TutorialStep(
          id: 'daily_closing_cash',
          targetKey: DailyClosingTutorialKeys.cashReconciliation,
          titleKey: 'tutorial_daily_closing_cash_title',
          descriptionKey: 'tutorial_daily_closing_cash_desc',
          position: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
          order: 5,
        ),

        // Step 6: Enter Actual Cash
        TutorialStep(
          id: 'daily_closing_actual_cash',
          targetKey: DailyClosingTutorialKeys.actualCashButton,
          titleKey: 'tutorial_daily_closing_actual_cash_title',
          descriptionKey: 'tutorial_daily_closing_actual_cash_desc',
          position: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
          order: 6,
        ),

        // Step 7: Special Notes
        TutorialStep(
          id: 'daily_closing_notes',
          targetKey: DailyClosingTutorialKeys.notesSection,
          titleKey: 'tutorial_daily_closing_notes_title',
          descriptionKey: 'tutorial_daily_closing_notes_desc',
          position: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
          order: 7,
        ),

        // Step 8: Perform Closing
        TutorialStep(
          id: 'daily_closing_perform',
          targetKey: DailyClosingTutorialKeys.performClosingButton,
          titleKey: 'tutorial_daily_closing_perform_title',
          descriptionKey: 'tutorial_daily_closing_perform_desc',
          position: ContentAlign.top,
          shape: ShapeLightFocus.RRect,
          order: 8,
        ),

        // Step 9: History
        TutorialStep(
          id: 'daily_closing_history',
          targetKey: DailyClosingTutorialKeys.historyButton,
          titleKey: 'tutorial_daily_closing_history_title',
          descriptionKey: 'tutorial_daily_closing_history_desc',
          position: ContentAlign.bottom,
          shape: ShapeLightFocus.Circle,
          order: 9,
        ),
      ],
    );
  }
}
