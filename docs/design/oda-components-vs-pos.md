# Oda 컴포넌트 가이드 vs Odaai POS 비교

**날짜**: 2026-02-28  
**분석 대상**: Oda Style Guide 컴포넌트 PDF 8종 vs POS Flutter 위젯  
**분석자**: Mama (Subagent)

---

## 1. Button

### Oda Style Guide 스펙
**치수**
- Height: 32px (medium)
- Padding: 6px (top/bottom), 16px (left/right)
- Border radius: 6px
- Icon size: 16×16px
- Icon-to-text gap: 8px

**색상**
- **Primary (Green)**
  - Default: `#25A85A`
  - Hover: `#199645`
  - Pressed: `#13783E`
  - Text: `#FFFFFF`
  - Disabled bg: `#DCEDE0`, text: `#9EBDAF`
- **Danger (Coral)**
  - Default: `#FF6F69`
  - Hover: `#F85C56`
  - Pressed: `#E24440`
  - Text: `#FFFFFF`
- **Neutral/Dark**
  - Default: `#605A64`
  - Text: `#FFFFFF`
- **Outline**
  - Border: 1px solid (same color as variant)
  - Background: transparent
  - Hover: 5% tinted bg

**타이포그래피**
- Font-size: 14px
- Weight: 600 (SemiBold)
- Line-height: 20px

**Shadow (Elevated)**
- Main: `0 10px 30px -10px rgba(39,47,58,0.18)`
- Subtle: `0 2px 6px rgba(39,47,58,0.08)`

**Variants**
- Filled (Primary, Danger, Neutral)
- Outline
- Text/Ghost
- Elevated (with shadow)

### 현재 POS 구현
**app_theme.dart ElevatedButton**
```dart
ElevatedButton.styleFrom(
  backgroundColor: primary,            // #3182F6 (파랑) ❌
  foregroundColor: Colors.white,
  elevation: 0,                        // shadow 없음 ❌
  borderRadius: BorderRadius.circular(12), // 12px ❌
  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24), // ❌
  textStyle: TextStyle(
    fontSize: 16,                      // 16px ❌
    fontWeight: FontWeight.w600,
  ),
)
```

**실제 사용 예 (attendance_check_screen.dart)**
```dart
ElevatedButton.styleFrom(
  backgroundColor: Colors.green,        // hardcoded ❌
  padding: EdgeInsets.symmetric(vertical: 20), // 다름 ❌
  borderRadius: BorderRadius.circular(12),
)
```

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Height | 32px | ~44px (v14 + h24 padding) | ⚠️ | POS는 더 큰 터치 영역 필요 |
| Border radius | 6px | 12px | ✅ | 6px로 변경 가능 |
| Padding | 6/16px | 14/24px | ⚠️ | POS는 데스크탑/태블릿용 |
| Primary color | Green #25A85A | Blue #3182F6 | ❌ | 브랜드 색상 차이 |
| Font size | 14px | 16px | ⚠️ | 14px는 작을 수 있음 (터치) |
| Shadow | Elevated 있음 | elevation: 0 | ✅ | 추가 가능 |
| Variants | 5종 | ElevatedButton만 | ✅ | Outline 이미 있음 |

