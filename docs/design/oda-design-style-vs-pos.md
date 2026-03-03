# Oda Design Style Guide vs Odaai POS — 비교 분석

## 1. Oda Design Style Guide 요약

### 1.1 Colors

#### Primary/Brand Colors
- **Green (Primary)**: 브랜드의 메인 컬러
  - Green-60: `#F0FAF3` (가장 연한)
  - Green-80: `#D2EFDA`
  - Green-100: `#B4E4C1`
  - Green-200: `#95DAA8`
  - Green-300: `#77CF8F`
  - Green-400: `#59C576`
  - Green-500: `#40B65F`
  - Green-600: `#35974F` ⭐ (Success color로 사용)
  - Green-700: `#2A793F`
  - Green-800: `#205B2F`
  - Green-900: `#153C20` (가장 진한)

#### Secondary Colors
- **Blue (Secondary)**: 정보 표시
  - Blue-60: `#ECF6FE`
  - Blue-80: `#ECF6FE`
  - Blue-100: `#9ED1FA`
  - Blue-200: `#77BEF8`
  - Blue-300: `#51ABF6`
  - Blue-400: `#2196F3` ⭐ (Info color로 사용)
  - Blue-500: `#0C85E9`
  - Blue-600: `#0A6FC2`
  - Blue-700: `#08599B`
  - Blue-800: `#064374`
  - Blue-900: `#042C4E`

- **Orange (Secondary)**: 경고
  - Orange-80: `#FDF4ED`
  - Orange-100: `#F8DEC9`
  - Orange-200: `#F3C8A5`
  - Orange-300: `#EFB281`
  - Orange-400: `#EA9C5D`
  - Orange-500: `#E58435` ⭐ (Warning color로 사용)
  - Orange-600: `#D9711C`
  - Orange-700: `#B55E17`
  - Orange-800: `#904B13`
  - Orange-900: `#6C380E`

#### System Colors
- **Success**: Green-600 `#35974F`
- **Info**: Blue-400 `#2196F3`
- **Danger**: Red-500 `#EF2E2E`
- **Warning**: Orange-500 `#E58435`

#### Red (Danger/Error)
- Red-60: `#FFF6F6`
- Red-80: `#FEECEC`
- Red-100: `#FBC6C6`
- Red-200: `#F8A0A0`
- Red-300: `#F46A6A`
- Red-400: `#F25454`
- Red-500: `#EF2E2E` ⭐ (Danger color)
- Red-600: `#E41111`
- Red-700: `#BE0E0E`
- Red-800: `#980B0B`
- Red-900: `#720909`

#### Yellow
- Yellow-80: `#FFF9EC`
- Yellow-100: `#FEEDC4`
- Yellow-200: `#FEE19D`
- Yellow-300: `#FED677`
- Yellow-400: `#FFCB44`
- Yellow-500: `#FDBE37`
- Yellow-600: `#F3AE29`
- Yellow-700: `#CB9120`
- Yellow-800: `#A27418`
- Yellow-900: `#79570F`

#### Neutral (Text & Background)
- Neutral-05: `#F9FAFC` (Canvas)
- Neutral-5: `#F7F7F8` (Sidebar/Hover)
- Neutral-10: `#F3F2F7`
- Neutral-20: `#EBE9F1`
- Neutral-40: `#DFDEE3` (Side bar/Border group cell)
- Neutral-60: `#CAC8D0`
- Neutral-80: `#B9B9C3` (Line)
- Neutral-100: `#9F9DAA`
- Neutral-200: `#8A8797` (Text 2 - secondary)
- Neutral-300: `#6E6B7B`
- Neutral-400: `#615F6D` (Text 1 - primary)
- Neutral-500: `#4E4C57`
- Neutral-600: `#373435` (Black Primary)
- Neutral-700: `#27262C`
- Neutral-800: `#131316`
- Neutral-900: (텍스트에서 누락)

