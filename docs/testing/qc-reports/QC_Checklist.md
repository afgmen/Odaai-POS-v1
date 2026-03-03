# Odaai Multilayer Approval - QC Checklist

> **프로젝트:** Odaai 다층 승인 시스템
> **버전:** v1.0 (P0+P1 수정 완료)
> **작성일:** 2026-02-25
> **대상:** 외부 QC 검토자
> **참조 문서:** 원본 PDF 스펙 8건 (동봉)

---

## 사용법

- 각 항목을 테스트한 후 `[ ]`를 `[x]` (Pass) 또는 `[!]` (Fail)로 변경
- Fail인 경우 **비고** 열에 증상 기술
- 우선순위: 🔴 P0 (Critical) / 🟡 P1 (Important) / 🔵 P2 (Nice-to-have)

---

## 0. 환경 준비

| # | 확인 항목 | Pass/Fail | 비고 |
|---|----------|-----------|------|
| 0-1 | `npm install` 후 에러 없이 완료 | [ ] | |
| 0-2 | `npx tsc --noEmit` 타입 에러 0건 | [ ] | |
| 0-3 | `npm run dev` 로 개발 서버 정상 기동 (localhost:3000) | [ ] | |
| 0-4 | 로그인 화면 정상 표시 (EN/VI/KO 3개 언어 전환) | [ ] | |
| 0-5 | admin@odaai.com 으로 로그인 성공 | [ ] | |

---

## 1. 승인 설정 (Settings > Approval Settings)

**참조:** Doc 1 (Admin), Doc 2 (Settings)

### 1-A. 기본 설정 🔴

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 1-A-1 | Settings > Approval Settings 페이지 진입 | 지점(Branch)별 승인 설정 목록 표시 | [ ] | |
| 1-A-2 | Enable Approval 토글 ON/OFF | is_enabled 상태 변경, 저장 시 반영 | [ ] | |
| 1-A-3 | Minimum Threshold 금액 변경 | 숫자 입력 가능, 저장 시 반영 | [ ] | |
| 1-A-4 | Save 버튼 클릭 후 설정 유지 | 페이지 새로고침 후에도 설정 유지 | [ ] | |

### 1-B. 승인 계층(Layer) 관리 🔴

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 1-B-1 | Add Layer 버튼 클릭 | Layer Name 입력 모달/영역 표시 | [ ] | |
| 1-B-2 | 새 Layer 추가 후 목록에 표시 | layer_number 순서대로 표시 | [ ] | |
| 1-B-3 | Layer 삭제 | 확인 모달 후 삭제, 목록에서 제거 | [ ] | |
| 1-B-4 | 🔴 Layer 순서 변경 (Move Up) | 위 Layer와 순서 교체, layer_number 재정렬 | [ ] | |
| 1-B-5 | 🔴 Layer 순서 변경 (Move Down) | 아래 Layer와 순서 교체, layer_number 재정렬 | [ ] | |
| 1-B-6 | 첫 번째 Layer의 Move Up 버튼 | 비활성화(disabled) 상태 | [ ] | |
| 1-B-7 | 마지막 Layer의 Move Down 버튼 | 비활성화(disabled) 상태 | [ ] | |

### 1-C. 승인자(Approver) 등록 🔴

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 1-C-1 | 🔴 Add Approver 클릭 시 입력 방식 | **이름(Name) + 이메일(Email) 직접 입력** 필드 표시 (드롭다운 선택이 아님!) | [ ] | |
| 1-C-2 | 시스템 사용자 이메일 입력 | 자동으로 user_id 연결 (내부 사용자로 인식) | [ ] | |
| 1-C-3 | 외부 이메일 입력 (예: external@gmail.com) | user_id = null, "External" 뱃지 표시 | [ ] | |
| 1-C-4 | 같은 Layer에 동일 이메일 중복 추가 시도 | 에러 메시지 표시, 추가 불가 | [ ] | |
| 1-C-5 | Branch 선택 (선택사항) | Branch 드롭다운 표시, 선택/미선택 모두 가능 | [ ] | |
| 1-C-6 | 승인자 삭제 | 해당 승인자 목록에서 제거 | [ ] | |

### 1-D. 활동 로그 🟡

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 1-D-1 | Activity Log 토글 버튼 표시 | 토글 클릭 시 활동 로그 패널 열림/닫힘 | [ ] | |
| 1-D-2 | 승인 설정 변경 후 Activity Log 확인 | 변경 내역 (who, what, when) 기록됨 | [ ] | |
| 1-D-3 | 승인자 추가/삭제 후 Activity Log 확인 | 해당 이벤트 기록됨 | [ ] | |
| 1-D-4 | Layer 순서 변경 후 Activity Log 확인 | 재정렬 이벤트 기록됨 | [ ] | |