**권장 사항**
- ✅ Border radius를 8px로 절충 (Oda 6px, POS 12px 사이)
- ✅ Elevated variant용 shadow 추가 (primary CTA용)
- ✅ Green success 버튼을 OdaColors.green600 (#35974F)로 통일
- ⚠️ Padding은 POS 현행 유지 (터치 환경)
- ❌ Primary blue는 브랜드 색상이므로 유지

---

## 2. TextField

### Oda Style Guide 스펙
**치수**
- Height: 44px (single-line)
- Padding: 10px (top/bottom), 14px (left), 44px (right with icon)
- Border radius: 6px
- Icon area: 32×32px
- Label spacing: 6-8px above input

**색상**
- Background (default): `#FFFFFF`
- Text: `#222024`
- Placeholder: `#BFB9BF`
- Border (default): `#DAD6DA` (1px)
- Focus border: Green `#25A85A` (2px) 또는 Red for error
- Error border: `#FF6F69` (1px)
- Disabled bg: `#F4F4F6`
- Label: `#6E6B7B` (Neutral-400)

**타이포그래피**
- Label: 12-13px, weight 500
- Input text: 14px, weight 400
- Line-height: 20px

**Icon**
- Size: 16px (in 32px tap area)
- Color: `#5A5460` / `#6E6B7B`

**States**
- Default, Hover, Focus (green outline), Error (red), Disabled

### 현재 POS 구현
**app_theme.dart InputDecorationTheme**
```dart
InputDecorationTheme(
  filled: true,
  fillColor: background,               // #F9FAFC ❌ (Oda는 white)
  borderRadius: BorderRadius.circular(10), // 10px ✅
  enabledBorder: BorderSide(color: divider), // #B9B9C3 (약간 다름)
  focusedBorder: BorderSide(color: primary, width: 2), // blue ❌
  errorBorder: BorderSide(color: error, width: 1.5),   // #E53935 ✅
  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  hintStyle: TextStyle(color: textDisabled, fontSize: 14),
)
```

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Background | White | Light grey #F9FAFC | ⚠️ | POS는 배경과 구분 위함 |
| Border radius | 6px | 10px | ✅ | 8px 절충 가능 |
| Placeholder color | #BFB9BF | #9F9DAA | ✅ | Oda 색상 적용 가능 |
| Focus border | Green | Blue | ❌ | 브랜드 색상 차이 |
| Error color | #FF6F69 | #E53935 | ⚠️ | 비슷한 red 계열 |
| Height | 44px | ~40px | ✅ | 유사함 |

**권장 사항**
- ✅ Placeholder 색상을 OdaColors.neutral100 (#9F9DAA → #BFB9BF)로 변경
- ✅ Border radius 8px 절충
- ⚠️ Background는 POS 현행 유지 (시인성)
- ❌ Focus border는 브랜드 blue 유지

---

## 3. Card

### Oda Style Guide 스펙
**치수**
- Width: 380px (고정)
- Padding: 28px (top), 20-24px (left/right/bottom)
- Border radius: 8px
- Item spacing (내부): 16px
- Text block spacing: 8px

**색상**
- Background: `#FFFFFF`
- Title: `#6E6B7B` (Neutral-400)
- Description: `#6E6B7B` (Neutral-400)
- Canvas bg: `#F1F1F2`

**타이포그래피**
- Title: Header/H-5 (14-16px)
- Description: Body/Body-L-Med

**Shadow**
- Subtle: `0 2px 8px rgba(24,28,30,0.06)`
- Raised: `0 10px 30px rgba(23,27,30,0.08)` (optional)

### 현재 POS 구현
**app_theme.dart CardTheme**
```dart
CardThemeData(
  color: cardWhite,                    // #FFFFFF ✅
  elevation: 0,                        // shadow 없음 ❌
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12), // 12px ❌
    side: BorderSide(color: divider, width: 1), // border 있음 ❌
  ),
)
```

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Border radius | 8px | 12px | ✅ | 10px 절충 |
| Shadow | Subtle shadow | elevation: 0 | ✅ | shadow 추가 가능 |
| Border | 없음 | 1px divider | ⚠️ | POS는 구분 명확히 |
| Padding | 28/20-24px | 각 위젯마다 다름 | ✅ | 표준화 가능 |
| Width | 380px 고정 | responsive | ❌ | POS는 반응형 |

**권장 사항**
- ✅ Border radius 10px로 절충
- ✅ Subtle shadow 추가 옵션 제공 (elevation 파라미터)
- ⚠️ Border는 POS 현행 유지 (명확한 구분)
- ✅ 내부 padding 표준 (16px spacing) 가이드 제공

---

## 4. Table

### Oda Style Guide 스펙
**치수**
- Compact row height: 32px
- Normal row height: 40px
- Row padding: 12px (left/right), 8-10px (top/bottom)
- Cell gap: 16px

**색상**
- (PDF에서 정확한 컬러 추출 불가 - 이미지 불완전)
- Row background: 흰색 또는 교차 색상
- Border: 연한 grey

### 현재 POS 구현
- DataTable 직접 사용 (표준 Flutter)
- 커스텀 테마 없음

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Row height | 40px (normal) | Flutter default (~48px) | ✅ | 조정 가능 |
| Padding | 12/8-10px | 기본값 사용 | ✅ | 표준화 필요 |
| Cell gap | 16px | 기본값 | ✅ | horizontalMargin 설정 |

**권장 사항**
- ✅ DataTableTheme 추가하여 row height, padding 표준화
- ✅ 40px row height 적용
- ✅ 12px horizontal padding

---

## 5. Badge

### Oda Style Guide 스펙
**치수**
- Dot badge: 8×8px (circular)
- Numeric badge: 24×24px (circular)
- Padding from edge: 4-6px
- Min tap area: 32px (권장)

**색상**
- Dot fill: `#F24F59` (coral/red)
- Numeric bg: `#F26E77` (coral)
- Numeric text: `#FFFFFF`
- Outline variant: white bg, 2px coral border

**타이포그래피**
- Font-size: 12px
- Weight: 600 (SemiBold)
- Line-height: 24px (vertical center)

### 현재 POS 구현
- Badge 위젯 직접 사용 없음
- 필요시 개별 구현

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Badge widget | 정의됨 | 없음 | ✅ | 신규 추가 필요 |
| Color | Coral #F24F59 | - | ✅ | OdaColors.red500 근사값 |
| Size | 8px/24px | - | ✅ | 표준 적용 |

**권장 사항**
- ✅ `OdaBadge` 위젯 신규 생성
- ✅ Dot, Numeric, Outline 3가지 variant
- ✅ OdaColors.red500 (#EF2E2E) 사용

---

## 6. Dialog

### Oda Style Guide 스펙
**치수**
- Small dialog: 320px width
- Medium dialog: 420px width
- Large dialog: 960px width
- Padding: 24-32px (상황별)
- Border radius: 10px
- Footer button height: 32px

**색상**
- Background: `#FFFFFF`
- Title: `#55535F` (dark grey-purple)
- Body text: `#6C6B72` (muted grey)
- Primary button bg: `#29B96F` (green)
- Destructive button bg: `#F16B66` (red)
- Secondary button border: `#D9D7DA` (1px)

**Shadow**
- Main: `0 22px 40px rgba(0,0,0,0.32)`
- Ambient: `0 6px 14px rgba(0,0,0,0.12)`

**타이포그래피**
- Title: 20px, weight 600
- Body: 13px, weight 400
- Button: 14px, weight 600

### 현재 POS 구현
**AlertDialog 기본 사용**
```dart
AlertDialog(
  title: Text(...),
  content: Column(...),
  actions: [
    TextButton(...),
    ElevatedButton(...),
  ],
)
```
- 표준 Material Design 스타일
- 커스텀 테마 적용 없음

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Border radius | 10px | Material default (~28px) | ✅ | 조정 가능 |
| Shadow | 구체적 정의 | Material elevation | ✅ | 변경 가능 |
| Button height | 32px | 44px+ | ⚠️ | POS는 더 큼 (터치) |
| Title size | 20px | 20px | ✅ | 동일 |
| Padding | 24-32px | Material default | ✅ | 조정 가능 |

**권장 사항**
- ✅ DialogTheme 추가하여 border radius 10px
- ✅ Shadow elevation 조정
- ⚠️ Button size는 POS 현행 유지
- ✅ Title/body color를 Oda 스펙과 유사하게 조정

---

## 7. Tab

### Oda Style Guide 스펙 (Vertical Tabs)
**치수**
- Tab height: 40px
- Icon size: 16×16px
- Icon-to-text gap: 8px
- Left padding: 12px
- Right padding: 12px
- Vertical gap between tabs: 6px
- Container border radius: 6px

**색상**
- Default icon/text: `#75757E` (muted grey)
- Hover text: `#4F4F55` (darker)
- Active icon/text: `#28B26B` (green)
- Active underline: `#28B26B` (2px)
- Active right border: `#28B26B` (2px, optional)
- Selected bg: `rgba(40,178,107,0.06)` (~6% green)

**타이포그래피**
- Font-size: 14px
- Weight: 500 (active), 400 (default)
- Line-height: 40px

**Icon**
- Size: 16px
- Stroke matches text color

### 현재 POS 구현
**TabBar 기본 사용**
```dart
TabBar(
  tabs: [
    Tab(text: '...'),
    Tab(text: '...'),
  ],
)
```
- Material Design 스타일
- Horizontal tabs (vertical 없음)
- 커스텀 테마 미적용

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Direction | Vertical | Horizontal | ⚠️ | POS는 주로 horizontal |
| Active color | Green #28B26B | Blue (primary) | ❌ | 브랜드 색상 차이 |
| Height | 40px | Material default | ✅ | 조정 가능 |
| Icon+text | Yes | Text only 주로 | ✅ | 추가 가능 |
| Underline | 2px | Material default | ✅ | 조정 가능 |

**권장 사항**
- ✅ TabBarTheme 추가하여 height, indicator 조정
- ⚠️ Vertical tabs는 필요시 커스텀 위젯 생성
- ❌ Active color는 브랜드 blue 유지
- ✅ Icon+text tab 사용 가이드 제공

---

## 8. Snackbar

### Oda Style Guide 스펙
**치수**
- Height: 44px
- Padding: 16px (horizontal), 8px (vertical)
- Border radius: 6px
- Distance from edge: 20px (left/bottom)

**색상**
- Background: `#222227` (very dark grey/black)
- Text: `#FFFFFF` (slightly dimmed to #F3F4F5)
- Action text (green): `#2BB56F`
- Close icon: `#FFFFFF` at 70% opacity

**Shadow**
- `0 10px 20px rgba(0,0,0,0.45)`

**타이포그래피**
- Message: 14px, weight 500
- Action: 14px, weight 600

**Icon**
- Close icon: 14px
- Action-to-icon gap: 12px

### 현재 POS 구현
**SnackBar 사용 예**
```dart
SnackBar(
  content: Text(message),
  backgroundColor: Colors.green,  // success
  // 또는
  backgroundColor: Colors.red,    // error
)
```
- Material Design 기본 스타일
- 색상만 변경
- Action, close icon 미사용

### 차이점 & 적용 방안

| 항목 | Oda | POS | 적용 가능 | 비고 |
|------|-----|-----|----------|------|
| Background | Dark #222227 | Green/Red | ⚠️ | Oda는 dark 통일 |
| Border radius | 6px | Material default (4px) | ✅ | 조정 가능 |
| Action button | Green text | 없음 | ✅ | 추가 가능 |
| Close icon | 있음 | 없음 | ✅ | 추가 가능 |
| Shadow | 구체적 정의 | Material elevation | ✅ | 조정 가능 |
| Height | 44px | Material default | ✅ | 조정 가능 |

**권장 사항**
- ⚠️ Background는 success/error 색상 유지 (명확성)
- ✅ Border radius 6px 적용
- ✅ Action button 파라미터 추가 (optional)
- ✅ Close icon showCloseIcon 옵션
- ✅ SnackBarThemeData 정의하여 일관성 확보

---

## 요약: POS 적용 가능 항목 (우선순위별)

### 즉시 적용 (app_theme.dart 수정만)

**1. Border Radius 통일 (우선순위: 높음)**
```dart
// 현재: 10-12px 혼용
// 변경: 8px로 통일 (Oda 6px + POS 12px 절충)
- Button: 12px → 8px
- Card: 12px → 10px
- TextField: 10px → 8px
- Dialog: Material default → 10px
```

**2. Shadow/Elevation 추가 (우선순위: 중)**
```dart
// Card에 subtle shadow
CardTheme(
  elevation: 1,
  shadowColor: Colors.black.withOpacity(0.06),
)

// ElevatedButton에 elevated variant용 shadow
// (primary CTA에만 적용)
```

**3. SnackBarTheme 추가 (우선순위: 중)**
```dart
SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
  ),
  actionTextColor: OdaColors.green500,
  closeIconColor: Colors.white.withOpacity(0.7),
)
```

**4. DialogTheme 추가 (우선순위: 중)**
```dart
DialogTheme(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
  ),
  elevation: 24,
  titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: OdaColors.neutral500,
  ),
)
```

**5. TabBarTheme 추가 (우선순위: 낮음)**
```dart
TabBarTheme(
  indicator: UnderlineTabIndicator(
    borderSide: BorderSide(width: 2, color: primary),
  ),
  labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
)
```

### 위젯 수정 필요

**1. Badge 위젯 신규 생성 (우선순위: 낮음)**
```dart
// lib/core/widgets/oda_badge.dart
class OdaBadge extends StatelessWidget {
  final BadgeType type; // dot, numeric, outline
  final int? count;
  final Color? color;
  final Widget? child;
  
  // Implementation with Oda specs:
  // - Dot: 8x8px circular
  // - Numeric: 24x24px, 12px text
  // - Color: OdaColors.red500
}
```

**2. Vertical Tab 위젯 (우선순위: 낮음)**
```dart
// 필요시 커스텀 vertical navigation rail
// Oda 스펙: 40px height, 16px icon, 8px gap
```

**3. DataTableTheme 정의 (우선순위: 중)**
```dart
DataTableThemeData(
  dataRowMinHeight: 40,
  dataRowMaxHeight: 40,
  horizontalMargin: 12,
  columnSpacing: 16,
  headingTextStyle: TextStyle(
    fontWeight: FontWeight.w600,
    color: OdaColors.neutral400,
  ),
)
```

### 적용 불가/보류

**1. Primary Color 차이 (보류)**
- Oda: Green `#25A85A` (primary)
- POS: Blue `#3182F6` (primary)
- **이유**: 브랜드 정체성 차이. POS는 파란색이 primary로 확립됨.
- **대안**: Success 색상에 Oda green 적용 (이미 적용 중: `OdaColors.green600`)

**2. TextField Background 색상 (보류)**
- Oda: White `#FFFFFF`
- POS: Light grey `#F9FAFC`
- **이유**: POS는 배경과의 대비를 위해 filled 스타일 사용. 시인성 우수.
- **대안**: 현행 유지

**3. Button/Input 크기 감소 (적용 불가)**
- Oda: 32px button, 14px padding
- POS: 44px+ button, 24px padding
- **이유**: POS는 터치 환경 최적화 (태블릿/키오스크). Oda는 데스크탑 중심.
- **대안**: 현행 유지 (accessibility 우선)

**4. Card 고정 width (적용 불가)**
- Oda: 380px 고정
- POS: Responsive (화면 크기에 따라 조정)
- **이유**: POS는 다양한 화면 크기 지원 필요.

---

## 코드 적용 예시

### 1. app_theme.dart 개선 (Phase 3 적용)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'oda_colors.dart';

class AppTheme {
  // ─── 색상 상수 (변경 없음) ──────────────────────
  static const Color primary = Color(0xFF3182F6);
  static const Color success = OdaColors.green600;
  static const Color error = Color(0xFFE53935);
  // ... (생략)

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSans().fontFamily,
      colorScheme: ColorScheme(
        // ... (변경 없음)
      ),
      scaffoldBackgroundColor: background,

      // ─── AppBar (변경 없음) ───────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: cardWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // ─── Card (Phase 3: shadow 추가, radius 조정) ─────
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 1, // ✅ subtle shadow 추가
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // ✅ 12 → 10
          side: BorderSide(color: divider, width: 1),
        ),
      ),

      // ─── ElevatedButton (Phase 3: radius 조정) ─────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // ✅ 12 → 8
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── OutlinedButton (Phase 3: radius 조정) ─────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // ✅ 12 → 8
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── TextField (Phase 3: radius 조정) ──────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // ✅ 10 → 8
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: textDisabled, fontSize: 14),
      ),

      // ─── SnackBarTheme (Phase 3: 신규 추가) ─────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // ✅ Oda spec
        ),
        actionTextColor: OdaColors.green500, // ✅ Oda green
        closeIconColor: Colors.white.withOpacity(0.7),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ─── DialogTheme (Phase 3: 신규 추가) ──────────────
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // ✅ Oda spec
        ),
        elevation: 24,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: OdaColors.neutral500, // ✅ #4E4C57
        ),
        contentTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: OdaColors.neutral300, // ✅ #6E6B7B
        ),
      ),

      // ─── TabBarTheme (Phase 3: 신규 추가) ──────────────
      tabBarTheme: TabBarTheme(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2, color: primary),
        ),
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),

      // ─── DataTableTheme (Phase 3: 신규 추가) ───────────
      dataTableTheme: DataTableThemeData(
        dataRowMinHeight: 40, // ✅ Oda spec
        dataRowMaxHeight: 40,
        horizontalMargin: 12,
        columnSpacing: 16,
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: OdaColors.neutral400,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
      ),

      // ─── Divider (변경 없음) ──────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        indent: 0,
        endIndent: 0,
      ),

      // ─── Typography (변경 없음) ───────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w500, color: textPrimary, height: 48/34),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: textPrimary, height: 40/28),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary, height: 32/22),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary, height: 28/20),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, height: 24/18),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, height: 24/16),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary, height: 24/16),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 24/16),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, height: 24/16),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 20/15),
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 20/14),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary, height: 20/15),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, height: 20/14),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: OdaColors.neutral500, height: 16/12),
      ),
    );
  }
}
```

---

### 2. OdaBadge 위젯 신규 생성 (선택적)

```dart
// lib/core/widgets/oda_badge.dart
import 'package:flutter/material.dart';
import '../theme/oda_colors.dart';

