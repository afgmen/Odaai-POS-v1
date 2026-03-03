# PRD: Multi-Layer Approval System - Web Implementation

> 버전: 1.0  
> 작성자: Mama (PM)  
> 작성일: 2026-02-25  
> 요청자: Jin  
> 상태: Draft  

---

## 1. 개요 (Overview)

### 1.1 배경
현재 Oda 플랫폼에서는 Multi-Layer Approval System이 **이메일 기반 웹링크**를 통해 구현되어 있다. 승인자는 이메일로 승인 요청을 받고, 웹링크를 통해 승인/거절 액션을 수행한다.

### 1.2 목표
이 시스템을 **웹 애플리케이션 내에서 직접** 구현하여, 이메일 의존도를 줄이고 실시간 승인 프로세스를 지원한다.

### 1.3 범위
기존 8개 기능 문서의 모든 요구사항을 웹 UI로 전환:

| # | 원본 문서 | 핵심 기능 |
|---|----------|----------|
| 1 | [OFA] Add "Multiplayer approval" feature on the Admin | Admin에서 회사별 Multi-layer approval 토글 설정 |
| 2 | [OFD, OFM] "Approval setting" feature on the Settings | 승인 레이어 목록 생성/편집/삭제/정렬 |
| 3 | [OFD, OFM] "Approval request" feature in the Buy order | 구매 주문에서 승인 요청 생성 및 관리 |
| 4 | [OFD, OFM] Approve order by email template | 이메일/웹링크 통한 승인 프로세스 |
| 5 | Add a "Branch" selection when creating approver | 지점(Branch)별 승인자 설정 |
| 6 | Send rejection/approval email notification | 거절/승인 이메일 알림 |
| 7 | Improve approval request by product in an order | 상품 단위 부분 승인/거절 및 메모 |
| 8 | [OFD, OFM] Adjust the quantity on the approval request | 승인 요청에서 수량/메모 수정 |

---

## 2. 용어 정의 (Glossary)

| 용어 | 설명 |
|------|------|
| Requester (요청자) | 구매 주문을 생성하고 승인을 요청하는 직원/바이어 |
| Approver (승인자) | 승인 레이어에 등록된 승인 담당자 |
| Approval Layer | 승인 단계 (Layer 1 → Layer 2 → ... → Final Layer) |
| Approval Request | 하나의 승인 요청 (1 request_id, 다수 order_id 가능) |
| Branch (지점) | 회사의 지점/부서 |
| Partial Approval | 주문 내 일부 상품만 승인하고 나머지는 거절 |
| OFA | Oda For Admin |
| OFD | Oda For Desktop |
| OFM | Oda For Mobile |

---

## 3. 기능 상세 (Functional Requirements)

### 3.1 Admin 설정 - Multi-Layer Approval 토글

**경로:** Admin > Companies > Company mngt > Company detail > Setting tab

| 항목 | 상세 |
|------|------|
| 설정명 | Multi-layer approval |
| 설명 | Allow user to implement a multi-layer approval process for buy orders |
| 타입 | Toggle (On/Off) |
| 위치 | Profit setting 아래 |
| 기본값 | Off |
| Off | 기존 단일 레이어 승인 (Role permission 기반) |
| On | 다중 레이어 승인 사용 (새 기능) |
| Toast | "Multi-layer approval settings updated successfully." |

**다국어 지원:**
- ENG: Allow user to implement a multi-layer approval process for orders.
- VIE: Cho phép người dùng triển khai quy trình phê duyệt nhiều lớp cho đơn hàng.
- KOR: 사용자가 주문에 대해 다중 계층 승인 프로세스를 구현할 수 있도록 허용합니다.

---

### 3.2 Approval Setting - 승인 레이어 관리

**경로:** (웹) Settings > Approval setting

**전제조건:** Admin에서 "Multi-layer approval" 토글이 ON

#### 3.2.1 페이지 구조

- **Header:** Approval setting
- **Section Label:** Approval layer list
- **버튼:**
  - `Create layer` - 새 레이어 추가 (현재 Layer N 다음에 N+1 생성)
  - `Sort layer` - 레이어 순서 변경 팝업
  - `Cancel` - 이전 저장 이후 모든 변경 취소 (항상 활성)
  - `Save` - 현재 UI/데이터 저장 (변경사항 있을 때만 활성)