#### Grey
- Grey-40: `#F5F5F5` (Side bar/Hover in grid cell)
- Grey-60: `#E0E0E0`
- Grey-80: `#C4C4C4`
- Grey-100: `#B8B8B8`
- Grey-200: `#A3A3A3`
- Grey-300: `#8F8F8F`
- Grey-400: `#7A7A7A`
- Grey-500: `#666666`
- Grey-600: `#525252`
- Grey-700: `#3D3D3D`
- Grey-800: `#292929`
- Grey-900: `#141414`

#### Monochrome
- White: `#FFFFFF`
- Black: `#000000`

### 1.2 Typography

**폰트 패밀리**: Noto Sans

#### Header
| 스타일 | Weight | Size/Line-height | 용도 |
|--------|--------|------------------|------|
| H-1 | Medium (500) | 34px / 48px | 타이틀 (예: HQ dashboard) |
| H-2 | Medium (500) | 28px / 40px | 서브타이틀 (예: Buy-Sell, Summary) |
| H-3 | SemiBold (600) | 22px / 32px | |
| H-4 | SemiBold (600) | 20px / 28px | |
| H-5 | SemiBold (600) | 18px / 24px | |
| H-6 | Medium (500) | 16px / 24px | |

#### Body
| 스타일 | Weight | Size/Line-height | 용도 |
|--------|--------|------------------|------|
| Body-L-Bold | SemiBold (600) | 16px / 24px | |
| Body-L-Semi | SemiBold (600) | 16px / 24px | |
| Body-L-Med | Medium (500) | 16px / 24px | 주요 텍스트 |
| Body-L-Reg | Regular (400) | 16px / 24px | |
| Body-M-Reg | Regular (400) | 15px / 20px | |
| Body-S-Reg | Regular (400) | 14px / 20px | |

#### Caption
| 스타일 | Weight | Size/Line-height |
|--------|--------|------------------|
| Caption-L | Medium (500) | 15px / 20px |
| Caption-M | Medium (500) | 14px / 20px |
| Caption-S | Medium (500) | 12px / 16px |
| Caption-XS | Medium (500) | 10px / 16px |

#### Button
| 스타일 | Weight | Size/Line-height | 용도 |
|--------|--------|------------------|------|
| Button-L-Semi | SemiBold (600) | 18px / 28px | |
| Button-L-Medi | Medium (500) | 18px / 28px | |
| Button-L-Regu | Regular (400) | 18px / 24px | |
| Button-M-Semi | SemiBold (600) | 16px / 24px | |
| Button-M-Medi | Medium (500) | 16px / 24px | |
| Button-M-Regu | Regular (400) | 16px / 20px | 메인 버튼 |

### 1.3 Icons

Oda Style Guide는 다음 아이콘 카테고리를 포함:
- Action
- Alert
- Av (Audio/Video)
- Device
- Hardware
- Home
- Maps
- Places
- Image
- Search
- Communication
- Content
- Editor
- Navigation
- File
- Notification
- Social
- Toggle

### 1.4 기타 디자인 토큰

**Border/Divider**:
- 주요 구분선: Neutral-80 `#B9B9C3` (Line)
- 테두리: Neutral-40 `#DFDEE3`

**Text Colors**:
- Primary text: Neutral-400 `#615F6D`
- Secondary text: Neutral-200 `#8A8797`
- Black Primary: Neutral-600 `#373435`

**Background**:
- Canvas: Neutral-05 `#F9FAFC`
- Sidebar/Hover: Grey-40 `#F5F5F5` 또는 Neutral-5 `#F7F7F8`

---

## 2. 현재 POS 디자인 토큰

