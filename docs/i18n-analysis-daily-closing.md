# 일일 마감 리포트 - 하드코딩된 한국어 분석

**분석 날짜**: 2026-02-10
**대상 기능**: Daily Closing Report (일일 마감 리포트)
**i18n 시스템**: Flutter `flutter_localizations` + ARB 파일 (app_ko.arb, app_en.arb, app_vi.arb)

---

## 📊 분석 요약

### 발견된 하드코딩 현황

| 파일 | 하드코딩 문자열 수 | 심각도 |
|------|-------------------|--------|
| `daily_closing_screen.dart` | 15+ | High |
| `closing_history_screen.dart` | 12+ | High |
| `closing_summary_card.dart` | 6 | Medium |
| `payment_breakdown_widget.dart` | 5 | Medium |
| `cash_count_dialog.dart` | 8 | Medium |
| `closing_service.dart` | 5 | High |
| `pdf_export_service.dart` | 20+ | High |

**총계**: **70+ 하드코딩된 한국어 문자열**

---

## 🔴 Critical - 반드시 수정 필요

### 1. `daily_closing_screen.dart` (15개)

| 라인 | 하드코딩된 문자열 | 제안 키 |
|------|-------------------|---------|
| 155 | `'일일 마감'` | `dailyClosing` |
| 180 | `'마감 날짜'` | `closingDate` |
| 77 | `'마감 리포트를 PDF로 저장하시겠습니까?'` | `savePdfConfirm` |
| 294 | `'데이터를 불러오는 중 문제가 발생했습니다.'` | `errorLoadingData` |
| 299 | `'잠시 후 다시 시도해주세요.'` | `retryLater` |
| 336 | `'예상 현금'` | `expectedCash` |
| 344 | `'실제 현금'` | `actualCash` |
| 357 | `'실제 현금 입력'` / `'실제 현금 수정'` | `enterActualCash` / `editActualCash` |
| 376 | `'차액'` | `difference` |
| 404 | `'특이사항'` | `notes` |
| 416 | `'특이사항을 입력하세요 (선택사항)'` | `notesPlaceholder` |
| 450 | `'마감 완료'` | `completeClosing` |
| 119 | `'마감 데이터를 찾을 수 없습니다.'` | `closingDataNotFound` |

### 2. `closing_history_screen.dart` (12개)

| 라인 | 하드코딩된 문자열 | 제안 키 |
|------|-------------------|---------|
| 16 | `'마감 이력'` | `closingHistory` |
| 46 | `'마감 이력이 없습니다.'` | `noClosingHistory` |
| 72 | `'마감 이력을 불러올 수 없습니다.'` | `errorLoadingHistory` |
| 77 | `'잠시 후 다시 시도해주세요.'` | `retryLater` |
| 271 | `'마감 상세'` | `closingDetail` |
| 274 | `'마감 시각'` | `closingTime` |
| 275 | `'담당자'` | `handler` |
| 278 | `'총 거래 건수'` / `'총 매출'` / `'평균 거래액'` | `totalTransactions` / `totalSales` / `avgTransaction` |
| 282 | `'현금'` / `'카드'` / `'QR'` / `'계좌이체'` | `cash` / `card` / `qr` / `transfer` |
| 287 | `'총 세금'` / `'총 할인'` | `totalTax` / `totalDiscount` |
| 290 | `'예상 현금'` / `'실제 현금'` / `'차액'` | `expectedCash` / `actualCash` / `difference` |

### 3. `closing_summary_card.dart` (6개)

| 라인 | 하드코딩된 문자열 | 제안 키 |
|------|-------------------|---------|
| 21 | `'매출 요약'` | `salesSummary` |
| 26 | `'총 거래 건수'` | `totalTransactions` |
| 31 | `'총 매출'` | `totalSales` |
| 36 | `'평균 거래 금액'` | `avgTransactionAmount` |
| 43 | `'총 세금'` | `totalTax` |
| 48 | `'총 할인'` | `totalDiscount` |

### 4. `payment_breakdown_widget.dart` (5개)