**저장 시 Toast:** "Approval layer has been updated successfully."

#### 3.2.2 레이어 생성/편집

| 필드 | 필수 | 편집가능 | 타입 | 값/규칙 |
|------|------|---------|------|---------|
| Layer no | - | NO | System | 자동 생성 (Layer 1, Layer 2, ...) |
| Layer name | YES | YES | Text | Placeholder: "Enter layer name" |
| Delete layer | - | - | Icon | 클릭 시 레이어 숨김 (Save 전까지 미반영) |
| Approver name | YES | YES | Text | Placeholder: "Enter name" |
| Approver email | YES | YES | Text | Placeholder: "Enter email" |
| Branch | YES | YES | Single select | "All" (기본) 또는 특정 지점 선택 |

**규칙:**
- 1 레이어 - 다수 승인자: 그 중 한 명이 승인하면 다음 레이어로 이동
- 승인자 추가(+ 아이콘) 및 제거(- 아이콘) 가능
- Branch 선택은 해제 불가 (항상 값이 있어야 함)
- 동일 승인자를 여러 지점에 배정하려면 각 지점마다 별도로 추가 필요

#### 3.2.3 Branch 선택 규칙

| 사용자 유형 | "All" 옵션 | Branch 목록 |
|------------|-----------|------------|
| Company 또는 본사 직원 | 활성 | 회사의 모든 지점 |
| 지점 직원 | 비활성 | 해당 직원에게 할당된 지점만 |

#### 3.2.4 레이어 정렬 (Sort)

- "Sort layer" 버튼 클릭 시 팝업 표시
- **Title:** Sort approval layer
- **Table:** Layer no. (정렬 전), Layer no. (정렬 후 - 고정값 1,2,3...), Layer name
- 사용자가 드래그 또는 스왑으로 순서 변경 가능
- Layer no.는 정렬 후에도 순서대로 유지 (1, 2, 3...)

#### 3.2.5 Activity Log
- 레이어 변경 시 활동 로그 기록 (기존 방식과 동일)

---

### 3.3 Buy Order - 승인 요청 (Approval Request)

**전제조건:** Admin에서 "Multi-layer approval" 토글이 ON

#### 3.3.1 주문 생성 시 승인 요청

**경로:** Buy > Buy order > Create buy order / Buy > Favorite > Create order

| 경우 | 동작 |
|------|------|
| Approval layer = null (미설정) | 알림 팝업: "You have not configured a multi-layer approval. Please create an approval layer list to send the order to the approvers." / Cancel: 팝업 닫기 / OK: Approval setting 페이지로 이동 |
| Approval layer ≠ null | 주문 생성 후 1st 승인자에게 전송 |
| Excel import | Draft 상태로 생성 (승인 상태 없음) |

**다수 공급업체 처리:**
- Single supplier: 1 order → 1 request_id, 1 order_id → 1 이메일 + 1 웹링크
- Multiple suppliers: N orders → 1 request_id, N order_ids → 1 이메일 + 1 웹링크 (다수 주문 포함)

**참고:** Approve Order 권한이 없는 사용자도 주문을 생성하고 승인자에게 전송 가능

#### 3.3.2 주문 목록 (Buy Order List)

**All 탭:**
- Waiting for approval 알림 숨김 확인

**Draft 탭:**
- 설명 문구 변경: "Please select order(s) that need to be requested for approval"
- 각 행 끝 "…" 메뉴 아이콘 숨김
- **새 컬럼 추가:** "Approval status" (Status와 Amount 사이)
  - Values:
    - `-` : Draft 상태, 승인 요청 전
    - `Waiting` (Confirmed 색상): 승인 프로세스 진행 중
    - `Rejected` (Cancelled 색상): 승인 거절됨

**"Request for approval" 버튼 (기존 "Approve and send order" 대체):**
- 기본: 비활성
- Draft 주문 선택 시: 활성