### 색상
```dart
// Primary
Color(0xFF3182F6)        // primary (파란색)
Color(0xFF1A6BE0)        // primaryDark

// Success
Color(0xFF03B26C)        // success (초록)
Color(0xFF028A53)        // successDark

// Error/Warning
Color(0xFFE53935)        // error (빨강)
Color(0xFFFFA726)        // warning (주황)

// Background
Color(0xFFF5F5F7)        // background (라이트 그레이)
Color(0xFFFFFFFF)        // cardWhite
Color(0xFFE8E8EA)        // divider

// Text
Color(0xFF1A1A1A)        // textPrimary
Color(0xFF6B7280)        // textSecondary
Color(0xFFAEB5BC)        // textDisabled
Color(0xFF6B7280)        // iconColor

// Container/Surface
Color(0xFFE8F0FE)        // primaryContainer
Color(0xFFE6FAF2)        // secondaryContainer
Color(0xFFFDEBEB)        // errorContainer
Color(0xFFF0F0F2)        // outlineVariant
```

### Typography
- **폰트 패밀리**: 시스템 기본 폰트 (명시되지 않음)
- Display: 32px/700, 28px/700
- Headline: 24px/700, 20px/600, 18px/600
- Title: 17px/600, 15px/600, 14px/600
- Body: 16px/400, 14px/400, 12px/400
- Label: 14px/500, 13px/500, 12px/500

### UI 컴포넌트
- **Card border radius**: 12px
- **Button border radius**: 12px
- **TextField border radius**: 10px
- **Button padding**: vertical 14px, horizontal 24px
- **Elevation**: 0 (flat design)

---

## 3. 차이점 분석 (Oda Style Guide vs POS)

| 항목 | Oda Style Guide | 현재 POS | 차이 | 적용 가능 여부 |
|------|-----------------|----------|------|----------------|
| **폰트 패밀리** | Noto Sans (명시) | 시스템 기본 폰트 | Oda는 Noto Sans 명시 | ✅ 즉시 적용 가능 |
| **Primary 색상** | Green `#35974F` ~ `#40B65F` | Blue `#3182F6` | 브랜드 컬러가 완전히 다름 (녹색 vs 파란색) | ⚠️ 브랜드 정체성 결정 필요 |
| **Success 색상** | Green-600 `#35974F` | `#03B26C` | 약간 다른 톤 (Oda가 더 어두운 녹색) | ✅ 적용 가능 |
| **Error 색상** | Red-500 `#EF2E2E` | `#E53935` | 매우 유사 (거의 같은 빨강) | ✅ 통합 가능 |
| **Warning 색상** | Orange-500 `#E58435` | `#FFA726` | Oda가 더 어두운 주황색 | ✅ 적용 가능 |
| **Info 색상** | Blue-400 `#2196F3` | 없음 (primary가 blue) | POS에 Info 색상 없음 | ✅ 추가 가능 |
| **텍스트 색상** | Neutral-400 `#615F6D` (primary)<br>Neutral-200 `#8A8797` (secondary) | `#1A1A1A` (primary)<br>`#6B7280` (secondary) | POS가 더 진한 검정 사용 | ⚠️ 가독성 테스트 필요 |
| **배경 색상** | Neutral-05 `#F9FAFC`<br>Grey-40 `#F5F5F5` | `#F5F5F7` | 거의 유사 | ✅ 통합 가능 |
| **Divider** | Neutral-80 `#B9B9C3` | `#E8E8EA` | POS가 더 밝은 회색 | ✅ 적용 가능 |
| **색상 팔레트 구조** | 900~60 단계별 팔레트 (11단계) | 단일 색상 + dark 변형 (2단계) | Oda가 훨씬 세분화됨 | ✅ 적용 가능 (디자인 유연성 향상) |
| **Typography 크기** | H-1: 34px, H-2: 28px | Display: 32px, 28px | 거의 유사 | ✅ 정렬 가능 |
| **Typography weight** | Medium(500), SemiBold(600) 중심 | Regular(400), SemiBold(600), Bold(700) | Oda는 Medium 활용 | ✅ 적용 가능 |
| **Button 텍스트** | Button-M-Regu: 16px/Regular | 16px/600 (SemiBold) | POS가 더 두꺼운 폰트 | ⚠️ 디자인 판단 필요 |
| **Border Radius** | 명시 안 됨 | 12px (card/button), 10px (input) | Oda 가이드에 명시 안 됨 | - |
| **Elevation** | 명시 안 됨 | 0 (flat) | Oda 가이드에 명시 안 됨 | - |

