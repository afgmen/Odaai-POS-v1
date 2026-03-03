# Multi-Layer Approval System - 구현 리뷰 보고서

> 작성자: Mama (PM/QC)  
> 작성일: 2026-02-25  
> 대상: `odaai-approval.zip` (직원 구현물)  
> 비교 기준: 8개 원본 기능 명세서 (PDF)  

---

## 1. 요약 (Executive Summary)

전체적으로 잘 구현된 프로젝트입니다. 8개 문서의 핵심 기능을 대부분 커버하고 있으며, 기술 스택 선정(Next.js 14 + Laravel + MySQL)도 적절합니다. 그러나 **원본 명세서와 비교 시 일부 누락/차이점**이 있어 보완이 필요합니다.

### 종합 점수: ⭐⭐⭐⭐ (4/5)

| 항목 | 점수 | 비고 |
|------|------|------|
| 기능 완성도 | ⭐⭐⭐⭐ | 핵심 흐름 구현됨, 세부 사항 일부 누락 |
| 코드 품질 | ⭐⭐⭐⭐ | 구조화 잘됨, 서비스 레이어 분리 |
| 문서화 | ⭐⭐⭐⭐⭐ | 매우 상세한 문서 (README, SETUP 등) |
| 원본 명세 충실도 | ⭐⭐⭐ | 주요 차이점 있음 (아래 상세) |
| i18n | ⭐⭐⭐⭐ | 3개 언어 지원 |
| 테스트 | ⭐⭐ | 테스트 코드 없음 |

---

## 2. 기능별 비교 분석

### ✅ Doc 1: Admin Multi-Layer Approval 토글 (OFA)

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| Company Setting에 Multi-layer approval 토글 | ⚠️ 부분 구현 | `approval_settings.is_enabled`로 구현되었으나, **Branch 단위**로 설정 (원본은 **Company 단위**) |
| 토글 위치: Profit setting 아래 | ❌ 미반영 | Admin 별도 페이지 없음 (Settings에 통합) |
| 기본값: Off | ✅ 구현됨 | `is_enabled` default false |
| Toast 메시지 | ❌ 미구현 | "Multi-layer approval settings updated successfully." Toast 없음 |
| On/Off에 따른 UI 분기 | ⚠️ 부분 | 토글은 있으나, Off 시 기존 단일 승인으로 fallback 미구현 |

**🔴 주요 차이:** 원본에서는 **Admin(OFA) 레벨**에서 회사 단위로 토글 설정하는데, 구현물에서는 **Branch 단위 Approval Setting**으로 변경됨. 이 설계 차이가 의도적인지 확인 필요.

---

### ✅ Doc 2: Approval Setting (레이어 관리)

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| Approval layer list CRUD | ✅ 구현됨 | Create/Delete 구현 |
| Layer name 필수 | ✅ 구현됨 | |
| Layer no 자동 생성 | ✅ 구현됨 | `layer_number` auto-increment |
| 승인자 추가/제거 (+/-) | ✅ 구현됨 | `addApprover`/`removeApprover` |
| Sort layer (정렬 팝업) | ❌ 미구현 | 원본에 있는 "Sort approval layer" 팝업 미구현 |
| Cancel 버튼 (Undo all) | ❌ 미구현 | 변경 즉시 API 호출, 원본은 Save 전까지 로컬 변경 |
| Save 버튼 (일괄 저장) | ❌ 미구현 | 같은 이유 - 실시간 저장 방식으로 변경됨 |
| Activity log | ❌ 미구현 | 레이어 변경 로그 없음 |
| 1 layer - many approvers 규칙 | ✅ 구현됨 | 한 명 승인 시 다음 레이어 이동 |
| 승인자 name + email 입력 | ⚠️ 차이 | 원본은 **이름+이메일 직접 입력**, 구현물은 **시스템 User 선택** |

**🔴 주요 차이:**
1. **저장 방식:** 원본은 "변경 후 Save 클릭" 패턴인데, 구현물은 각 액션마다 즉시 API 호출. 원본의 Cancel/Undo 기능 사용 불가.
2. **승인자 등록:** 원본은 외부 사람의 이름+이메일을 직접 입력하는 방식인데, 구현물은 시스템 내 User만 선택 가능. 이는 **원본 명세서의 핵심 설계와 다름** (이메일 기반 외부 승인자 지원 불가).

