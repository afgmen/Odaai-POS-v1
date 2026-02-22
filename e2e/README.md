# Oda POS — Playwright E2E Tests

## 구조

```
e2e/
├── helpers/
│   └── flutter.ts              # Flutter Web DOM 유틸리티 + loginEmployee()
├── pos_checkout_flow.spec.ts   # POS 플로우 (로그인 전/후) + KDS 네비게이션
├── payment_edge_cases.spec.ts  # 결제 엣지 케이스 (빈 카트, 잔돈, 환불, 재고 등)
├── rbac_settings.spec.ts       # RBAC Settings (Enable RBAC, Security, Role Permissions)
└── README.md
playwright.config.ts            # Playwright 설정
package.json
```

## 실행 방법

### 1. Flutter Production Build (최초 1회)

```bash
cd /Users/macmini/.openclaw/workspace/Odaai-POS-v1
flutter build web --no-pub
```

### 2. E2E 테스트 실행

`playwright.config.ts`의 `webServer` 설정이 자동으로 HTTP 서버를 시작합니다.

```bash
# 전체 실행
npx playwright test

# 특정 파일만
npx playwright test e2e/pos_checkout_flow.spec.ts
npx playwright test e2e/payment_edge_cases.spec.ts

# UI 모드 (인터랙티브)
npx playwright test --ui

# 결과 리포트 보기
npx playwright show-report
```

## 테스트 범위

| 파일 | 테스트 수 | 커버리지 |
|------|-----------|----------|
| `pos_checkout_flow.spec.ts` | 18개 | 앱 로드, 직원 로그인 플로우 (드롭다운 + PIN), POS 메인 화면, 제품 그리드, 카트 조작, 결제 모달, KDS 네비게이션 |
| `payment_edge_cases.spec.ts` | 6개 | 빈 카트 방지, 결제 수단 4개, 현금 잔돈 계산, 환불 화면, 영수증, 재고 |
| `rbac_settings.spec.ts` | 4개 | RBAC 활성화 버튼 (SQL 버그 수정 검증), 성공 다이얼로그, Security Settings 접근, Role Permissions 화면 |
| | **총 28개 (전체 PASS)** | |

### 테스트 그룹

| 그룹 | 인증 필요 | 설명 |
|------|-----------|------|
| `POS Checkout Flow` | ❌ | 로그인 화면 스모크 테스트 |
| `POS Authenticated` | ✅ | POS 메인 기능 (로그인 후) |
| `POS Special Scenarios` | ✅ | QC 크리티컬 엣지 케이스 |
| `KDS Menu Summary Screen` | ✅ | KDS 화면 네비게이션 |
| `Payment Edge Cases` | ✅ | 결제 엣지 케이스 전체 |
| `RBAC Settings` | ✅ | RBAC 활성화 + Security Settings + Role Permissions |

## 로그인 플로우

`loginEmployee()` 헬퍼 (`helpers/flutter.ts`)가 전체 로그인 플로우를 처리합니다:

```
"Select Employee" 버튼 클릭
    → role="menu" 드롭다운 열림
    → role="menuitem" 직원 선택 (기본: 첫 번째 직원)
    → PIN 키패드 화면 (0-9 버튼 + "Login" 버튼)
    → PIN 입력 (기본: "1234" — Administrator)
    → "Login" 클릭
    → POS 메인 화면
```

기본 직원: **Administrator (Manager)**, PIN: **1234**

## Flutter Web E2E 기술 노트

### CanvasKit 렌더러
Flutter 3.41 web은 **CanvasKit (dart2js)** 렌더러를 사용합니다.
UI는 WebGL canvas에 직접 렌더링되므로 DOM에 텍스트가 없습니다.
Playwright 테스트는 **Production build** (`flutter build web`)에서만 작동합니다.
개발 서버(`flutter run -d web-server`)는 DDC 모듈 로딩 방식으로 인해 Playwright와 호환되지 않습니다.

### Accessibility 트리 활성화
Flutter는 `<flt-semantics>` 노드로 접근성 트리를 노출합니다.
이 트리는 첫 사용자 상호작용 후에만 빌드됩니다.

- `enableA11y()` 헬퍼가 `flt-semantics-placeholder`에 JavaScript PointerEvent를 발송합니다.
- `flt-semantics-placeholder`는 뷰포트 밖에 있어 일반 Playwright `.click()`이 실패합니다.
- `page.evaluate()`로 직접 이벤트 발송하여 해결합니다.

### DOM 구조 확인
앱 로드 후 브라우저 DevTools에서:
```javascript
document.querySelectorAll('flt-semantics').length  // 0이면 a11y 비활성
document.querySelector('flt-semantics-placeholder').click()  // 활성화
document.querySelectorAll('flt-semantics')  // 이후 노드 목록 확인
```

### 중요: flt-semantics 클릭 시 주의사항
- `role="button"`이 없는 `flt-semantics` 노드를 `.click()`하면 `flutter-view`가 포인터 이벤트를 가로챌 수 있습니다.
- KDS 모드 카드 등 클릭 가능한 카드는 반드시 `flt-semantics[role="button"]` 셀렉터를 사용하세요.

### headless: false
Flutter CanvasKit은 WebGL context가 필요합니다.
`headless: false`로 실제 브라우저 창을 열어 GPU 렌더링을 활성화합니다.

## CI 연동

CI 환경에서는 production build를 먼저 실행한 후 테스트합니다:

```yaml
- run: flutter build web --no-pub
- run: npx playwright test
```

`playwright.config.ts`의 `webServer` 설정이 자동으로 `python3 -m http.server 8080 --directory build/web`을 실행합니다.