| 라인 | 하드코딩된 문자열 | 제안 키 |
|------|-------------------|---------|
| 48 | `'결제 수단별 매출'` | `salesByPaymentMethod` |
| 21 | `'현금'` | `paymentCash` |
| 26 | `'카드'` | `paymentCard` |
| 31 | `'QR 결제'` | `paymentQR` |
| 36 | `'계좌이체'` | `paymentTransfer` |

### 5. `cash_count_dialog.dart` (8개)

| 라인 | 하드코딩된 문자열 | 제안 키 |
|------|-------------------|---------|
| 42 | `'시재 확인'` | `cashVerification` |
| 52 | `'예상 현금'` | `expectedCash` |
| 68 | `'실제 현금 입력'` | `enterActualCash` |
| 73 | `'실제 현금 금액을 입력하세요'` | `enterActualCashPlaceholder` |
| 74 | `'원'` | `currencyUnit` |
| 128 | `'차액'` | `difference` |
| 161 | `'허용 범위(±1,000원)를 초과했습니다.'` | `cashDifferenceExceeded` |
| 182 | `'취소'` / `'확인'` | `cancel` / `confirm` (이미 존재) |

### 6. `closing_service.dart` (5개)

| 라인 | 하드코딩된 문자열 | 제안 키 |
|------|-------------------|---------|
| 26 | `'이미 마감된 날짜입니다.'` | `alreadyClosed` |
| 36 | `'미래 날짜는 마감할 수 없습니다.'` | `cannotCloseFutureDate` |
| 45 | `'해당 날짜에 판매 내역이 없습니다.'` | `noSalesData` |
| 75 | `'로그인이 필요합니다.'` | `loginRequired` |
| 92 | `'마감이 완료되었습니다.'` | `closingCompleted` |
| 98 | `'마감 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'` | `closingError` |

### 7. `pdf_export_service.dart` (20+개)

| 라인 | 하드코딩된 문자열 | 제안 키 |
|------|-------------------|---------|
| 39 | `'일일 마감 리포트'` | `dailyClosingReport` |
| 94 | `'마감 날짜'` / `'마감 시각'` / `'마감 담당'` | `closingDate` / `closingTime` / `closingHandler` |
| 95 | `'알 수 없음'` | `unknown` |
| 113 | `'매출 요약'` | `salesSummary` |
| 119 | `'총 거래 건수'` / `'총 매출'` / `'평균 거래 금액'` / `'총 세금'` / `'총 할인'` | (위와 동일) |
| 120 | `'건'` | `transactionUnit` |
| 138 | `'결제 수단별 매출'` | `salesByPaymentMethod` |
| 148 | `'현금'` / `'카드'` / `'QR 결제'` / `'계좌이체'` | (위와 동일) |
| 168 | `'시재 관리'` | `cashManagement` |
| 176 | `'예상 현금'` / `'실제 현금'` / `'차액'` | (위와 동일) |
| 198 | `'특이사항'` | `notes` |
| 217 | `'마감 담당자:'` / `'확인자:'` / `'서명:'` | `closingHandler` / `verifier` / `signature` |

---

## 🟡 Medium - 권장 수정

### 통화 형식 하드코딩

모든 파일에서 다음 형식이 반복됨:
```dart
NumberFormat.currency(locale: 'ko_KR', symbol: '₩')
```

**문제점**:
- 로케일이 하드코딩됨
- 다국어 지원 시 동적 변경 불가

**해결책**:
```dart
// constants/closing_constants.dart
static String getCurrencyLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ko' ? 'ko_KR' : 'en_US';
}

static String getCurrencySymbol(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ko' ? '₩' : '\$';
}
```

---

## 📝 제안 ARB 파일 추가 내용

### `app_ko.arb`에 추가할 키 (70개)

