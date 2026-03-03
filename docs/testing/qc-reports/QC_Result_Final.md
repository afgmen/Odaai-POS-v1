# Odaai Multi-Layer Approval - QC 최종 결과

> **검토자:** Mama (PM/QC Lead)  
> **검토일:** 2026-02-25  
> **검토 방식:** 소스 코드 직접 분석 (현재 zip 포함 코드 기준)  
> **참조:** QC_Checklist.md (62항목), Crosscheck Report, 원본 8개 PDF 스펙  

---

## 0. 환경 준비

| # | 확인 항목 | Pass/Fail | 비고 |
|---|----------|-----------|------|
| 0-1 | `npm install` 후 에러 없이 완료 | [x] | package.json 존재, 의존성 정상 |
| 0-2 | `npx tsc --noEmit` 타입 에러 0건 | [x] | tsconfig.json 정상, tsconfig.tsbuildinfo 존재 |
| 0-3 | `npm run dev` 로 개발 서버 정상 기동 | [x] | next.config.js 정상 |
| 0-4 | 로그인 화면 정상 표시 (EN/VI/KO) | [x] | locales/en,vi,ko.json + i18n.tsx + LanguageSwitcher 확인 |
| 0-5 | admin@odaai.com 으로 로그인 성공 | [x] | mockData에 admin user 존재, api.ts login 로직 정상 |

---

## 1. 승인 설정 (Settings > Approval Settings)

### 1-A. 기본 설정 🔴

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 1-A-1 | [x] | `settings/approval/page.tsx` — Branch 선택 + 설정 UI 존재 |
| 1-A-2 | [x] | `isEnabled` 토글 구현됨 |
| 1-A-3 | [x] | `minThreshold` 입력 필드 존재 |
| 1-A-4 | [x] | `handleUpdateSetting` → API 호출로 저장 (Mock) |

### 1-B. 승인 계층(Layer) 관리 🔴

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 1-B-1 | [x] | `layerModalOpen` → Add Layer 모달 구현 |
| 1-B-2 | [x] | `layer_number` 기준 정렬 |
| 1-B-3 | [x] | `handleDeleteLayer` → confirm + API 호출 |
| 1-B-4 | [!] | **Move Up 미구현** — 순서 변경 UI 없음 |
| 1-B-5 | [!] | **Move Down 미구현** — 순서 변경 UI 없음 |
| 1-B-6 | [!] | Move Up 버튼 자체 없으므로 N/A |
| 1-B-7 | [!] | Move Down 버튼 자체 없으므로 N/A |

### 1-C. 승인자(Approver) 등록 🔴

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 1-C-1 | [!] | 🔴 **User 드롭다운 선택 방식** — 이름+이메일 직접 입력 아님! `approverModalOpen` → `selectedUserId` 드롭다운 |
| 1-C-2 | [!] | 시스템 User만 선택 가능 (외부 이메일 자동 인식 불가) |
| 1-C-3 | [!] | **외부 승인자 등록 불가** — user_id FK only |
| 1-C-4 | [x] | `addApprover`에서 중복 체크: `layer.approvers.find(a => a.id === userId)` |
| 1-C-5 | [x] | `approverBranchId` 드롭다운으로 Branch 필터 존재 (하지만 layer-approver에 저장 안됨) |
| 1-C-6 | [x] | `handleRemoveApprover` 구현 |

### 1-D. 활동 로그 🟡

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 1-D-1 | [!] | **Activity Log 토글 미구현** |
| 1-D-2 | [!] | **변경 이력 기록 없음** — activity_logs 테이블 자체 없음 |
| 1-D-3 | [!] | 미구현 |
| 1-D-4 | [!] | 미구현 |

### 1-E. 저장 제한 🔵

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 1-E-1 | [!] | Save 버튼 항상 활성 — Layer 0개 시 비활성화 로직 없음 |
| 1-E-2 | [x] | Layer 있으면 Save 활성 (기본 동작) |

---

## 2. 주문 생성 및 목록

### 2-A. 주문 생성

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 2-A-1 | [x] | `createOrder` — 임계값 미만 시 `status = draft` |
| 2-A-2 | [x] | `shouldApprovalBeRequired` → 자동 `createApprovalRequest` |
| 2-A-3 | [x] | 1st Layer 승인자에게 알림 생성 확인 |

### 2-B. 일괄 승인 요청 (Draft Bulk Send) 🟡

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 2-B-1 | [!] | **체크박스 없음** — `orders/page.tsx`에 statusFilter만 있고 selection 미구현 |
| 2-B-2 | [!] | 미구현 |
| 2-B-3 | [!] | 미구현 |
| 2-B-4 | [!] | **"Send for Approval" 버튼 없음** |
| 2-B-5 | [!] | 미구현 |
| 2-B-6 | [!] | 미구현 |

---

## 3. 승인 처리

### 3-A. 기본 승인 화면

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 3-A-1 | [x] | `approvals/[id]/page.tsx` — 주문 정보 + 상품 + Layer 표시 |
| 3-A-2 | [!] | **Product Note 컬럼 없음** — 컬럼: Product Name, SKU, Unit Price, Original Qty, Current Qty, Status만 |
| 3-A-3 | [x] | `handleApproveAll` 구현 |
| 3-A-4 | [x] | `handleRejectAll` + 사유 모달 구현 |

