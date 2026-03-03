# Odaai Multi-Layer Approval - QC 결과 (Mama)

> **검토자:** Mama (PM/QC Lead)  
> **검토일:** 2026-02-25  
> **역할:** 원본 스펙 대비 기능 충실도 검증, Crosscheck Report 검증, QC 총괄  
> **비교 대상:** 현재 코드 vs 원본 8개 PDF 스펙 vs Crosscheck Report  

---

## 1. Crosscheck Report 검증 (Mama 소견)

Crosscheck Report에서 제기된 주요 판정에 대한 Mama의 독립적 의견:

### P0-1: 1 Request → N Orders (1:1 vs 1:N)

| 항목 | 내용 |
|------|------|
| 이전 리뷰 (Mama) | 1:N이 필요하다고 판단 |
| Crosscheck 판정 | DISAGREE — 1:1이 맞다 |
| **Mama 재검토** | **Crosscheck가 맞음 ✅** |

**근거:** 원본 Doc 3을 재확인한 결과:
- "Single supplier: an order will be sent to approver via 01 email with 01 weblink having 01 order detail → 1 request_id and 1 order_id"
- "Multiple suppliers: Many orders of many suppliers will be sent to approver via 01 email with 01 weblink having many orders detail → 1 request_id and group of order_ids"

이것은 **이메일 통지 그룹핑**에 대한 설명이지, 데이터 모델 자체가 1:N이어야 한다는 의미가 아님. 실제 DB 관계는 1:1이 맞고, 이메일 발송 시에만 여러 주문을 묶어서 보내는 것.

**결론:** 기존 1:1 관계 유지. **내 이전 P0 판정을 철회합니다.**

---

### P0-2: 승인자 이름+이메일 직접 입력

| 항목 | 내용 |
|------|------|
| Crosscheck 판정 | AGREE — P0 |
| **Mama 재검토** | **동의 ✅ — P0 확정** |

현재 코드 확인:
- `approval_layer_approvers` 테이블: `user_id` FK만 존재, `name`/`email` 컬럼 없음
- Frontend `settings/approval/page.tsx`: User 드롭다운 선택 방식
- 원본 Doc 2: 명확히 `Approver name: Text, Enter name` / `Approver email: Text, Enter email` 필드 정의

**코드에 반영 필요:**
- DB: `approval_layer_approvers`에 `name`, `email` 컬럼 추가, `user_id` nullable로 변경
- Frontend: 드롭다운 → 텍스트 입력 필드로 변경
- Backend: addApprover 로직 수정

---

### P0-3: Branch-Approver 매핑

| 항목 | 내용 |
|------|------|
| Crosscheck 판정 | PARTIALLY AGREE — P1로 하향 |
| **Mama 재검토** | **Crosscheck가 맞음 ✅ — P1로 조정** |

현재 코드에서 approver 추가 시 branch를 선택할 수는 있지만, `approval_layer_approvers` 테이블에 `branch_id`가 저장되지 않는 문제. 사용자의 `users.branch_id`로 우회 가능하긴 하나, 명세서 Doc 5에서 "Approver 1 - Branch = All, Approver 2 - Branch 1"처럼 **승인자 레벨에서 별도 branch 지정**을 요구하므로, `branch_id` 컬럼 추가는 필요.

---

### NEW-1: ANY vs ALL 승인자 로직 ⚠️ 가장 중요

| 항목 | 내용 |
|------|------|
| Crosscheck 판정 | NEW P0 — BUG |
| **Mama 재검토** | **동의 ✅ — P0 확정, 가장 심각한 버그** |

원본 Doc 2: *"1 layer - many approvers: one of them approves, the orders can go to next approver"*

현재 `ApprovalService::checkLayerCompletion()` 코드:
```php
foreach ($items as $item) {
    if ($item->status === 'pending') {
        return false; // 모든 아이템이 처리되어야 완료
    }
}
```

**문제:** 이 로직은 "모든 아이템이 처리되었는지" 확인하는데, 핵심은 **"레이어 내 한 명의 승인자가 전체 아이템을 승인하면 다음 레이어로"** 이동해야 한다는 것. 현재 코드는 여러 승인자가 각각 다른 아이템을 처리하는 시나리오도 허용하는데, 명세서는 **한 명의 승인만으로 충분**하다고 명시.

---

### NEW-2~5: 추가 발견 사항