### 1-E. 저장 제한 🔵

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 1-E-1 | 🔵 Layer가 0개인 상태에서 Save 버튼 | Save 버튼 비활성화(disabled) | [ ] | |
| 1-E-2 | Layer 1개 이상 추가 후 Save 버튼 | Save 버튼 활성화 | [ ] | |

---

## 2. 주문 생성 및 목록 (Orders)

**참조:** Doc 3 (Approval Request in Buy Order)

### 2-A. 주문 생성

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 2-A-1 | 새 주문 생성 (임계값 미만 금액) | status = draft | [ ] | |
| 2-A-2 | 새 주문 생성 (임계값 이상 금액) | status = pending_approval, 승인 요청 자동 생성 | [ ] | |
| 2-A-3 | 주문 생성 시 알림(Notification) | 첫 번째 Layer 승인자들에게 알림 생성 | [ ] | |

### 2-B. 일괄 승인 요청 (Draft Bulk Send) 🟡

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 2-B-1 | Orders 목록에서 Draft 탭/필터 선택 | Draft 주문만 표시, 체크박스 표시 | [ ] | |
| 2-B-2 | 개별 주문 체크박스 선택 | 선택된 주문 수 카운트 표시 | [ ] | |
| 2-B-3 | "전체 선택" 체크박스 클릭 | 모든 Draft 주문 선택됨 | [ ] | |
| 2-B-4 | "Send for Approval" 버튼 클릭 | 확인 대화상자 표시 | [ ] | |
| 2-B-5 | 확인 후 일괄 전송 | 선택된 주문들의 status → pending_approval 변경 | [ ] | |
| 2-B-6 | 임계값 미달 주문이 포함된 경우 | 해당 주문은 skipped, 결과에 sent/skipped 수 표시 | [ ] | |

---

## 3. 승인 처리 (Approvals > Detail)

**참조:** Doc 7 (Product-Level Approval), Doc 8 (Adjust Quantity)

### 3-A. 기본 승인 화면

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 3-A-1 | 승인 상세 페이지 진입 | 주문 정보 + 상품 목록 + 현재 Layer 표시 | [ ] | |
| 3-A-2 | 상품 목록 테이블 컬럼 | Product Name, SKU, Unit, Unit Price, Original Qty, Current Qty, **Product Note**, Status 포함 | [ ] | |
| 3-A-3 | Approve All 클릭 | 모든 항목 approved, 다음 Layer로 이동 | [ ] | |
| 3-A-4 | Reject All 클릭 | 사유 입력 모달 → 모든 항목 rejected | [ ] | |

### 3-B. 수량 조정 (Adjust Qty) 🔴

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 3-B-1 | Adjust Qty 모달 열기 | New Qty 입력 + Reason 입력 + **Product Note 입력** 필드 표시 | [ ] | |
| 3-B-2 | 수량을 10 → 5로 변경, 사유 입력 후 제출 | current_qty = 5, status = adjusted | [ ] | |
| 3-B-3 | 🔴 수량 변경 후 주문 총액 재계산 | total_amount = Σ(unit_price × current_qty) 재계산됨 | [ ] | |
| 3-B-4 | Product Note 입력 후 저장 | 상품 테이블의 Note 열에 반영 | [ ] | |

### 3-C. 승인 버튼 비활성화 조건 🟡

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 3-C-1 | 🟡 수량을 0으로 조정, Note도 비어있는 상태 | Approve 버튼 **비활성화** (disabled) | [ ] | |
| 3-C-2 | 수량 = 0, Note에 값 입력 | Approve 버튼 **활성화** | [ ] | |
| 3-C-3 | 수량 > 0, Note 비어있음 | Approve 버튼 **활성화** | [ ] | |
| 3-C-4 | 비활성화 상태에서 툴팁/힌트 메시지 표시 | "Cannot approve: qty is 0 and no note provided" 또는 해당 언어 번역 | [ ] | |

### 3-D. 거부 시 변경 취소 (Reject Discard) 🟡

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 3-D-1 | 수량을 10→5로 조정한 후, 해당 항목 Reject | current_qty가 **원래 수량(10)으로 복원** | [ ] | |
| 3-D-2 | Reject 후 주문 총액 | original_qty 기반으로 재계산됨 | [ ] | |

### 3-E. ANY 승인자 로직 (Layer 진행) 🔴

| # | 테스트 시나리오 | 예상 결과 | Pass/Fail | 비고 |
|---|---------------|----------|-----------|------|
| 3-E-1 | Layer에 승인자 3명 배정, 그 중 1명이 Approve All | **다음 Layer로 이동** (3명 모두 승인 필요 없음) | [ ] | |
| 3-E-2 | 마지막 Layer에서 1명이 Approve All | 주문 status → approved (최종 승인) | [ ] | |
| 3-E-3 | 다음 Layer 이동 시 알림 | 다음 Layer 승인자들에게 알림 생성 | [ ] | |

---

## 4. DB 스키마 검증

**참조:** Doc 5 (Branch Selection)