| 선택 상태 | 동작 |
|----------|------|
| Layer = null | Use case 1.1 (미설정 알림) |
| 선택 주문 ≠ Waiting & ≠ Rejected | 확인 팝업: "Do you want to request approval for order(s)?" → Confirm 시 1st 승인자에게 전송 |
| 선택 주문 중 Waiting 또는 Rejected 포함 | 경고 팝업: 해당 주문 목록 표시 + "You cannot request approval for the following orders as they have been approved or are currently in the approval process." |

#### 3.3.3 주문 상세 - 액션 및 상태

| Approval Status | 가능한 액션 |
|----------------|-----------|
| `-` (미요청) | 기존 액션 + Request approval |
| Waiting | 액션 불가 |
| Denied/Rejected | 기존 액션 + Request approval (재요청) |
| Approved | → Unconfirmed 탭으로 이동 |

#### 3.3.4 주문 상세 - Approval Process 섹션

**위치:** Order status와 Order Amount 사이

**표시 정보:**
- 각 레이어별:
  - Approver: 이름 및 이메일 (이전/다음)
  - Action time
  - Status (Approved/Rejected/Waiting)
  - Note (승인 시 입력한 메모)

**Branch 연동:**
- Branch = "All": 회사 전체 지점의 승인자 표시
- Branch = 특정 지점: 해당 지점에 매핑된 승인자만 표시
- 레이어에 해당 지점 승인자 = 0명이면 해당 레이어 숨김

---

### 3.4 웹 기반 승인 처리 (기존 이메일 웹링크 → 웹 앱 내 구현)

> **핵심 변경:** 기존에는 이메일 → 웹링크에서 승인/거절했으나, 이제 웹 앱 내에서 직접 처리

#### 3.4.1 승인 요청 웹 페이지 (Approval Request Page)

**표시 정보:**
- Approval process (레이어별 승인 상태)
- Created at (요청 생성 시간)
- Order information (주문 정보)
- Product list (상품 목록)

**액션 버튼:**

| 버튼 | 동작 |
|------|------|
| Approve All | 전체 주문 승인 - 확인 팝업 표시 |
| Reject All | 전체 주문 거절 - 거절 사유 입력 팝업 (필수, 텍스트) |
| Approve (개별) | 개별 주문 승인 |
| Reject (개별) | 개별 주문 거절 |

**승인 시 Note 필드:**
- Label: Note
- 필수: NO
- 타입: Text
- Placeholder: "Enter note"

#### 3.4.2 승인 흐름

```
Requester 주문 생성
  → Layer 1 승인자에게 알림
    → Layer 1 승인 → Layer 2 승인자에게 알림
      → Layer 2 승인 → ... → Final Layer 승인
        → 주문 상태: Draft → Unconfirmed
        → 공급업체에게 전송
```

**승인 규칙:**
- 중간 레이어 승인 → 자동으로 다음 레이어에 알림
- 최종 레이어 승인 → Draft → Unconfirmed 상태 변경
- 거절 → 주문 상태: Draft (approval status 없음) + Rejected 표시 → 재요청 가능 (1st 레이어부터 재시작)
- 거절 시 거절 사유 필수 입력 (팝업, 텍스트 필드)

#### 3.4.3 승인 완료 후 재접근
- 이미 승인/거절된 요청에 재접근 시: 상세 정보 조회만 가능 (액션 불가)

---

### 3.5 상품 단위 부분 승인/거절 (Partial Approval by Product)

#### 3.5.1 상품 거절 (Rejecting Product)

**규칙:**
- 승인자는 주문 내 **특정 상품을 거절** 가능 (최소 1개 상품은 승인 필요)
- 단일 승인 요청에 다수 주문이 포함된 경우, **전체 주문 거절 불가** → 전체를 거절하려면 요청 자체를 거절해야 함
- 거절된 상품은 다음 레이어로 전달되기 전에 주문에서 제거

**예시:**
```
승인 요청: Order #1 (10 items) + Order #2 (3 items)
Layer 1: 전체 승인
Layer 2: Order #1에서 1개 상품 거절, 나머지 승인
  → Layer 3으로 전달: Order #1 (9 items) + Order #2 (3 items)
  → Requester와 Layer 1에게 거절 알림 발송
  → 거절된 상품은 필요 시 새 주문으로 재주문 가능
```

