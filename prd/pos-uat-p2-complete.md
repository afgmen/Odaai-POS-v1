# POS UAT Phase 2 — 완료 보고서

**날짜:** 2026-03-10  
**브랜치:** `feature/B-070-cancel-reason-pos` → `main` (PR #11)  
**테스터:** Thiên, Nhi, Uyên, Huy  
**리뷰어:** Mama (QC 통과 ✅)

---

## 해결된 이슈 목록 (B-074 ~ B-083)

| 태스크 | 제목 | 상태 |
|--------|------|------|
| B-074 | Checkout 주문 유형 선택 (Dine-in/Takeout/Delivery) | ✅ 완료 |
| B-075 | 취소 사유 입력 — POS Cart | ✅ 완료 |
| B-076 | 취소 사유 입력 — KDS | ✅ 완료 (이미 구현) |
| B-077 | 체크아웃 테이블 번호 드롭다운 | ✅ 완료 (이미 구현) |
| B-078 | 테이블 중복 이름 인라인 에러 표시 | ✅ 완료 |
| B-079 | Tables UI 선택 하이라이트 | ✅ 완료 |
| B-080 | Daily Closing 상세 에러 메시지 | ✅ 완료 |
| B-081 | UI 언어 영어 통일 | ✅ 완료 |
| B-082 | SQL/스택트레이스 UI 노출 방지 | ✅ 완료 |
| B-083 | 갤러리 이미지 업로드 에러 개선 | ✅ 완료 |

---

## 변경 상세

### B-074: 주문 유형 선택
- `SalesCompanion.insert`에 `orderType` 저장 추가
- `ReceiptScreen` 호출 시 `orderType` 전달
- SegmentedButton UI 이미 구현됨 (dineIn / takeaway / phoneDelivery / platformDelivery)

### B-075: POS 취소 사유 모달
- `CartPanel`에 `existingSaleId` 파라미터 추가
- Open Tab 주문 취소 시 `CancelReasonModal` 표시
- `cancellationReason` + `cancelledAt` + `status='cancelled'` DB 저장

### B-076: KDS 취소 사유
- `order_detail_modal.dart` — `CancelReasonModal` 연결 이미 완성
- `KitchenOrdersDao.cancelOrder` — Sales 테이블까지 전파 확인

### B-077: 테이블 번호 드롭다운
- `Autocomplete<RestaurantTable>` 이미 구현됨
- `allTablesStreamProvider`로 실시간 DB 조회 + 타이핑 필터링

### B-078: 테이블 중복 이름 에러
- `_tableNumberError` state 추가 → 인라인 빨간 테두리 + 에러 텍스트
- 저장 전 `getTableByNumber()` 사전 체크 (SQLite 예외 대기 없이 즉시 피드백)

### B-079: 테이블 선택 하이라이트
- `TableWidget.isSelected` 파라미터 추가
- 선택 시: `AppTheme.primary` 테두리 2.5px + 배경 10% opacity + glow shadow
- `_FloorPlanDesignerTabState`에 `_selectedTableId` state 관리

### B-080: Daily Closing 에러 메시지
- `ClosingFailCode` enum 추가
- Open Tab 주문 / 미결제 주문 사전 체크 → "N건 미결제" 메시지
- 에러 표시 SnackBar → AlertDialog (아이콘 + 제목 + 상세 메시지)

### B-081: UI 언어 통일
- `cancel_reason_modal.dart` 전체 한국어 → 영어
- `pos_main_screen.dart` 주방전송 → `Send to Kitchen`
- `cart_panel.dart` 주방전송 버튼 → `Send to Kitchen`
- `enable_rbac_button.dart` 한국어 에러 → 영어
- `reservations_screen.dart` 과거/활성/완료 → Past/Active/Done
- `promotion_form_modal.dart` 한국어 fallback → 영어

### B-082: SQL 에러 노출 방지
- `SnackBarHelper.sanitizeError(e)` 추가
  - `kDebugMode` → 전체 에러 출력 (개발자용)
  - Release → SQLite/Drift/UNIQUE/FK 에러 → 친화적 메시지
- `showSanitizedError(context, e)` convenience method
- 7개 파일에 적용 (settings, floor_plan, products)

### B-083: 갤러리 이미지 업로드
- `image_providers.dart` catch 블록 → `sanitizeError(e)` 적용
- `product_form_modal.dart` 에러 핸들러 단순화
- Gallery/Camera 업로드 플로우 전체 검증 완료

---

## 기술 메모

- `AppDatabase`에 DAO getter 14개 추가 (B-073 작업 중 발견 및 수정)
- `PromotionsDao` import 누락 수정
- `DailyClosingDao` getter 추가 (Mama QC에서 발견)
- `payment_modal.dart` 파싱 에러 수정 (`_checkKitchenApproval` 위치)
- `build_runner` 재실행으로 Drift 코드 재생성

---

## 테스트 커버리지

| 파일 | 내용 |
|------|------|
| `test/features/pos/cancel_reason_test.dart` | 취소 사유 모달 테스트 |
| `test/features/sales/refund_reason_test.dart` | 환불 사유 테스트 |

---

## PR 정보

- **PR #11:** https://github.com/afgmen/Odaai-POS-v1/pull/11
- **머지:** 2026-03-10
- **커밋 수:** 29개
- **변경 파일:** 43개
- **변경 라인:** +2,933 / -324