```json
{
  "dailyClosing": "일일 마감",
  "dailyClosingReport": "일일 마감 리포트",
  "closingDate": "마감 날짜",
  "closingTime": "마감 시각",
  "closingHistory": "마감 이력",
  "closingDetail": "마감 상세",
  "closingHandler": "마감 담당",
  "closingCompleted": "마감이 완료되었습니다.",
  "completeClosing": "마감 완료",

  "salesSummary": "매출 요약",
  "totalSales": "총 매출",
  "totalTransactions": "총 거래 건수",
  "avgTransaction": "평균 거래액",
  "avgTransactionAmount": "평균 거래 금액",
  "totalTax": "총 세금",
  "totalDiscount": "총 할인",
  "transactionUnit": "건",

  "salesByPaymentMethod": "결제 수단별 매출",
  "paymentCash": "현금",
  "paymentCard": "카드",
  "paymentQR": "QR 결제",
  "paymentTransfer": "계좌이체",

  "cashManagement": "시재 관리",
  "cashVerification": "시재 확인",
  "expectedCash": "예상 현금",
  "actualCash": "실제 현금",
  "difference": "차액",
  "enterActualCash": "실제 현금 입력",
  "editActualCash": "실제 현금 수정",
  "enterActualCashPlaceholder": "실제 현금 금액을 입력하세요",
  "cashDifferenceExceeded": "허용 범위(±1,000원)를 초과했습니다.",

  "notes": "특이사항",
  "notesPlaceholder": "특이사항을 입력하세요 (선택사항)",

  "handler": "담당자",
  "verifier": "확인자",
  "signature": "서명",
  "unknown": "알 수 없음",
  "currencyUnit": "원",

  "savePdfConfirm": "마감 리포트를 PDF로 저장하시겠습니까?",

  "errorLoadingData": "데이터를 불러오는 중 문제가 발생했습니다.",
  "errorLoadingHistory": "마감 이력을 불러올 수 없습니다.",
  "retryLater": "잠시 후 다시 시도해주세요.",
  "closingDataNotFound": "마감 데이터를 찾을 수 없습니다.",
  "noClosingHistory": "마감 이력이 없습니다.",

  "alreadyClosed": "이미 마감된 날짜입니다.",
  "cannotCloseFutureDate": "미래 날짜는 마감할 수 없습니다.",
  "noSalesData": "해당 날짜에 판매 내역이 없습니다.",
  "loginRequired": "로그인이 필요합니다.",
  "closingError": "마감 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
}
```

### `app_en.arb`에 추가할 키

```json
{
  "dailyClosing": "Daily Closing",
  "dailyClosingReport": "Daily Closing Report",
  "closingDate": "Closing Date",
  "closingTime": "Closing Time",
  "closingHistory": "Closing History",
  "closingDetail": "Closing Detail",
  "closingHandler": "Handler",
  "closingCompleted": "Closing completed successfully.",
  "completeClosing": "Complete Closing",

  "salesSummary": "Sales Summary",
  "totalSales": "Total Sales",
  "totalTransactions": "Total Transactions",
  "avgTransaction": "Avg Transaction",
  "avgTransactionAmount": "Avg Transaction Amount",
  "totalTax": "Total Tax",
  "totalDiscount": "Total Discount",
  "transactionUnit": "items",

  "salesByPaymentMethod": "Sales by Payment Method",
  "paymentCash": "Cash",
  "paymentCard": "Card",
  "paymentQR": "QR Payment",
  "paymentTransfer": "Bank Transfer",

  "cashManagement": "Cash Management",
  "cashVerification": "Cash Verification",
  "expectedCash": "Expected Cash",
  "actualCash": "Actual Cash",
  "difference": "Difference",
  "enterActualCash": "Enter Actual Cash",
  "editActualCash": "Edit Actual Cash",
  "enterActualCashPlaceholder": "Enter actual cash amount",
  "cashDifferenceExceeded": "Exceeds acceptable range (±1,000)",

  "notes": "Notes",
  "notesPlaceholder": "Enter notes (optional)",

  "handler": "Handler",
  "verifier": "Verifier",
  "signature": "Signature",
  "unknown": "Unknown",
  "currencyUnit": "KRW",

  "savePdfConfirm": "Save closing report as PDF?",

  "errorLoadingData": "Error loading data.",
  "errorLoadingHistory": "Cannot load closing history.",
  "retryLater": "Please try again later.",
  "closingDataNotFound": "Closing data not found.",
  "noClosingHistory": "No closing history available.",

  "alreadyClosed": "This date is already closed.",
  "cannotCloseFutureDate": "Cannot close future dates.",
  "noSalesData": "No sales data for this date.",
  "loginRequired": "Login required.",
  "closingError": "Error occurred during closing. Please try again later."
}
```