---

## 4. POS에 적용 가능한 항목 (우선순위별)

### 즉시 적용 가능 (코드 변경만)

1. **폰트 패밀리 통일**
   - Noto Sans를 POS에 적용
   - `pubspec.yaml`에 Google Fonts 추가: `google_fonts: ^6.0.0`
   - `AppTheme`에서 `fontFamily: GoogleFonts.notoSans().fontFamily` 적용

2. **색상 팔레트 확장**
   - 현재 단일 색상을 Oda의 900~60 단계 팔레트로 확장
   - `AppTheme`에 색상 클래스 추가 (예: `OdaColors.green600`, `OdaColors.neutral400`)
   - 디자인 유연성 대폭 향상

3. **System Colors 추가**
   - Info 색상 추가: `Color infoColor = Color(0xFF2196F3);`
   - Success를 Green-600으로 변경: `Color(0xFF35974F)`
   - Warning을 Orange-500으로 변경: `Color(0xFFE58435)`

4. **Typography weight 조정**
   - Medium(500) weight 추가 (현재 Regular, SemiBold, Bold만 사용)
   - Oda 가이드에 맞춰 Header에 Medium, Body에 Regular/Medium/SemiBold 혼용

5. **Divider 색상 변경**
   - `divider = Color(0xFFB9B9C3)` (현재 `0xFFE8E8EA`에서 변경)

### 적용 검토 필요 (디자인 판단 필요)

1. **브랜드 Primary 색상 변경**
   - **현재**: Blue `#3182F6` (토스 스타일)
   - **Oda**: Green `#40B65F` (자연/신뢰/성장)
   - **결정 필요**: Odaai POS의 브랜드 정체성이 Oda 브랜드와 동일한가?
   - **영향 범위**: 전체 UI (버튼, 링크, 강조 색상)
   - **권장**: Jin과 디자인 팀에 확인 필요

2. **텍스트 색상 변경**
   - **현재**: `#1A1A1A` (거의 검정)
   - **Oda**: `#615F6D` (Neutral-400, 보라 톤 회색)
   - **고려 사항**: 가독성 테스트 필요 (특히 작은 텍스트)
   - **권장**: A/B 테스트 후 결정

3. **Button 텍스트 weight**
   - **현재**: SemiBold (600)
   - **Oda**: Regular (400) - "Main button" 권장
   - **고려 사항**: POS는 버튼 강조가 중요한 환경 (결제, 주문 등)
   - **권장**: 현재대로 SemiBold 유지 or Oda Medium(500) 절충

4. **배경 색상 미세 조정**
   - **현재**: `#F5F5F7` (약간 보라 톤)
   - **Oda**: `#F9FAFC` (Neutral-05, 더 밝은 블루 톤)
   - **영향**: 전체 앱 느낌 변화
   - **권장**: 디자이너 검토 후 결정

### 적용 불가 (플랫폼 제약)

1. **아이콘 시스템**
   - Oda는 자체 아이콘 세트 사용
   - POS는 Flutter Material Icons 사용 중
   - **제약**: Oda 아이콘 세트가 SVG/Flutter asset으로 제공되지 않는 한 적용 불가
   - **대안**: Material Icons 중 Oda 스타일과 유사한 것 선택

2. **Border Radius / Elevation**
   - Oda 가이드에 명시되지 않음
   - 현재 POS의 12px radius, 0 elevation 유지

---

## 5. 권장 적용 순서

### Phase 1: 기초 토큰 통일 (1주)
1. Noto Sans 폰트 적용
2. 색상 팔레트 확장 (900~60 단계)
3. System Colors 추가 (Info, Success, Warning 업데이트)
4. Typography weight 조정 (Medium 추가)

### Phase 2: 브랜드 결정 (디자인 리뷰)
1. Primary 색상 변경 여부 결정 (Blue → Green?)
2. 텍스트 색상 가독성 테스트
3. Button 스타일 최종 결정

