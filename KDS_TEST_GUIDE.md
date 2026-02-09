# KDS (Kitchen Display System) 테스트 가이드

## 🎯 목적
주방 디스플레이 시스템(KDS)이 제대로 작동하는지 확인

---

## 📋 사전 준비

### 1. 앱 실행
```bash
cd /Users/JINLee/Documents/AI-coding/Odaai-POS/oda_pos
flutter run -d macos
```

### 2. 로그인
- **아이디**: `admin`
- **비밀번호**: `admin123`

---

## 🧪 테스트 시나리오

### ✅ Scenario 1: POS에서 주문 생성

#### Step 1-1: 상품 선택
1. POS 메인 화면에서 상품 카드 클릭
2. 장바구니에 상품 추가됨 확인
3. 여러 상품 추가 가능

#### Step 1-2: 결제 시작
1. 우측 장바구니에서 **"결제"** 버튼 클릭
2. Payment Modal 팝업 확인

#### Step 1-3: KDS 정보 입력 (NEW!)
결제 모달에서 아래 필드 확인 및 입력:

**📍 테이블 번호** (TextField)
- 예시: `테이블 5`, `Table 3`, `T-101`
- 선택사항 (비워두면 "포장" 주문으로 표시)

**📝 특별 지시사항** (TextField)
- 예시:
  - `매운맛 빼주세요`
  - `얼음 많이`
  - `포장해주세요`
- 선택사항

#### Step 1-4: 결제 완료
1. 결제 방법 선택 (현금/카드/QR/계좌이체)
2. 금액 확인
3. **"결제 완료"** 버튼 클릭
4. 영수증 화면으로 이동

**✅ 예상 결과**:
- 결제 성공 메시지
- KitchenOrder가 자동 생성됨 (백그라운드)

---

### ✅ Scenario 2: KDS 화면에서 주문 확인

#### Step 2-1: KDS 화면 접근
1. POS 상단 AppBar에서 **"주방"** 버튼 클릭
   - 위치: 우측 상단, 직원 정보 왼쪽
   - 아이콘: 🍽️ restaurant_menu
   - 색상: 주황색 테두리

2. KDS 화면으로 이동

#### Step 2-2: 주문 카드 확인
**주문 카드 구성**:
```
┌─────────────────────────┐
│ 테이블 5        🔴(긴급) │
│                          │
│ 🕐 14:30                 │
│ ⏱️ 3분 경과 (초록/노랑)  │
│                          │
│ [대기중] 🟠              │
│                          │
│ 📝 매운맛 빼주세요       │
└─────────────────────────┘
```

**필드 설명**:
- **테이블 번호**: 입력한 테이블 번호 (없으면 "포장 #ID")
- **긴급 아이콘**: 🔴 (urgent 주문인 경우)
- **주문 시간**: HH:mm 형식
- **경과 시간**:
  - 🟢 초록 (10분 미만)
  - 🟡 노랑 (10-20분)
  - 🟠 주황 (20-30분)
  - 🔴 빨강 (30분 이상)
- **상태**: PENDING(대기) / PREPARING(조리중) / READY(완료)
- **특별 지시사항**: 📝 (있을 경우만 표시)

#### Step 2-3: 필터 테스트
상단 필터 탭 클릭:
- **전체**: 모든 활성 주문
- **대기**: PENDING 주문만
- **조리중**: PREPARING 주문만
- **완료**: READY 주문만

---

### ✅ Scenario 3: 주문 상태 변경

#### Step 3-1: 주문 카드 클릭
1. 주문 카드 클릭
2. 하단에서 **주문 상세 모달** 팝업

#### Step 3-2: 주문 상세 확인
**모달 구성**:
```
┌───────────────────────────┐
│ 테이블 5            ✕     │
├───────────────────────────┤
│ 주문 시간: 2026-02-08 14:30
│ 상태: 대기중
│ 우선순위: 일반
│ 특별 요청: 매운맛 빼주세요
│
│ ━━ 처리 내역 ━━
│ ● 주문 접수  14:30:15
│ ○ 조리 시작  --:--:--
│ ○ 조리 완료  --:--:--
│ ○ 서빙 완료  --:--:--
│
├───────────────────────────┤
│ [취소] [조리 시작 →]      │
└───────────────────────────┘
```

#### Step 3-3: 상태 전환 테스트

**PENDING → PREPARING**
1. **"조리 시작"** 버튼 클릭
2. 모달 자동 닫힘
3. 주문 카드 상태 변경 확인: [조리중] 🔵

**PREPARING → READY**
1. 조리중 주문 카드 클릭
2. **"조리 완료"** 버튼 클릭
3. 상태 변경: [완료] 🟢
4. 🔔 **알림음 재생** (order_ready.mp3) - 파일 추가 시

**READY → SERVED**
1. 완료 주문 카드 클릭
2. **"서빙 완료"** 버튼 클릭
3. 주문 카드가 KDS 화면에서 사라짐

**상태 전환 규칙**:
- PENDING → PREPARING ✅
- PREPARING → READY ✅
- READY → SERVED ✅
- 완료된 주문은 되돌릴 수 없음 ❌

---

### ✅ Scenario 4: 통계 확인

#### Step 4-1: 성과 헤더 확인
KDS 화면 상단 우측:

```
✅ 완료: 12건  |  ⏳ 진행중: 3건  |  ⏱️ 평균: 8분 30초
```

- **완료**: 오늘 처리된 주문 수
- **진행중**: 현재 활성 주문 수 (PENDING + PREPARING + READY)
- **평균**: 평균 조리 시간 (STARTED → READY)

---