---

### ✅ Doc 3: Buy Order - Approval Request

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| Layer = null 시 알림 팝업 | ❌ 미구현 | "Approval layer를 먼저 설정하세요" 팝업 없음 |
| 주문 생성 시 자동 1st Layer 전송 | ✅ 구현됨 | `ApprovalService::createApprovalRequest` |
| Draft 탭 Approval status 컬럼 | ⚠️ 부분 | 주문 목록에 status 있으나, 원본의 별도 "Approval status" 컬럼 구분 미흡 |
| "Request for approval" 버튼 | ❌ 미구현 | 원본의 Draft 탭에서 다수 주문 선택 후 일괄 승인 요청 기능 없음 |
| 다수 공급업체 → 1 request, N orders | ❌ 미구현 | 현재 1 order = 1 request 관계. 원본은 1 request에 여러 order 가능 |
| Waiting/Rejected 주문 경고 팝업 | ❌ 미구현 | |
| Excel import → Draft without approval | ❌ 미구현 | Excel import 기능 자체 없음 |
| "Got it" 팝업 (주문 생성 성공) | ❌ 미구현 | |

**🔴 주요 차이:**
1. **1 Request - Many Orders:** 원본의 핵심 설계에서 1 request_id가 여러 order_id를 그룹핑하는데, 구현물은 1:1 관계. **이는 구조적 차이로, DB 스키마 변경이 필요.**
2. **Draft 탭 일괄 승인 요청:** 원본에서 여러 Draft 주문을 선택하고 일괄 "Request for approval"하는 기능이 없음.

---

### ✅ Doc 4: 웹 기반 승인 처리 (Email Template → Web)

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| 이메일 알림 발송 | ⚠️ 부분 | NotificationService에 구조는 있으나, 실제 이메일 발송 (SMTP) 미구현 (DB 알림만) |
| 웹링크 토큰 기반 접근 | ❌ 미구현 | 원본의 `?token=XXX&email=YYY` 방식 웹링크 없음 |
| Approve All / Reject All | ✅ 구현됨 | |
| 거절 사유 필수 입력 | ✅ 구현됨 | Reject Modal + reason required |
| 이메일 Subject/Header/Body 템플릿 | ❌ 미구현 | 원본의 상세 이메일 템플릿 미구현 |
| 만료 시간 (기존과 동일) | ❌ 미구현 | |
| 승인/거절 후 재접근 시 조회만 | ✅ 구현됨 | `canApprove` 플래그로 제어 |

**🟡 참고:** 이메일 → 웹 전환이 이 프로젝트의 핵심 목표인데, 이메일 알림 자체는 유지해야 하는 것으로 원본에 명시되어 있음. 현재 DB 내부 알림만 구현됨.

---

### ✅ Doc 5: Branch 선택 (승인자별 지점 매핑)

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| 승인자에 Branch 필드 추가 | ⚠️ 차이 | 구현물은 `approval_settings`가 Branch 단위, 원본은 **승인자 개인에 Branch 매핑** |
| "All" 기본 선택 | ❌ 미구현 | 원본의 "All branches" 옵션 없음 |
| Company Staff: All + 전체 지점 | ❌ 미구현 | |
| Branch Staff: 할당 지점만 | ❌ 미구현 | |
| 해당 지점 승인자 0명이면 레이어 숨김 | ❌ 미구현 | |
| Migration: 기존 → Branch "All" | ❌ 미구현 | |

**🔴 주요 차이:** 원본에서는 **같은 레이어 내에서 승인자마다 다른 Branch를 선택**할 수 있음. 예: Layer 1에 "Approver A - Branch All", "Approver B - Branch 1", "Approver C - Branch 2". 구현물은 이 개념이 없고 approval_setting 자체가 Branch 단위. **이것은 데이터 모델 레벨의 차이.**

---