### Phase 3: 세부 조정 (1주)
1. 배경/Divider 색상 미세 조정
2. 전체 화면 일관성 검증
3. QA 및 최종 검수

---

## 6. 코드 적용 예시 (Phase 1)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OdaColors {
  // Green (Primary/Success)
  static const green900 = Color(0xFF153C20);
  static const green800 = Color(0xFF205B2F);
  static const green700 = Color(0xFF2A793F);
  static const green600 = Color(0xFF35974F); // Success
  static const green500 = Color(0xFF40B65F);
  static const green400 = Color(0xFF59C576);
  static const green300 = Color(0xFF77CF8F);
  static const green200 = Color(0xFF95DAA8);
  static const green100 = Color(0xFFB4E4C1);
  static const green80 = Color(0xFFD2EFDA);
  static const green60 = Color(0xFFF0FAF3);

  // Blue (Info)
  static const blue900 = Color(0xFF042C4E);
  static const blue800 = Color(0xFF064374);
  static const blue700 = Color(0xFF08599B);
  static const blue600 = Color(0xFF0A6FC2);
  static const blue500 = Color(0xFF0C85E9);
  static const blue400 = Color(0xFF2196F3); // Info
  static const blue300 = Color(0xFF51ABF6);
  static const blue200 = Color(0xFF77BEF8);
  static const blue100 = Color(0xFF9ED1FA);

  // Red (Danger)
  static const red900 = Color(0xFF720909);
  static const red800 = Color(0xFF980B0B);
  static const red700 = Color(0xFFBE0E0E);
  static const red600 = Color(0xFFE41111);
  static const red500 = Color(0xFFEF2E2E); // Danger
  static const red400 = Color(0xFFF25454);
  static const red300 = Color(0xFFF46A6A);
  static const red200 = Color(0xFFF8A0A0);
  static const red100 = Color(0xFFFBC6C6);

  // Orange (Warning)
  static const orange900 = Color(0xFF6C380E);
  static const orange800 = Color(0xFF904B13);
  static const orange700 = Color(0xFFB55E17);
  static const orange600 = Color(0xFFD9711C);
  static const orange500 = Color(0xFFE58435); // Warning
  static const orange400 = Color(0xFFEA9C5D);
  static const orange300 = Color(0xFFEFB281);
  static const orange200 = Color(0xFFF3C8A5);
  static const orange100 = Color(0xFFF8DEC9);

  // Neutral (Text & Background)
  static const neutral900 = Color(0xFF131316); // 텍스트에서 누락, 추정
  static const neutral800 = Color(0xFF131316);
  static const neutral700 = Color(0xFF27262C);
  static const neutral600 = Color(0xFF373435); // Black Primary
  static const neutral500 = Color(0xFF4E4C57);
  static const neutral400 = Color(0xFF615F6D); // Text Primary
  static const neutral300 = Color(0xFF6E6B7B);
  static const neutral200 = Color(0xFF8A8797); // Text Secondary
  static const neutral100 = Color(0xFF9F9DAA);
  static const neutral80 = Color(0xFFB9B9C3); // Line/Divider
  static const neutral60 = Color(0xFFCAC8D0);
  static const neutral40 = Color(0xFFDFDEE3); // Border
  static const neutral20 = Color(0xFFEBE9F1);
  static const neutral10 = Color(0xFFF3F2F7);
  static const neutral5 = Color(0xFFF7F7F8); // Sidebar/Hover
  static const neutral05 = Color(0xFFF9FAFC); // Canvas

  // Grey
  static const grey900 = Color(0xFF141414);
  static const grey800 = Color(0xFF292929);
  static const grey700 = Color(0xFF3D3D3D);
  static const grey600 = Color(0xFF525252);
  static const grey500 = Color(0xFF666666);
  static const grey400 = Color(0xFF7A7A7A);
  static const grey300 = Color(0xFF8F8F8F);
  static const grey200 = Color(0xFFA3A3A3);
  static const grey100 = Color(0xFFB8B8B8);
  static const grey80 = Color(0xFFC4C4C4);
  static const grey60 = Color(0xFFE0E0E0);
  static const grey40 = Color(0xFFF5F5F5); // Sidebar/Hover

  // Monochrome
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