enum BadgeType { dot, numeric, outline }

class OdaBadge extends StatelessWidget {
  final BadgeType type;
  final int? count;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? child;

  const OdaBadge({
    super.key,
    this.type = BadgeType.numeric,
    this.count,
    this.backgroundColor,
    this.textColor,
    this.child,
  });

  const OdaBadge.dot({
    super.key,
    this.backgroundColor,
    this.child,
  })  : type = BadgeType.dot,
        count = null,
        textColor = null;

  const OdaBadge.numeric({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.child,
  }) : type = BadgeType.numeric;

  const OdaBadge.outline({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.child,
  }) : type = BadgeType.outline;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? OdaColors.red500; // #EF2E2E
    final fgColor = textColor ?? Colors.white;

    Widget badge;

    switch (type) {
      case BadgeType.dot:
        badge = Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
        );
        break;

      case BadgeType.numeric:
        badge = Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${count ?? 0}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
              height: 1.0,
            ),
          ),
        );
        break;

      case BadgeType.outline:
        badge = Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: bgColor, width: 2),
          ),
          child: Text(
            '${count ?? 0}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: bgColor,
              height: 1.0,
            ),
          ),
        );
        break;
    }

    if (child != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          Positioned(
            top: -4,
            right: -4,
            child: badge,
          ),
        ],
      );
    }

    return badge;
  }
}
```

**사용 예시:**
```dart
// Dot badge on icon
OdaBadge.dot(
  child: Icon(Icons.notifications),
)