---

## 🔧 수정 방법

### 1. ARB 파일에 키 추가

위의 키들을 `lib/l10n/app_ko.arb`, `app_en.arb`, `app_vi.arb`에 추가

### 2. 코드 생성

```bash
flutter gen-l10n
```

### 3. 하드코딩된 문자열 교체

**Before:**
```dart
const Text('일일 마감')
```

**After:**
```dart
Text(AppLocalizations.of(context)!.dailyClosing)
```

또는 간단하게:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// 위젯 내부에서
final l10n = AppLocalizations.of(context)!;

Text(l10n.dailyClosing)
Text(l10n.totalSales)
```

---

## 📊 우선순위

### High Priority (즉시 수정)
1. **에러 메시지** - 사용자에게 보이는 모든 에러 메시지
2. **UI 라벨** - 화면 제목, 버튼 텍스트
3. **비즈니스 로직 메시지** - ClosingService의 검증 메시지

### Medium Priority
4. **PDF 내용** - PDF 리포트의 모든 텍스트
5. **위젯 라벨** - 카드, 다이얼로그 내부 텍스트

### Low Priority
6. **통화 형식** - 로케일 기반 동적 포맷팅

---

## 💡 추가 권장사항

### 1. 날짜/시간 형식도 하드코딩됨

```dart
// 현재 (하드코딩)
DateFormat('yyyy-MM-dd')
DateFormat('HH:mm')

// 권장
DateFormat.yMd(Localizations.localeOf(context).languageCode)
DateFormat.Hm(Localizations.localeOf(context).languageCode)
```

### 2. 숫자 형식도 로케일 기반으로 변경

```dart
// 현재
NumberFormat.currency(locale: 'ko_KR', symbol: '₩')

// 권장
NumberFormat.currency(
  locale: Localizations.localeOf(context).toString(),
  symbol: l10n.currencySymbol,
)
```

### 3. 플러럴(복수형) 처리

```dart
// ARB 파일
"transactionCount": "{count}건",
"@transactionCount": {
  "placeholders": {
    "count": {
      "type": "int"
    }
  }
}

// 코드
l10n.transactionCount(closing.totalTransactions)
```

---

## 🎯 예상 작업 시간

| 작업 | 예상 시간 |
|------|-----------|
| ARB 파일에 키 추가 (ko, en, vi) | 1시간 |
| 코드 생성 (`flutter gen-l10n`) | 5분 |
| 화면 파일 수정 (7개 파일) | 2-3시간 |
| 테스트 (언어 전환 확인) | 30분 |
| **총계** | **약 4시간** |

---

## 📋 체크리스트

- [ ] ARB 파일에 모든 키 추가 (ko, en, vi)
- [ ] `flutter gen-l10n` 실행
- [ ] `daily_closing_screen.dart` 수정
- [ ] `closing_history_screen.dart` 수정
- [ ] `closing_summary_card.dart` 수정
- [ ] `payment_breakdown_widget.dart` 수정
- [ ] `cash_count_dialog.dart` 수정
- [ ] `closing_service.dart` 수정
- [ ] `pdf_export_service.dart` 수정
- [ ] 통화/날짜 형식 로케일 기반으로 변경
- [ ] 언어 전환 테스트 (한국어 ↔ 영어 ↔ 베트남어)

---

**작성자**: Code Analyzer
**분석 대상**: Daily Closing Report Feature
**권장 조치**: High Priority 항목부터 단계적 적용