| # | 확인 항목 | 예상 결과 | Pass/Fail | 비고 |
|---|----------|----------|-----------|------|
| 4-1 | approval_layer_approvers 테이블 | name, email, branch_id(nullable), user_id(nullable) 컬럼 존재 | [ ] | |
| 4-2 | unique 제약조건 | (approval_layer_id, email) 유니크 | [ ] | |
| 4-3 | activity_logs 테이블 | user_id, user_name, user_role, feature, action, detail, timestamps 컬럼 존재 | [ ] | |
| 4-4 | 🟡 Branch-Approver 관계 | branch_id가 approver에 저장됨 (Layer가 아닌 개별 Approver에) | [ ] | |

---

## 5. 다국어 (i18n)

**참조:** 모든 Doc 공통 요구사항 "Apply to 03 languages"

| # | 확인 항목 | Pass/Fail | 비고 |
|---|----------|-----------|------|
| 5-1 | EN(English) 전환 시 모든 신규 UI 문자열 정상 표시 | [ ] | |
| 5-2 | VI(Tiếng Việt) 전환 시 모든 신규 UI 문자열 정상 표시 | [ ] | |
| 5-3 | KO(한국어) 전환 시 모든 신규 UI 문자열 정상 표시 | [ ] | |
| 5-4 | 번역 누락 키 없음 (콘솔에 missing key 경고 없음) | [ ] | |

**신규 번역키 체크 (각 언어별 확인):**

| 키 | EN | VI | KO |
|----|----|----|-----|
| settings.activity_log | Activity Log | Nhật ký hoạt động | 활동 로그 |
| settings.external | External | Bên ngoài | 외부 |
| settings.approver_name | Approver Name | Tên người phê duyệt | 승인자 이름 |
| settings.approver_email | Approver Email | Email người phê duyệt | 승인자 이메일 |
| settings.move_up | Move Up | Lên trên | 위로 이동 |
| settings.move_down | Move Down | Xuống dưới | 아래로 이동 |
| settings.add_layer_first | Add at least one layer... | Thêm ít nhất một cấp... | 저장하기 전에... |
| orders.send_for_approval | Send for Approval | Gửi phê duyệt | 승인 요청 보내기 |
| orders.product_note | Product Note | Ghi chú sản phẩm | 상품 메모 |
| approvals.enter_product_note | Enter product note | Nhập ghi chú sản phẩm | 상품 메모 입력 |
| approvals.approve_disabled_hint | Cannot approve... | Không thể phê duyệt... | 승인 불가... |
| common.optional | Optional | Tùy chọn | 선택사항 |

---

## 6. Backend (Laravel) 검증

**참조:** Doc 8 (Adjust Qty), Doc 7 (Product-Level)

| # | 확인 항목 | 예상 결과 | Pass/Fail | 비고 |
|---|----------|----------|-----------|------|
| 6-1 | ApprovalService::handleItemApproval() | productNote 파라미터 지원 | [ ] | |
| 6-2 | Reject 시 original_qty 복원 | current_qty = original_qty로 rollback | [ ] | |
| 6-3 | 수량 변경 후 order total_amount 재계산 | Σ(unit_price × current_qty) | [ ] | |
| 6-4 | 최종 승인(finalizeOrder) 시 총액 재계산 | 마지막으로 한 번 더 재계산 | [ ] | |
| 6-5 | checkLayerCompletion 로직 | ANY 1인 승인 → Layer 완료 (전원 아님) | [ ] | |

---

## 7. 알려진 미구현 / 향후 작업 (Out of Scope)

아래 항목은 이번 QC 범위에서 **제외**합니다. Fail 처리하지 마세요.

| 항목 | 상태 | 비고 |
|------|------|------|
| 이메일 발송 (Doc 4, 6) | 미구현 | 백엔드 SMTP 연동 필요 |
| 실제 API 연동 | Mock API | 프론트엔드 Mock 데이터로 동작 |
| 모바일 반응형 (OFM) | 부분 구현 | Tailwind 기반이나 별도 모바일 QC 필요 |
| 1:N 주문-승인요청 (복수 주문 1건 승인) | 미구현 | 스펙상 1:1 관계 확인됨 |
| 주문 내 상품 체크박스 부분승인 UI | 부분 구현 | Approve/Reject/Adjust 개별 동작 |

---

## QC 결과 요약

| 카테고리 | 총 항목 | Pass | Fail | N/A |
|---------|--------|------|------|-----|
| 0. 환경 준비 | 5 | | | |
| 1. 승인 설정 | 20 | | | |
| 2. 주문/일괄전송 | 9 | | | |
| 3. 승인 처리 | 15 | | | |
| 4. DB 스키마 | 4 | | | |
| 5. 다국어 | 4 | | | |
| 6. Backend | 5 | | | |
| **합계** | **62** | | | |

**QC 판정:** ☐ Pass / ☐ Conditional Pass / ☐ Fail

**검토자:** ___________________
**검토일:** ___________________
**서명:** ___________________