**전체 주문 거절 시:**
```
Layer 2: Order #2 전체 상품 거절
  → 해당 승인 요청 전체 거절됨
  → Requester가 Order #2를 삭제하고 Order #1만 재요청 가능
```

#### 3.5.2 주문 상세 & 이력 기록

거절된 상품에 대해:
- 주문 상세에서 해당 상품 제거 반영
- 주문 이력에 기록: `"{approver_name} ({approver_email}) (WEBLINK) removed the rejected item."`
- 색상: 빨간색

#### 3.5.3 거절 상품 이메일 알림

거절 발생 시 → Requester + 모든 이전 레이어 승인자에게 알림

---

### 3.6 수량 조정 (Adjust Quantity on Approval Request)

#### 3.6.1 수정 가능 필드

승인 웹 페이지에서 승인자가 직접 수정 가능:

| 필드 | 설명 |
|------|------|
| Qty (수량) | 수량 변경 가능 (Qty = 0이면 상품 제거와 동일) |
| Product note | 상품별 메모 추가/수정 |

**규칙:**
- Qty = 0 && Product note = NULL → Approve 버튼 비활성
- Qty 변경 시 → 주문 합계 섹션 자동 재계산
- Reject 시: 수량/메모 변경 무시 (원래 값 유지)
- Approve 시: 변경사항 저장 + 주문 이력 기록 + 이메일 알림

#### 3.6.2 주문 이력 기록

수정 발생 시:
- 설명: `"{approver_name} ({approver_email}) (WEBLINK) updated order"`
- 상세: `"Updated {number_of_edited_product} product(s)"`
- 색상: 빨간색
- "Show detail" 링크로 변경 전/후 확인 가능

#### 3.6.3 이메일 알림

수량/메모 변경 승인 시 → Requester + 모든 이전 레이어 승인자에게 업데이트 알림

---

### 3.7 알림 시스템 (Notification System)

> **웹 구현 시:** 이메일 알림은 유지하되, 웹 앱 내 **인앱 알림**도 추가

#### 3.7.1 승인 요청 알림 (다음 레이어로)

**트리거:** 이전 레이어 승인 완료 / 새 요청 생성
**수신자:** 다음 레이어 승인자 (해당 지점)
**이메일:**
- Sender: Oda - Order.so easy
- Subject: `You have new approval request (#{request_id}) from {staff_name}`
- Header: New approval request
- Body: `Hi {approver_name}, You have 1 new approval request from {staff_name}. Please review and take action on this request by clicking the link: {weblink}`

#### 3.7.2 거절 알림

**트리거:** 어떤 레이어에서든 거절 발생
**수신자:** Requester (staff email이 있는 경우) + 모든 이전 레이어 승인자
**이메일:**
- Subject: `Approval request (#{request_id}) has been rejected by {approver_name} ({approver_email})`
- Header: Approval request rejected
- Body: `Hi {name}, Approval request (#{request_id}) has been rejected by {approver_name} ({approver_email}) at YYYY-MM-DD HH:MM:SS. To view the details of this request, click the link: {weblink}`

#### 3.7.3 최종 승인 알림

**트리거:** 최종 레이어에서 승인 완료
**수신자:** Requester + 모든 승인자
**이메일:**
- Subject: `Approval request (#{request_id}) has been approved by {approver_name} ({approver_email})`
- Header: Approval request approved
- Body: 승인 시간 포함

**참고:** 기존 공급업체 이메일 알림은 유지

#### 3.7.4 이메일 언어
- Requester의 언어 설정 기준으로 이메일 발송

---

### 3.8 승인 요청 목록 (Approval Request List)

**경로:** Buy > Buy order > Approval request (서브 메뉴)

승인 요청 이력을 목록으로 관리:
- Request ID
- 요청 생성일
- 요청자
- 포함된 주문 목록
- 현재 승인 상태
- 현재 레이어

---

### 3.9 Migration (데이터 이관)

기존 승인자 데이터:
- 현재 승인자 → Branch = "All"로 자동 설정
- 기존 승인 프로세스 데이터 보존

---