### ✅ Doc 6: 거절/승인 이메일 알림

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| 거절 시 Requester + 이전 레이어에 알림 | ⚠️ 부분 | `notifyRequester` 구현됨, `notifyPreviousApprovers` 메서드 존재하나 호출 미확인 |
| 최종 승인 시 Requester + 전체 승인자에 알림 | ⚠️ 부분 | `finalizeOrder`에서 requester만 알림 |
| 이메일 언어 = Requester 언어 | ❌ 미구현 | User에 `lang` 필드는 있으나 알림 시 미활용 |
| 상세 이메일 템플릿 (Subject, Header, Body) | ❌ 미구현 | |

---

### ✅ Doc 7: 상품 단위 부분 승인/거절

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| 상품별 Approve/Reject | ✅ 구현됨 | `ApprovalRequestItemController` |
| 최소 1개 승인 필요 | ❌ 미구현 | 전체 거절도 가능 (원본은 상품 단위에서 전체 거절 불가) |
| 거절 상품 → 다음 레이어에서 제거 | ⚠️ 부분 | Item status가 rejected로 변경되나, 다음 레이어 전달 시 명시적 제거 로직 미확인 |
| Approve 시 Note 입력 | ✅ 구현됨 | reason 파라미터 (optional) |
| 주문 이력 기록 (빨간색) | ❌ 미구현 | Audit trail은 있으나 원본의 UI 요구사항(빨간색, 상세보기 링크) 미구현 |
| 거절 상품 알림 (Requester + 이전 레이어) | ⚠️ 부분 | Requester만 알림 |

---

### ✅ Doc 8: 수량 조정 (Adjust Qty)

| 원본 요구사항 | 구현 상태 | 비고 |
|-------------|----------|------|
| Qty 수정 가능 | ✅ 구현됨 | `adjustQty` API + 프론트엔드 Modal |
| Product note 수정 가능 | ❌ 미구현 | Qty만 조정 가능, Product note 수정 불가 |
| Qty = 0 → 상품 제거 효과 | ❌ 미구현 | min: 0이지만 제거 로직 없음 |
| Qty = 0 && Note = null → Approve 비활성 | ❌ 미구현 | |
| 주문 합계 자동 재계산 | ❌ 미구현 | Qty 변경 시 total_amount 미업데이트 |
| Reject 시 변경사항 무시 | ✅ 구현됨 | Reject은 별도 흐름 |
| 주문 이력 기록 (빨간색, Show detail) | ❌ 미구현 | |
| 수정 알림 (Requester + 이전 레이어) | ⚠️ 부분 | Requester만 |

---

## 3. 아키텍처/설계 차이점

### 3.1 데이터 모델 차이

| 항목 | 원본 명세 | 구현물 | 영향도 |
|------|----------|--------|--------|
| Approval Request - Order 관계 | 1:N (1 request → many orders) | 1:1 | 🔴 높음 |
| 승인자 등록 방식 | 이름+이메일 직접 입력 (외부인 가능) | 시스템 User 선택만 | 🔴 높음 |
| Branch-Approver 매핑 | 승인자 레코드에 branch_id | approval_setting에 branch_id | 🟡 중간 |
| Approval Setting 단위 | Company (Admin에서 설정) | Branch | 🟡 중간 |

### 3.2 구현물에서 추가된 기능 (원본에 없음)

| 기능 | 설명 | 평가 |
|------|------|------|
| `min_amount_threshold` | 최소 금액 기준 자동 승인 트리거 | ✅ 좋은 추가 |
| Branch Management 페이지 | 지점 CRUD | ✅ 필요한 기능 |
| User Management | 사용자 CRUD | ✅ 필요한 기능 |
| Dashboard 페이지 | 대시보드 통계 | ✅ 좋은 추가 |
| Health Check API | 서버 상태 확인 | ✅ 운영에 필요 |

---

## 4. 코드 품질 리뷰

### 4.1 백엔드 (Laravel)

**장점:**
- ✅ Service Layer 패턴 (ApprovalService, NotificationService) - 비즈니스 로직 분리 우수
- ✅ Eloquent Relationships 적절히 활용
- ✅ Migration으로 스키마 관리
- ✅ RESTful API 설계
- ✅ Sanctum 인증