class AppTheme {
  // System Colors
  static const Color success = OdaColors.green600;
  static const Color info = OdaColors.blue400;
  static const Color danger = OdaColors.red500;
  static const Color warning = OdaColors.orange500;

  // 기존 코드와의 호환을 위한 alias
  static const Color primary = Color(0xFF3182F6); // TODO: OdaColors.green500로 변경 검토
  static const Color error = danger;
  static const Color background = OdaColors.neutral05;
  static const Color cardWhite = OdaColors.white;
  static const Color divider = OdaColors.neutral80;
  static const Color textPrimary = OdaColors.neutral400;
  static const Color textSecondary = OdaColors.neutral200;
  static const Color textDisabled = OdaColors.neutral100;

  static ThemeData get lightTheme {
    final textTheme = TextTheme(
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
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary, height: 16/12),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSans().fontFamily,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        primaryContainer: Color(0xFFE8F0FE),
        onPrimary: Colors.white,
        onPrimaryContainer: primary,
        secondary: success,
        secondaryContainer: OdaColors.green60,
        onSecondary: Colors.white,
        onSecondaryContainer: success,
        error: error,
        onError: Colors.white,
        errorContainer: OdaColors.red100,
        onErrorContainer: error,
        surface: cardWhite,
        onSurface: textPrimary,
        surfaceContainerHighest: background,
        onSurfaceVariant: textSecondary,
        outline: divider,
        outlineVariant: OdaColors.neutral40,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      // ... 나머지 테마 설정 동일
    );
  }
}
```

### pubspec.yaml 추가
```yaml
dependencies:
  google_fonts: ^6.0.0
```

---

## 7. 결론

### 주요 발견

1. **Oda Design Style Guide**는 체계적이고 세분화된 디자인 시스템을 가지고 있음:
   - 11단계 색상 팔레트 (900~60)
   - Noto Sans 기반 명확한 Typography 체계
   - System Colors (Success, Info, Danger, Warning) 명확히 정의

2. **현재 POS**는 토스 스타일을 참고한 심플한 디자인:
   - 단순한 색상 구조 (주색 + dark 변형)
   - Material Design 스타일
   - Flat design (elevation 0)

3. **주요 차이점**:
   - **브랜드 컬러**: Oda는 Green, POS는 Blue
   - **색상 체계**: Oda는 11단계 세분화, POS는 단순 2단계
   - **폰트**: Oda는 Noto Sans 명시, POS는 시스템 폰트
   - **텍스트 색상**: Oda는 보라 톤 회색(Neutral), POS는 순수 회색

### 적용 전략

#### ✅ 즉시 적용 (Phase 1)
- Noto Sans 폰트 적용
- 색상 팔레트 확장 (디자인 유연성 향상)
- System Colors 추가/업데이트
- Typography weight 조정

#### ⚠️ 검토 후 적용 (Phase 2)
- **브랜드 Primary 색상 변경**: Jin과 디자인 팀 확인 필요
- **텍스트 색상**: 가독성 A/B 테스트 필요
- **Button weight**: POS 특성상 현재 유지 권장

#### ❌ 적용 제외
- 아이콘 시스템: Oda 전용 아이콘이 Flutter asset으로 제공되지 않는 한 불가
- Border Radius/Elevation: Oda 가이드에 명시 없음, 현재 유지

### 최종 권장사항

1. **Phase 1 먼저 적용** → 즉시 디자인 일관성 향상
2. **브랜드 컬러는 Jin과 협의** → Odaai POS가 Oda 브랜드의 일부인지 확인
3. **텍스트 색상은 테스트 필수** → 작은 텍스트 가독성 검증
4. **점진적 적용** → Phase별로 나눠 QA 진행

이 분석 리포트를 기반으로 디자인 팀과 논의 후 최종 적용 범위를 결정하시기 바랍니다.