## 4. 웹 구현 시 추가/변경 사항

### 4.1 이메일 웹링크 → 웹 앱 내 페이지 전환

| 기존 (이메일 기반) | 신규 (웹 기반) |
|-------------------|---------------|
| 이메일로 승인 요청 수신 | 웹 앱 내 알림 + 이메일 (병행) |
| 웹링크 클릭 → 외부 승인 페이지 | 웹 앱 내 승인 페이지로 네비게이션 |
| 웹링크 토큰 기반 인증 | 웹 앱 로그인 세션 기반 인증 |
| 만료 시간 있음 (기존과 동일) | 로그인 세션 유지 (만료 없음) |

### 4.2 인앱 알림 추가

- 웹 앱 내 알림 벨 아이콘에 승인 요청 알림 표시
- 실시간 알림 (WebSocket 또는 polling)
- 알림 클릭 시 해당 승인 요청 페이지로 이동

### 4.3 대시보드

- 승인 대기 중인 요청 수 표시
- 최근 승인/거절 이력 표시

---

## 5. 페이지/화면 목록 (Web Pages)

| # | 페이지 | 경로 | 사용자 |
|---|--------|------|--------|
| 1 | Admin - Multi-layer approval 설정 | Admin > Companies > Setting | Admin |
| 2 | Approval Setting (레이어 관리) | Settings > Approval setting | Company Staff |
| 3 | Sort Layer 팝업 | (Approval Setting 내) | Company Staff |
| 4 | Buy Order List - Draft 탭 | Buy > Buy order > Draft | Buyer |
| 5 | Buy Order Detail - Approval Process | Buy > Buy order > Detail | Buyer |
| 6 | Approval Request Page (승인 처리) | /approval/{request_id} | Approver |
| 7 | Approval Request List | Buy > Approval request | All |
| 8 | Reject Reason 팝업 | (Approval Request Page 내) | Approver |
| 9 | Approve with Note 팝업 | (Approval Request Page 내) | Approver |
| 10 | Qty/Note 편집 (인라인) | (Approval Request Page 내) | Approver |

---

## 6. API Endpoints (제안)

```
# Admin
PUT   /api/admin/companies/{id}/settings/multi-layer-approval

# Approval Setting
GET   /api/approval/layers
POST  /api/approval/layers
PUT   /api/approval/layers
PUT   /api/approval/layers/sort
DELETE /api/approval/layers/{layerId}

# Approval Request
POST  /api/approval/requests                    # 승인 요청 생성
GET   /api/approval/requests                    # 승인 요청 목록
GET   /api/approval/requests/{requestId}        # 승인 요청 상세
POST  /api/approval/requests/{requestId}/approve # 승인
POST  /api/approval/requests/{requestId}/reject  # 거절

# Product-level actions
POST  /api/approval/requests/{requestId}/orders/{orderId}/products/{productId}/reject  # 상품 거절
PUT   /api/approval/requests/{requestId}/orders/{orderId}/products/{productId}          # 수량/메모 수정

# Notifications
GET   /api/notifications/approval               # 승인 관련 알림 목록
```

---

## 7. 데이터 모델 (제안)

```
approval_settings
  - company_id
  - multi_layer_enabled (boolean)

approval_layers
  - id
  - company_id
  - layer_no (integer)
  - layer_name (string)
  - created_at, updated_at

approval_layer_approvers
  - id
  - layer_id
  - approver_name (string)
  - approver_email (string)
  - branch_id (nullable, null = "All")
  - created_at, updated_at

approval_requests
  - id (request_id)
  - company_id
  - requester_id
  - requester_name
  - requester_email
  - current_layer_no
  - status (waiting / approved / rejected)
  - created_at, updated_at

approval_request_orders
  - request_id
  - order_id

approval_actions
  - id
  - request_id
  - layer_no
  - approver_name
  - approver_email
  - action (approve / reject)
  - note (nullable)
  - rejected_reason (nullable)
  - action_at

approval_product_actions
  - id
  - action_id
  - order_id
  - product_id
  - action (approve / reject / edit)
  - original_qty
  - new_qty (nullable)
  - original_note
  - new_note (nullable)
  - rejection_reason (nullable)
```