**개선 필요:**
- ❌ Request Validation 클래스 없음 (FormRequest 미사용)
- ❌ Policy/Gate 미구현 (권한 체크 부족)
- ❌ 테스트 코드 없음
- ❌ Exception Handling 전략 미흡 (generic try-catch)
- ❌ Transaction 미사용 (승인 처리 시 데이터 정합성 위험)
- ⚠️ `approval_layer_approvers`에 `branch_id` 컬럼 없음

### 4.2 프론트엔드 (Next.js)

**장점:**
- ✅ TypeScript 전면 사용
- ✅ App Router (최신 패턴)
- ✅ 컴포넌트 분리 (Layout, Modal, DataTable, StatusBadge, ApprovalTimeline)
- ✅ i18n 지원 (en, vi, ko)
- ✅ Tailwind CSS 활용
- ✅ Mock API로 프론트엔드 독립 개발 가능

**개선 필요:**
- ❌ 상태 관리 라이브러리 없음 (대규모 시 복잡해질 수 있음)
- ❌ `localStorage`에서 직접 user 읽는 패턴 (auth-context 대신)
- ❌ Error boundary 미구현
- ❌ Loading skeleton 미구현
- ⚠️ Sort layer 기능 미구현
- ⚠️ 페이지 간 데이터 갱신 전략 미흡

---

## 5. 누락된 기능 요약 (우선순위별)

### 🔴 P0 - 반드시 수정 필요

1. **1 Request - Many Orders 구조 변경**
   - 현재: `approval_requests` → `order_id` (1:1)
   - 필요: `approval_request_orders` 중간 테이블 (M:N)
   - 영향: DB 스키마, Service, Controller, Frontend 전체

2. **승인자 등록 방식 변경**
   - 현재: 시스템 User 선택
   - 필요: 이름+이메일 직접 입력 (외부 승인자 지원)
   - `approval_layer_approvers`에 `approver_name`, `approver_email`, `branch_id` 추가

3. **Branch-Approver 매핑**
   - 현재: approval_setting이 branch 단위
   - 필요: 승인자 레코드에 branch 매핑 (같은 레이어에서 승인자마다 다른 branch)

### 🟡 P1 - 조기 보완 필요

4. **Sort Layer 기능** - 레이어 순서 변경 팝업
5. **Draft 탭 일괄 승인 요청** - 다수 주문 선택 → Request for approval
6. **Layer 미설정 시 알림 팝업** - Redirect to Approval Setting
7. **이메일 알림 실제 발송** (SMTP 연동)
8. **주문 합계 재계산** (Qty 변경 시)
9. **이전 레이어 승인자에게도 알림** (거절/최종승인 시)
10. **Product note 수정 기능**

### 🟢 P2 - 추후 보완

11. Cancel/Save 일괄 저장 패턴 (Approval Setting)
12. Activity Log (레이어 변경 이력)
13. 이메일 템플릿 (Subject, Header, Body)
14. 이메일 언어 = Requester 언어
15. 주문 이력 UI (빨간색, Show detail)
16. Waiting/Rejected 주문 경고 팝업
17. Transaction 적용 (데이터 정합성)
18. 테스트 코드 작성

---

## 6. 결론 및 권장 사항

### 잘 된 점 👍
- 전체적인 프로젝트 구조가 깔끔하고 확장 가능
- 문서화가 매우 상세함
- 핵심 승인 흐름 (Layer 1 → 2 → ... → Final) 정상 구현
- 상품 단위 승인/거절/수량 조정 기본 구조 구현
- i18n 3개 언어 지원
- Mock API로 프론트엔드 독립 개발 환경 구축

### 보완 필요 ⚠️
- **데이터 모델 수정 필수**: 1 Request - Many Orders, 승인자 Branch 매핑
- **원본 명세의 세부 UX 반영**: 팝업, Toast, 경고 메시지 등
- **이메일 알림 실제 구현**: 현재 DB 알림만 있음
- **Transaction/Validation 강화**: 데이터 정합성 및 보안

### 다음 단계 제안
1. P0 이슈 3개 먼저 DB 스키마 수정
2. P1 기능 순차 구현
3. 이메일 SMTP 연동
4. 단위/통합 테스트 작성
5. P2 세부 UX 보완

---

*이 리뷰는 8개 원본 PDF 명세서와 구현물의 소스 코드를 직접 비교 분석한 결과입니다.*