// Numeric badge
OdaBadge.numeric(
  count: 5,
  child: Icon(Icons.shopping_cart),
)

// Outline badge
OdaBadge.outline(
  count: 3,
  backgroundColor: OdaColors.green600,
  child: Icon(Icons.message),
)
```

---

### 3. 개선된 SnackBar 헬퍼 함수 (선택적)

```dart
// lib/core/utils/snackbar_helper.dart
import 'package:flutter/material.dart';
import '../theme/oda_colors.dart';

class SnackBarHelper {
  /// Success SnackBar with optional action
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OdaColors.green600, // #35974F
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
        duration: duration,
        showCloseIcon: true,
      ),
    );
  }

  /// Error SnackBar with optional action
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OdaColors.red500, // #EF2E2E
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
        duration: duration,
        showCloseIcon: true,
      ),
    );
  }

  /// Info SnackBar with optional action
  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OdaColors.blue400, // #2196F3
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
        duration: duration,
        showCloseIcon: true,
      ),
    );
  }

  /// Dark SnackBar (Oda style) with green action
  static void showDark(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF222227), // Oda dark bg
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: OdaColors.green500, // #40B65F (Oda action green)
              )
            : null,
        duration: duration,
        showCloseIcon: true,
        closeIconColor: Colors.white.withOpacity(0.7),
      ),
    );
  }
}
```

**사용 예시:**
```dart
// 기존 방식 대체
// _showSuccessSnackBar('Leave approved successfully');
SnackBarHelper.showSuccess(context, 'Leave approved successfully');