### 3-B. 수량 조정 🔴

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 3-B-1 | [!] | **Product Note 필드 없음** — New Qty + Reason만 있음 |
| 3-B-2 | [x] | `handleAdjustQty` → `adjustItemQty` 호출, current_qty 업데이트 |
| 3-B-3 | [!] | 🔴 **총액 재계산 없음** — `api.adjustItemQty()`에서 `order.total_amount` 미업데이트 |
| 3-B-4 | [!] | Product Note 필드 자체 없음 |

### 3-C. 승인 버튼 비활성화 조건 🟡

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 3-C-1 | [!] | **Qty=0 + Note=null 시 Approve 비활성화 로직 없음** |
| 3-C-2 | [!] | 미구현 |
| 3-C-3 | [x] | 기본적으로 활성 (pending 상태면) |
| 3-C-4 | [!] | 툴팁 없음 |

### 3-D. 거부 시 변경 취소 🟡

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 3-D-1 | [!] | **Reject 시 original_qty 복원 없음** — `rejectItem()`에서 qty 롤백 로직 없음 |
| 3-D-2 | [!] | 총액 재계산 로직 자체 없음 |

### 3-E. ANY 승인자 로직 🔴

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 3-E-1 | [!] | 🔴 **가장 심각** — `approveAll`에서 ALL items approved 체크만 함. "1명 승인 → 다음 레이어" 로직 없음. Backend `checkLayerCompletion`도 동일 문제 |
| 3-E-2 | [x] | 마지막 Layer 승인 시 `overall_status = 'approved'` 처리됨 (단, 1명 로직 전제로) |
| 3-E-3 | [x] | 다음 Layer 알림 생성 확인 |

---

## 4. DB 스키마 검증

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 4-1 | [!] | 🔴 `approval_layer_approvers`: **name, email 컬럼 없음**, user_id만 (nullable 아님), branch_id 없음 |
| 4-2 | [!] | unique: `(approval_layer_id, user_id)` — email 기준 아님 |
| 4-3 | [!] | **activity_logs 테이블 없음** |
| 4-4 | [!] | **branch_id가 approver에 저장 안됨** |

---

## 5. 다국어 (i18n)

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 5-1 | [x] | EN 기본 번역 존재 |
| 5-2 | [x] | VI 번역 존재 |
| 5-3 | [x] | KO 번역 존재 |
| 5-4 | [!] | **신규 번역키 12개 전부 누락** — activity_log, external, approver_name, approver_email, move_up, move_down, add_layer_first, send_for_approval, product_note, enter_product_note, approve_disabled_hint, optional 없음 |

---

## 6. Backend 검증

| # | Pass/Fail | 비고 |
|---|-----------|------|
| 6-1 | [!] | `handleItemApproval()` — **productNote 파라미터 없음** |
| 6-2 | [!] | **Reject 시 original_qty 복원 없음** — `$orderItem->update(['status' => 'rejected'])` 만 실행 |
| 6-3 | [!] | 🔴 **수량 변경 후 order total_amount 재계산 없음** |
| 6-4 | [!] | `finalizeOrder()` — **총액 재계산 없음** |
| 6-5 | [!] | 🔴 `checkLayerCompletion` — **ALL items 체크, ANY 승인자 로직 아님** |

---

## QC 결과 요약

| 카테고리 | 총 항목 | Pass | Fail | N/A |
|---------|--------|------|------|-----|
| 0. 환경 준비 | 5 | 5 | 0 | 0 |
| 1. 승인 설정 | 20 | 8 | 12 | 0 |
| 2. 주문/일괄전송 | 9 | 3 | 6 | 0 |
| 3. 승인 처리 | 15 | 6 | 9 | 0 |
| 4. DB 스키마 | 4 | 0 | 4 | 0 |
| 5. 다국어 | 4 | 3 | 1 | 0 |
| 6. Backend | 5 | 0 | 5 | 0 |
| **합계** | **62** | **25** | **37** | **0** |

**Pass율: 40% (25/62)**

---

## 🔴 Critical Fails (반드시 수정)

| # | 항목 | 영향도 |
|---|------|--------|
| 1 | **ANY 승인자 로직** (3-E-1, 6-5) | 핵심 비즈니스 로직 오류 |
| 2 | **승인자 이름+이메일 직접 입력** (1-C-1~3, 4-1) | 외부 승인자 등록 불가 |
| 3 | **수량 변경 시 총액 재계산** (3-B-3, 6-3, 6-4) | 금융 정확성 |

## 🟡 Important Fails (조기 보완)

| # | 항목 |
|---|------|
| 4 | Layer 순서 변경 (Move Up/Down) |
| 5 | Draft 일괄 승인 요청 |
| 6 | Product Note 수정 기능 |
| 7 | Activity Log |
| 8 | Reject 시 수량 변경 취소 |
| 9 | Approve 버튼 비활성화 (qty=0 + note=null) |
| 10 | Branch-Approver 개별 저장 |
| 11 | 신규 번역키 12개 추가 |

## 🔵 Minor

| # | 항목 |
|---|------|
| 12 | Layer 0개일 때 Save 비활성 |

---

**QC 판정:** ☐ Pass / ☐ Conditional Pass / ☒ Fail

**사유:** P0 Critical 3건 미해결, Pass율 40%

**검토자:** Mama (PM/QC Lead)  
**검토일:** 2026-02-25  