| ID | 항목 | Crosscheck | Mama 검증 |
|----|------|-----------|----------|
| NEW-2 | Activity log (설정 변경 이력) | P1 MISSING | ✅ 동의 — `activity_logs` 테이블 자체 없음 |
| NEW-3 | Reject 시 수량/메모 변경 취소 | P1 MISSING | ✅ 동의 — reject에서 rollback 로직 없음 |
| NEW-4 | Qty=0 + Note=null → Approve 비활성 | P1 MISSING | ✅ 동의 — validation 없음 |
| NEW-5 | Layer 0개일 때 Save 비활성 | P2 MINOR | ✅ 동의 |

---

## 2. 현재 코드 상태 확인 (QC Checklist 기반)

Jin이 말씀한 수정 파일들의 코드를 확인한 결과, **현재 프로젝트 내 코드는 아직 수정 전 상태**입니다:

| 파일 | 현재 상태 | 수정 필요 |
|------|----------|----------|
| `lib/types.ts` | Approver, ActivityLog 타입 **미추가** | ⚠️ 수정본 미반영 |
| `services/api.ts` | 기존 mock API 그대로 | ⚠️ 수정본 미반영 |
| `services/mockData.ts` | 기존 그대로 | ⚠️ 수정본 미반영 |
| `app/settings/approval/page.tsx` | User 드롭다운 방식 그대로 | ⚠️ 수정본 미반영 |
| `app/approvals/[id]/page.tsx` | Product Note 없음 | ⚠️ 수정본 미반영 |
| `app/orders/page.tsx` | 일괄 전송 기능 없음 | ⚠️ 수정본 미반영 |
| `locales/*.json` | 신규 번역키 미추가 | ⚠️ 수정본 미반영 |
| `ApprovalService.php` | ANY 로직 미구현, 총액 재계산 없음 | ⚠️ 수정본 미반영 |
| `migration` | name/email/branch_id 없음, activity_logs 없음 | ⚠️ 수정본 미반영 |

**→ Jin이 작업한 수정 코드가 아직 프로젝트 폴더에 반영되지 않았습니다. 수정된 파일을 받아야 QC Checklist의 62개 항목을 실행할 수 있습니다.**

---

## 3. 우선순위 최종 정리 (Mama + Crosscheck 종합)

### 🔴 P0 (Critical) — 3개

| # | 항목 | 소스 |
|---|------|------|
| 1 | **승인자 이름+이메일 직접 입력** (외부 승인자 지원) | 원래 P0-2 |
| 2 | **ANY 승인자 로직** (한 명 승인 → 다음 레이어) | Crosscheck NEW-1 |
| 3 | **수량 변경 시 주문 총액 재계산** | 원래 P1-4 → 승격 |

### 🟡 P1 (Important) — 7개

| # | 항목 |
|---|------|
| 4 | Layer 순서 변경 (Sort/Move Up/Down) |
| 5 | Branch-Approver 개별 매핑 (branch_id 저장) |
| 6 | Draft 일괄 승인 요청 (Bulk Send) |
| 7 | Product note 수정 기능 |
| 8 | Activity log (설정 변경 이력) |
| 9 | Reject 시 수량/메모 변경 취소 (rollback) |
| 10 | Qty=0 + Note=null → Approve 비활성 |

### 🔵 P2 (Nice-to-have) — 1개

| # | 항목 |
|---|------|
| 11 | Layer 0개일 때 Save 비활성 |

### ❌ 철회

| # | 항목 | 이유 |
|---|------|------|
| ~~P0-1~~ | ~~1 Request → N Orders~~ | Crosscheck 지적대로 1:1이 맞음. 이메일 통지 그룹핑과 데이터 모델 혼동 |

---

## 4. 결론

1. **Crosscheck Report는 정확하고 가치 있는 리뷰입니다.** 특히 내 이전 P0-1 판정을 바로잡아줬고, NEW-1(ANY 승인자 로직)이라는 심각한 버그를 추가 발견.
2. **현재 코드에는 수정본이 미반영** — Jin이 작업한 수정 파일을 프로젝트에 반영해주시면, QC Checklist 62개 항목 실행 가능.
3. **전체 평가 3.5/5**로 Crosscheck의 평가에 동의합니다.

---

**Mama 서명:** ✅ 검토 완료  
**다음 액션:** 수정된 코드 반영 후 Dede(기술 QC) + Sese(문서/i18n QC) 진행