---

## 8. 비기능 요구사항 (Non-Functional)

| 항목 | 요구사항 |
|------|---------|
| 성능 | 승인 페이지 로드 < 2초 |
| 보안 | 승인자 본인만 액션 가능 (세션 기반 인증) |
| 반응형 | Desktop + Mobile 지원 |
| 다국어 | ENG, VIE, KOR 3개 언어 지원 |
| 실시간성 | 승인 상태 변경 시 관련자에게 즉시 알림 |
| 호환성 | 기존 이메일 알림 유지 (웹 알림과 병행) |

---

## 9. Acceptance Criteria (인수 기준)

### 9.1 Admin 설정
- [ ] Multi-layer approval 토글 On/Off 가능
- [ ] 토글 변경 시 Toast 메시지 표시
- [ ] 3개 언어 지원

### 9.2 Approval Setting
- [ ] 레이어 생성/편집/삭제 가능
- [ ] 레이어 정렬 가능
- [ ] Branch 선택 가능 (Company Staff: All + 전체 지점 / Branch Staff: 할당 지점만)
- [ ] 승인자 추가/제거 가능
- [ ] Cancel: 변경사항 복원 / Save: 저장 + Toast

### 9.3 Buy Order - 승인 요청
- [ ] Layer 미설정 시 알림 팝업
- [ ] 주문 생성 시 자동 1st Layer 전송
- [ ] Draft 탭에 Approval status 컬럼 표시
- [ ] Request for approval 버튼 동작 (Waiting/Rejected 주문 경고)
- [ ] 승인 완료 시 Draft → Unconfirmed 상태 전환

### 9.4 승인 처리 (웹 페이지)
- [ ] Approve All / Reject All 동작
- [ ] 개별 주문 Approve / Reject 동작
- [ ] Approve 시 Note 입력 가능
- [ ] Reject 시 Reason 필수 입력
- [ ] 승인 완료 후 다음 레이어 자동 알림
- [ ] 이미 처리된 요청 재접근 시 조회만 가능

### 9.5 부분 승인
- [ ] 상품 단위 거절 가능 (최소 1개 승인 필요)
- [ ] 거절 상품 → 다음 레이어 전달 시 제거
- [ ] 주문 이력에 거절 기록
- [ ] 거절 알림 이메일 발송

### 9.6 수량 조정
- [ ] 승인 페이지에서 Qty 및 Product note 수정 가능
- [ ] Qty = 0 시 상품 제거 효과
- [ ] 변경 시 주문 합계 자동 재계산
- [ ] Reject 시 변경사항 무시
- [ ] 수정 이력 기록 및 알림 발송

### 9.7 알림
- [ ] 승인 요청 이메일 발송 (다음 레이어)
- [ ] 거절 이메일 발송 (Requester + 이전 레이어)
- [ ] 최종 승인 이메일 발송 (Requester + 전체 승인자)
- [ ] 웹 앱 내 인앱 알림 표시
- [ ] 이메일 언어 = Requester 언어 설정 기준

### 9.8 Migration
- [ ] 기존 승인자 → Branch = "All" 자동 설정
- [ ] 기존 데이터 무결성 보존

---

## 10. 개발 우선순위 (Implementation Phases)

### Phase 1 - 기본 설정 및 승인 흐름
1. Admin Multi-layer approval 토글 (3.1)
2. Approval Setting 페이지 (3.2)
3. Buy Order 승인 요청 (3.3)
4. 웹 기반 승인 처리 페이지 (3.4)

### Phase 2 - 지점별 승인 및 알림
5. Branch 선택 기능 (3.2.3)
6. 알림 시스템 - 이메일 + 인앱 (3.7)

### Phase 3 - 상품 단위 승인 및 수량 조정
7. 상품 단위 부분 승인/거절 (3.5)
8. 수량/메모 조정 (3.6)
9. 승인 요청 목록 (3.8)

### Phase 4 - Migration 및 QA
10. 데이터 Migration (3.9)
11. 통합 테스트 및 QA

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|----------|--------|
| 2026-02-25 | 1.0 | 초기 PRD 작성 (8개 문서 통합) | Mama |