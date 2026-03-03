# Odaai 브랜드 디자인 통일성 분석 리포트

**작성일**: 2026-02-28  
**분석 대상**: Odaai POS (Flutter), Odaai Approval (Next.js), Odaai 웹사이트

---

## Executive Summary

Odaai의 3개 제품(POS, Approval, 웹사이트)을 분석한 결과, **기본적인 브랜드 컬러는 공통적으로 블루 계열을 사용**하고 있으나, **구체적인 디자인 토큰(색상 코드, 타이포그래피, spacing 등)에서 불일치**가 발견되었습니다.

**핵심 발견사항**:
- Primary 컬러가 제품마다 다름 (POS: #3182F6, Approval: #2563eb)
- Border radius 패턴 차이 (POS: 12px 주력, Approval: Tailwind 기본값 혼용)
- Typography 체계 부재 (폰트 패밀리 명시 없음)
- 아이콘 시스템 불일치 (POS: Material Icons, Approval: Lucide)

---

## 1. 제품별 디자인 토큰 분석

### 1.1 Odaai POS (Flutter 앱)

**위치**: `/Users/macmini/.openclaw/workspace/Odaai-POS-v1/lib/core/theme/app_theme.dart`

#### Colors

| 역할 | 컬러 코드 | 비고 |
|------|-----------|------|
| Primary | `#3182F6` | 메인 파란색 |
| Primary Dark | `#1A6BE0` | Hover/Active 상태 |
| Success | `#03B26C` | 초록 |
| Success Dark | `#028A53` | |
| Error | `#E53935` | 빨강 |
| Warning | `#FFA726` | 주황 |
| Background | `#F5F5F7` | 라이트 그레이 |
| Card White | `#FFFFFF` | 카드 배경 |
| Divider | `#E8E8EA` | 구분선 |
| Text Primary | `#1A1A1A` | 본문 텍스트 |
| Text Secondary | `#6B7280` | 세컨더리 텍스트 |
| Text Disabled | `#AEB5BC` | 비활성 텍스트 |
| Icon Color | `#6B7280` | 아이콘 |

#### Typography

| 스타일 | 크기 | Weight | 용도 |
|--------|------|--------|------|
| Display Large | 32px | 700 | 최상위 제목 |
| Display Medium | 28px | 700 | |
| Headline Large | 24px | 700 | |
| Headline Medium | 20px | 600 | |
| Headline Small | 18px | 600 | |
| Title Large | 17px | 600 | |
| Title Medium | 15px | 600 | |
| Title Small | 14px | 600 | |
| Body Large | 16px | 400 | 본문 |
| Body Medium | 14px | 400 | 본문 |
| Body Small | 12px | 400 | 작은 텍스트 |
| Label Large | 14px | 500 | |
| Label Medium | 13px | 500 | |
| Label Small | 12px | 500 | |

**폰트 패밀리**: 명시되지 않음 (Flutter 기본 폰트 사용 추정)

#### Border Radius

| 요소 | Radius |
|------|--------|
| Card | 12px |
| Button (Elevated/Outlined) | 12px |
| TextField | 10px |

#### Shadows / Elevation

- **Card**: elevation: 0, border 1px solid divider
- **ElevatedButton**: elevation: 0 (플랫 디자인)
- 기타 컴포넌트: 대부분 elevation: 0 사용 (토스 POS 스타일 참고)

#### Icons

- **시스템**: Material Icons (`Icons.`)
- 예시: `Icons.approval`, `Icons.dashboard`, `Icons.calendar_today`

---

### 1.2 Odaai Approval (Next.js 웹)

**위치**: `/Users/macmini/openclaw-workspaces/mama/temp/odaai-v2/odaai-approval/frontend/src/app/globals.css`

#### Colors (CSS Variables)

| 역할 | 컬러 코드 | 비고 |
|------|-----------|------|
| Primary | `#2563eb` | Tailwind blue-600 |
| Primary Dark | `#1d4ed8` | Tailwind blue-700 |
| Primary Light | `#93c5fd` | Tailwind blue-300 |
| Sidebar | `#1e293b` | Tailwind slate-800 |
| Sidebar Light | `#334155` | Tailwind slate-700 |
| Sidebar Lighter | `#475569` | Tailwind slate-600 |
| Sidebar BG | `#f8fafc` | Tailwind slate-50 |
| Status Approved | `#10b981` | Tailwind emerald-500 |
| Status Rejected | `#ef4444` | Tailwind red-500 |
| Status Pending | `#f59e0b` | Tailwind amber-500 |
| Status In Progress | `#3b82f6` | Tailwind blue-500 |

**배경**: `#F9FAFB` (Tailwind gray-50)  
**텍스트**: `#1F2937` (Tailwind gray-800)  
**Border**: Tailwind gray-200

#### Typography

**폰트 패밀리**: 명시되지 않음 (시스템 폰트 사용 추정 - `font-sans`)

| 스타일 | Tailwind Class | 실제 크기 | Weight |
|--------|----------------|-----------|--------|
| h1 | text-3xl | 30px | 700 |
| h2 | text-2xl | 24px | 700 |
| h3 | text-xl | 20px | 600 |
| h4 | text-lg | 18px | 600 |
| h5 | text-base | 16px | 600 |
| h6 | text-sm | 14px | 600 |
| Body | text-gray-700 | 기본 | 400 |

#### Border Radius

| 요소 | CSS Variable | 값 |
|------|--------------|-----|
| sm | --radius-sm | 0.375rem (6px) |
| md | --radius-md | 0.5rem (8px) |
| lg | --radius-lg | 0.75rem (12px) |
| xl | --radius-xl | 1rem (16px) |

**실제 사용**:
- Button: `rounded-lg` (12px)
- Card: `rounded-lg` (12px)
- Modal: `rounded-lg` (12px)
- Input: `rounded-lg` (12px)

#### Shadows

| 크기 | CSS Variable | 값 |
|------|--------------|-----|
| sm | --shadow-sm | 0 1px 2px 0 rgba(0,0,0,0.05) |
| md | --shadow-md | 0 4px 6px -1px rgba(0,0,0,0.1) |
| lg | --shadow-lg | 0 10px 15px -3px rgba(0,0,0,0.1) |

**실제 사용**: Card, Modal에 shadow-md/lg 사용

#### Buttons

| 타입 | 스타일 |
|------|--------|
| Primary | bg-blue-600, hover:bg-blue-700, text-white, rounded-lg, shadow-md |
| Secondary | bg-gray-100, hover:bg-gray-200, text-gray-900, rounded-lg |
| Outline | border-2 border-gray-300, hover:bg-gray-50, rounded-lg |
| Danger | bg-red-600, hover:bg-red-700, text-white |

#### Icons

- **시스템**: Lucide React
- 예시: `Menu`, `X`, `LogOut`, `Bell`, `Settings`, `Home`, `ShoppingCart`, `CheckCircle`, `LayoutGrid`

---

### 1.3 Odaai 웹사이트 (https://odaai.com)

**상태**: 웹사이트 직접 접근 실패 (web_fetch 에러)  
**분석 방법**: 코드 기반 분석 불가, 추후 수동 확인 필요

**추정**:
- POS/Approval과 유사한 블루 계열 Primary 컬러 사용 가능성
- 마케팅 사이트 특성상 더 다양한 색상 팔레트 사용 가능성
- 추가 분석 필요

---

## 2. 제품 간 일치/불일치 비교

### 2.1 Primary Color 불일치 ⚠️

| 제품 | Primary Color | Hex 차이 |
|------|---------------|----------|
| **POS** | `#3182F6` | 밝은 파란색 |
| **Approval** | `#2563eb` | 더 진한 파란색 |
| **차이** | △ | **명백한 불일치** |

**영향도**: **높음** - 브랜드 일관성의 핵심 요소

### 2.2 Secondary/Status Colors 부분 일치 ⚠️

| 역할 | POS | Approval | 일치 여부 |
|------|-----|----------|-----------|
| Success | `#03B26C` | `#10b981` | ❌ 불일치 |
| Error | `#E53935` | `#ef4444` | ❌ 불일치 |
| Warning | `#FFA726` | `#f59e0b` | ❌ 불일치 |

**분석**: Approval은 Tailwind 기본 팔레트를 사용하고, POS는 커스텀 컬러 사용

### 2.3 Typography 불일치 ⚠️

| 항목 | POS | Approval | 일치 여부 |
|------|-----|----------|-----------|
| Font Family | 명시 없음 | 명시 없음 (`font-sans`) | ⚠️ 기본 폰트 의존 |
| Heading Sizes | Material 3 스케일 | Tailwind 스케일 | ❌ 체계 다름 |
| Body 기본 | 16px/14px | Tailwind 기본 | △ 유사하나 명시적 통일 없음 |

**문제점**: 명시적인 폰트 패밀리가 없어 플랫폼/브라우저마다 다르게 렌더링될 가능성

### 2.4 Border Radius 부분 일치 ✅

| 요소 | POS | Approval | 일치 여부 |
|------|-----|----------|-----------|
| Card/Button | 12px | rounded-lg (12px) | ✅ 일치 |
| TextField | 10px | rounded-lg (12px) | △ 근소한 차이 |

**평가**: 주요 요소는 12px로 일치, 세부 요소에서 차이

### 2.5 Shadow/Elevation 불일치 ⚠️

| 제품 | 전략 | 비고 |
|------|------|------|
| POS | Elevation: 0, Border 강조 | 플랫 디자인 |
| Approval | Shadow 사용 (sm/md/lg) | 입체감 강조 |

**차이**: 디자인 철학 자체가 다름 (Flat vs Shadow)

### 2.6 Icon System 불일치 ❌

| 제품 | 아이콘 시스템 | 비고 |
|------|---------------|------|
| POS | Material Icons | Flutter 기본 |
| Approval | Lucide React | 웹 전용 라이브러리 |

**문제점**: 
- 동일한 기능(예: "홈", "설정")에 다른 아이콘 사용 가능성
- 시각적 일관성 저해

---

## 3. 브랜드 통일성을 위한 작업 제안 (우선순위별)

### 🔴 **우선순위 1: 브랜드 컬러 통일 (필수)**

**문제**: Primary 컬러가 제품마다 다름  
**영향도**: 매우 높음 (브랜드 정체성 핵심)

**제안**:
1. **Brand Primary Color 결정**
   - Option A: POS의 `#3182F6` 채택 (밝고 친근함)
   - Option B: Approval의 `#2563eb` 채택 (전문적이고 안정적)
   - Option C: 새로운 컬러 정의 (브랜드 재정립 기회)

2. **Color Palette 문서화**
   ```
   // 예시: Odaai Brand Colors
   Primary: #3182F6
   Primary Dark: #1A6BE0
   Success: #10b981
   Error: #ef4444
   Warning: #f59e0b
   ```

3. **적용**:
   - POS: `app_theme.dart` 업데이트
   - Approval: `globals.css` CSS variables 업데이트
   - 웹사이트: 스타일 시스템 확인 후 적용

**예상 작업 기간**: 1-2일  
**리스크**: 낮음 (코드 변경 범위 명확)

---

### 🔴 **우선순위 2: Typography 시스템 정의 (필수)**

**문제**: 폰트 패밀리 명시 없음, 타이포그래피 스케일 불일치

**제안**:
1. **Brand Font 선정**
   - Option A: Inter (웹/앱 모두 지원, 가독성 우수)
   - Option B: Pretendard (한글 최적화, 무료)
   - Option C: Noto Sans KR (Google Fonts, 안정적)

2. **Typography Scale 통일**
   ```
   Display: 32px / 700
   H1: 28px / 700
   H2: 24px / 700
   H3: 20px / 600
   H4: 18px / 600
   Body Large: 16px / 400
   Body: 14px / 400
   Caption: 12px / 400
   ```

3. **적용**:
   - POS: `app_theme.dart`의 `textTheme`에 fontFamily 추가
   - Approval: `globals.css` 또는 `tailwind.config.js`에 fontFamily 정의
   - 웹폰트 로딩 전략 수립 (FOIT/FOUT 방지)

**예상 작업 기간**: 2-3일  
**리스크**: 중간 (라이선스 확인, 웹폰트 로딩 최적화 필요)

---

### 🟡 **우선순위 3: Status Color 통일 (권장)**

**문제**: Success/Error/Warning 컬러가 제품마다 다름

**제안**:
1. **Tailwind 기본 팔레트 채택** (Approval 기준)
   - Success: `#10b981` (Emerald-500)
   - Error: `#ef4444` (Red-500)
   - Warning: `#f59e0b` (Amber-500)

   **장점**: Tailwind는 접근성 고려한 색상, 웹 생태계 표준

2. **POS 업데이트**:
   ```dart
   static const Color success = Color(0xFF10B981);
   static const Color error = Color(0xFFEF4444);
   static const Color warning = Color(0xFFF59E0B);
   ```

**예상 작업 기간**: 1일  
**리스크**: 낮음

---

### 🟡 **우선순위 4: Shadow/Elevation 전략 통일 (권장)**

**문제**: POS는 플랫 디자인, Approval은 그림자 사용

**제안**:
1. **하이브리드 접근** (추천)
   - 기본: Flat (elevation: 0, border 사용)
   - 강조: Subtle shadow (hover/active 상태)
   
   ```css
   /* Approval 예시 */
   .card {
     border: 1px solid #E8E8EA;
     box-shadow: none;
   }
   
   .card:hover {
     box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
   }
   ```

2. **POS는 현재 유지, Approval만 조정**
   - POS는 Material 3 가이드 따르는 중이므로 큰 변경 불필요
   - Approval의 shadow를 더 subtle하게 조정

**예상 작업 기간**: 1-2일  
**리스크**: 중간 (디자인 의사결정 필요)

---

### 🟢 **우선순위 5: Border Radius 미세 조정 (선택)**

**문제**: POS TextField는 10px, Approval은 12px

**제안**:
1. **12px로 통일** (rounded-lg 표준)
   - POS: TextField border radius를 12px로 변경
   - 큰 변화 없으나 일관성 확보

**예상 작업 기간**: 1시간  
**리스크**: 매우 낮음

---

### 🟢 **우선순위 6: Icon System 검토 (장기)**

**문제**: POS는 Material Icons, Approval은 Lucide

**현실적 제약**:
- Flutter는 Material Icons가 기본
- Lucide는 React/Vue 등 웹 전용
- 완전 통일은 비현실적

**제안**:
1. **Icon Mapping Table 작성**
   - 주요 기능별 아이콘 매핑 (예: 홈, 설정, 알림 등)
   - 시각적으로 유사한 아이콘 선택 가이드
   
   | 기능 | Material (POS) | Lucide (Approval) |
   |------|----------------|-------------------|
   | Home | Icons.home | Home |
   | Settings | Icons.settings | Settings |
   | Logout | Icons.logout | LogOut |

2. **장기 전략**: 
   - Custom Icon Set 제작 (SVG 기반, 플랫폼 무관)
   - 비용과 시간이 많이 들어 현재는 비권장

**예상 작업 기간**: 1일 (매핑 테이블만)  
**리스크**: 낮음

---

## 4. Design Token 문서 제안

위 작업을 진행하려면 **단일 진실 공급원(Single Source of Truth)**이 필요합니다.

### 제안: `odaai-design-tokens.json` 생성

```json
{
  "version": "1.0.0",
  "colors": {
    "primary": "#3182F6",
    "primaryDark": "#1A6BE0",
    "success": "#10b981",
    "error": "#ef4444",
    "warning": "#f59e0b",
    "background": "#F5F5F7",
    "surface": "#FFFFFF",
    "textPrimary": "#1A1A1A",
    "textSecondary": "#6B7280",
    "textDisabled": "#AEB5BC",
    "divider": "#E8E8EA"
  },
  "typography": {
    "fontFamily": {
      "primary": "Pretendard, -apple-system, sans-serif"
    },
    "scale": {
      "display": { "size": "32px", "weight": "700" },
      "h1": { "size": "28px", "weight": "700" },
      "h2": { "size": "24px", "weight": "700" },
      "h3": { "size": "20px", "weight": "600" },
      "body": { "size": "14px", "weight": "400" },
      "caption": { "size": "12px", "weight": "400" }
    }
  },
  "spacing": {
    "xs": "4px",
    "sm": "8px",
    "md": "12px",
    "lg": "16px",
    "xl": "24px",
    "2xl": "32px"
  },
  "borderRadius": {
    "sm": "6px",
    "md": "8px",
    "lg": "12px",
    "xl": "16px"
  },
  "shadows": {
    "none": "none",
    "sm": "0 1px 2px 0 rgba(0,0,0,0.05)",
    "md": "0 4px 6px -1px rgba(0,0,0,0.1)",
    "lg": "0 10px 15px -3px rgba(0,0,0,0.1)"
  }
}
```

**활용**:
1. **POS**: Dart 코드 생성 스크립트로 `app_theme.dart` 자동 생성
2. **Approval**: Tailwind config에서 import
3. **웹사이트**: CSS variables로 변환

**도구**: Style Dictionary (Token 변환 자동화)

---

## 5. 실행 로드맵

### Phase 1: 즉시 실행 (1주)
- [ ] Primary Color 결정 (팀 미팅)
- [ ] Brand Font 선정
- [ ] `odaai-design-tokens.json` 초안 작성
- [ ] POS `app_theme.dart` 업데이트
- [ ] Approval `globals.css` 업데이트

### Phase 2: 단기 (2-3주)
- [ ] Status Color 통일
- [ ] Border Radius 통일
- [ ] Shadow 전략 조정
- [ ] 웹사이트 스타일 확인 및 적용

### Phase 3: 중기 (1-2개월)
- [ ] Icon Mapping Table 작성
- [ ] Typography 웹폰트 최적화
- [ ] Design Token 자동화 스크립트 (Style Dictionary)
- [ ] QA: 모든 제품에서 디자인 일관성 검증

### Phase 4: 장기 (3개월+)
- [ ] Custom Icon Set 검토
- [ ] Component Library 통합 (Storybook 등)
- [ ] Design System 문서화 사이트

---

## 6. 결론

Odaai의 3개 제품은 **블루 계열 Primary Color**와 **12px Border Radius** 등 일부 공통점이 있으나, **구체적인 디자인 토큰 수준에서 불일치**가 명확합니다.

**핵심 권장사항**:
1. **즉시**: Primary Color 통일 (브랜드 정체성 핵심)
2. **단기**: Typography 시스템 정의 (가독성과 일관성)
3. **중기**: Design Token 문서화 및 자동화

이 작업을 통해 Odaai는 **통일된 브랜드 경험**을 제공하고, **개발 효율성**을 높일 수 있습니다.

---

**Next Steps**:
1. 본 리포트를 팀과 공유
2. Primary Color 및 Font 선정 회의
3. Design Token 초안 작성 및 검토
4. Phase 1 작업 시작 (1주 목표)

**작성자**: Mama (AI PM)  
**문의**: Jin 형님