## 🔍 데이터베이스 직접 확인

### SQLite 데이터 조회
```bash
# 데이터베이스 경로 찾기
find ~/Library/Containers -name "oda_pos.db" 2>/dev/null

# 또는 일반 경로
sqlite3 ~/Library/Application\ Support/com.example.odaPos/oda_pos.db
```

### SQL 쿼리
```sql
-- 모든 주방 주문 확인
SELECT * FROM kitchen_orders ORDER BY created_at DESC LIMIT 10;

-- 활성 주문만
SELECT * FROM kitchen_orders
WHERE status IN ('PENDING', 'PREPARING', 'READY')
ORDER BY created_at DESC;

-- 주문과 판매 정보 조인
SELECT
  ko.id,
  ko.table_number,
  ko.status,
  ko.created_at,
  s.total
FROM kitchen_orders ko
JOIN sales s ON ko.sale_id = s.id
ORDER BY ko.created_at DESC;
```

---

## 🐛 문제 해결

### 문제 1: "주방" 버튼이 안 보여요
**원인**: pos_main_screen.dart 임포트 누락
**해결**:
```dart
// lib/features/pos/presentation/screens/pos_main_screen.dart
import '../../../kds/presentation/screens/kds_screen.dart';
```

### 문제 2: 결제해도 KDS에 주문이 안 뜨요
**원인**: payment_modal에서 파라미터 미전달
**확인 사항**:
```dart
await salesDao.createSale(
  // ... 기존 코드 ...
  tableNumber: _tableNumberController.text.trim(),  // ← 이 줄 있는지 확인
  specialInstructions: _specialInstructionsController.text.trim(),  // ← 이 줄 있는지 확인
);
```

### 문제 3: 알림음이 안 나요
**원인**: MP3 파일 누락
**해결**:
1. `assets/sounds/` 폴더로 이동
2. 아래 파일 추가:
   - `new_order.mp3`
   - `urgent_order.mp3`
   - `order_ready.mp3`
3. 무료 다운로드: Freesound.org, Mixkit.co

### 문제 4: 한글이 깨져요
**원인**: l10n 적용 안됨
**해결**:
```bash
flutter gen-l10n
flutter run
```

---

## ✅ 체크리스트

### 기본 동작
- [ ] POS에서 상품 선택 및 장바구니 추가
- [ ] 결제 모달에서 테이블 번호 입력란 확인
- [ ] 결제 모달에서 특별 지시사항 입력란 확인
- [ ] 결제 완료 시 에러 없음
- [ ] "주방" 버튼 클릭 시 KDS 화면 이동

### KDS 화면
- [ ] 주문 카드 표시됨 (테이블 번호, 시간, 상태)
- [ ] 경과 시간 색상 변경 (초록→노랑→주황→빨강)
- [ ] 필터 탭 동작 (전체/대기/조리중/완료)
- [ ] 성과 헤더 통계 표시

### 상태 전환
- [ ] "조리 시작" 버튼으로 PREPARING 전환
- [ ] "조리 완료" 버튼으로 READY 전환
- [ ] "서빙 완료" 버튼으로 SERVED 전환 및 카드 사라짐
- [ ] 타임라인 업데이트 (시작 시간, 완료 시간 기록)

### 고급 기능
- [ ] 긴급 주문 표시 (빨간 테두리, 아이콘)
- [ ] 특별 지시사항 표시 (노란 배경)
- [ ] 실시간 업데이트 (Stream)
- [ ] 빈 상태 메시지 ("주문이 없습니다")

---

## 📊 성능 지표

### 목표 KPI
- **주문 처리 시간**: < 15분
- **경과 시간 정확도**: ±1초
- **UI 반응성**: < 100ms (터치 → 화면 전환)
- **실시간 업데이트**: < 2초 (POS 결제 → KDS 표시)

### 측정 방법
1. POS에서 결제 완료 시간 기록
2. KDS 화면에 주문 표시 시간 확인
3. 차이가 2초 이내인지 확인

---

## 🎥 데모 시나리오

### 시나리오: 카페 매장 시뮬레이션

**상황**: 손님 3명이 동시에 주문

**주문 1** (테이블 3)
- 상품: 아메리카노 x2
- 특별 지시사항: "얼음 많이"
- 우선순위: 일반

**주문 2** (테이블 5)
- 상품: 카페라떼 x1, 샌드위치 x1
- 특별 지시사항: "토스트 약하게"
- 우선순위: 긴급 (VIP 고객)

**주문 3** (포장)
- 상품: 녹차라떼 x3
- 테이블 번호: (비워둠)
- 특별 지시사항: 없음

**진행 순서**:
1. POS에서 3건 연속 결제
2. KDS 화면에서 3개 카드 확인
3. 긴급 주문(테이블 5) 먼저 처리
4. 나머지 순서대로 처리
5. 모든 주문 SERVED 전환
6. 통계 확인: "완료 3건"

---

## 📸 스크린샷 위치

테스트 완료 후 스크린샷 저장:
```
docs/screenshots/kds/
├── 01-pos-payment-modal.png      # 테이블 번호 입력
├── 02-kds-main-screen.png         # KDS 메인 화면
├── 03-order-card-detail.png       # 주문 상세 모달
├── 04-status-transition.png       # 상태 전환
└── 05-performance-stats.png       # 성과 통계
```

---

## 🚀 다음 단계

테스트 완료 후:

1. ✅ **Pass**: `/pdca report kds` 실행하여 완료 보고서 생성
2. ❌ **Fail**: 이슈 기록 후 수정

---

**작성일**: 2026-02-08
**버전**: v1.0.0
**Match Rate**: 93%