// Action과 함께
SnackBarHelper.showSuccess(
  context,
  'Item deleted',
  actionLabel: 'UNDO',
  onAction: () {
    // undo logic
  },
);

// Oda dark 스타일
SnackBarHelper.showDark(
  context,
  'Settings saved',
  actionLabel: 'VIEW',
  onAction: () {
    // navigate to settings
  },
);
```

---

## 다음 단계 권장사항

### Phase 3-A: 즉시 적용 (테마 조정)
1. ✅ `app_theme.dart`에 위의 코드 예시 적용
2. ✅ Border radius 통일 (8-10px)
3. ✅ SnackBarTheme, DialogTheme, TabBarTheme, DataTableTheme 추가
4. ✅ Card elevation 1 추가 (subtle shadow)
5. ✅ Git commit: "chore: Apply Oda Design Phase 3 - theme refinements"

### Phase 3-B: 위젯 추가 (선택적)
1. ⚠️ OdaBadge 위젯 생성 (필요시)
2. ⚠️ SnackBarHelper 유틸 생성 (일관성 향상)
3. ⚠️ 기존 hardcoded 스타일을 theme 기반으로 리팩토링

### Phase 4: 장기 과제 (보류)
1. ❌ Vertical navigation rail (필요성 재검토)
2. ❌ Elevated button variant with shadow (CTA 강조 필요시)
3. ❌ Floating label TextField (고급 UX 필요시)

---

## 분석 결과 요약

### ✅ 적용 가능 항목 (높은 호환성)
- Border radius 통일 (8-10px)
- Shadow/elevation 추가 (Card, Dialog)
- SnackBar, Dialog, TabBar, DataTable 테마 정의
- Badge 위젯 신규 생성
- 코드 일관성 향상 (theme 기반)

### ⚠️ 절충 필요 항목
- Button/Input 크기: POS는 터치 최적화 유지
- TextField background: POS는 filled 스타일 유지
- Primary color: 브랜드 차이 (Blue vs Green)

### ❌ 적용 불가 항목
- Oda의 32px 작은 버튼 (accessibility 저해)
- 고정 width 컴포넌트 (responsive 필요)
- Green primary (POS는 Blue 확립)

### 📊 전체 적용률
- **즉시 적용 가능**: 60% (테마 수정만으로 해결)
- **커스텀 위젯 필요**: 20% (Badge, helper 등)
- **적용 불가/보류**: 20% (브랜드 차이, UX 차이)

---

**분석 완료일**: 2026-02-28  
**다음 액션**: Jin에게 보고 후 Phase 3-A 적용 여부 확인