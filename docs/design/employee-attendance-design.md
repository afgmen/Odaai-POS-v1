# 직원 근태 관리 시스템 설계서

## 1. 개요

### 목적
직원의 출퇴근 기록, 근무 시간 추적, 휴가 관리를 자동화하여 근태 관리를 효율화합니다.

### 주요 기능
- 출퇴근 체크인/체크아웃
- 근무 시간 자동 계산 (정규/연장/야간)
- 휴가 신청 및 승인 워크플로우
- 근무 스케줄 관리
- 근태 통계 및 리포트
- 지각/조퇴/결근 자동 탐지

---

## 2. 데이터베이스 설계

### 2.1 출퇴근 기록 테이블 (attendance_logs)

```dart
class AttendanceLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 직원 정보
  IntColumn get employeeId => integer().named('employee_id')
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 날짜 및 시간
  DateTimeColumn get workDate => dateTime().named('work_date')(); // 근무일
  DateTimeColumn get checkInTime => dateTime().named('check_in_time')(); // 출근 시간
  DateTimeColumn get checkOutTime => dateTime().nullable().named('check_out_time')(); // 퇴근 시간

  // 근무 시간 (분 단위)
  IntColumn get totalMinutes => integer().nullable().named('total_minutes')(); // 총 근무 시간
  IntColumn get regularMinutes => integer().nullable().named('regular_minutes')(); // 정규 근무
  IntColumn get overtimeMinutes => integer().nullable().named('overtime_minutes')(); // 연장 근무
  IntColumn get nightMinutes => integer().nullable().named('night_minutes')(); // 야간 근무

  // 상태 및 플래그
  TextColumn get status => text()(); // 'working' | 'completed' | 'absent' | 'late' | 'early_leave'
  BoolColumn get isLate => boolean().named('is_late').withDefault(const Constant(false))();
  BoolColumn get isEarlyLeave => boolean().named('is_early_leave').withDefault(const Constant(false))();

  // 메모 및 위치
  TextColumn get checkInNote => text().nullable().named('check_in_note')();
  TextColumn get checkOutNote => text().nullable().named('check_out_note')();
  TextColumn get location => text().nullable()(); // GPS 좌표 또는 위치명

  // 승인 정보
  IntColumn get approvedBy => integer().nullable().named('approved_by')();
  DateTimeColumn get approvedAt => dateTime().nullable().named('approved_at')();

  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}
```

### 2.2 휴가 신청 테이블 (leave_requests)

```dart
class LeaveRequests extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 직원 정보
  IntColumn get employeeId => integer().named('employee_id')
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 휴가 정보
  TextColumn get leaveType => text().named('leave_type')();
  // 'annual' | 'sick' | 'personal' | 'maternity' | 'paternity' | 'unpaid'

  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().named('end_date')();
  RealColumn get days => real()(); // 휴가 일수 (0.5일 단위)

  TextColumn get reason => text()();
  TextColumn get attachments => text().nullable()(); // JSON array of file paths

  // 승인 워크플로우
  TextColumn get status => text();
  // 'pending' | 'approved' | 'rejected' | 'cancelled'

  IntColumn get reviewedBy => integer().nullable().named('reviewed_by')();
  DateTimeColumn get reviewedAt => dateTime().nullable().named('reviewed_at')();
  TextColumn get reviewNote => text().nullable().named('review_note')();

  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}
```

### 2.3 근무 스케줄 테이블 (work_schedules)

```dart
class WorkSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 직원 정보
  IntColumn get employeeId => integer().named('employee_id')
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 스케줄 정보
  IntColumn get dayOfWeek => integer().named('day_of_week')(); // 0=일요일, 6=토요일
  TextColumn get shiftType => text().named('shift_type')(); // 'day' | 'night' | 'off'

  // 근무 시간
  TextColumn get startTime => text().named('start_time')(); // HH:mm 형식
  TextColumn get endTime => text().named('end_time')(); // HH:mm 형식
  IntColumn get plannedMinutes => integer().named('planned_minutes')(); // 계획된 근무 시간

  // 유효 기간
  DateTimeColumn get effectiveFrom => dateTime().named('effective_from')();
  DateTimeColumn get effectiveTo => dateTime().nullable().named('effective_to')();

  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
}
```

### 2.4 휴가 잔여 테이블 (leave_balances)

```dart
class LeaveBalances extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get employeeId => integer().named('employee_id')
      .unique()
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 연차
  RealColumn get annualTotal => real().named('annual_total')(); // 총 연차 일수
  RealColumn get annualUsed => real().named('annual_used')(); // 사용한 연차
  RealColumn get annualRemaining => real().named('annual_remaining')(); // 남은 연차

  // 병가
  RealColumn get sickTotal => real().named('sick_total')();
  RealColumn get sickUsed => real().named('sick_used')();
  RealColumn get sickRemaining => real().named('sick_remaining')();

  // 기타
  RealColumn get personalTotal => real().named('personal_total')();
  RealColumn get personalUsed => real().named('personal_used')();
  RealColumn get personalRemaining => real().named('personal_remaining')();

  // 연도 정보
  IntColumn get year => integer()();

  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
}
```

---

## 3. 비즈니스 로직

### 3.1 출퇴근 처리

#### 체크인 프로세스
```
1. 현재 시간 기록
2. 당일 스케줄 조회
3. 지각 여부 판단 (스케줄 시작 시간 + 15분 초과)
4. attendance_logs 레코드 생성 (status: 'working')
5. 알림 발송 (관리자에게)
```

#### 체크아웃 프로세스
```
1. 현재 시간 기록
2. 총 근무 시간 계산
3. 조퇴 여부 판단 (스케줄 종료 시간 - 30분 미만)
4. 근무 시간 분류:
   - 정규 근무: 스케줄 기준 시간
   - 연장 근무: 스케줄 종료 후 시간
   - 야간 근무: 22시 ~ 06시 사이 시간
5. attendance_logs 업데이트 (status: 'completed')
6. 통계 업데이트
```

### 3.2 휴가 관리

#### 휴가 신청 워크플로우
```
1. 직원이 휴가 신청 (날짜, 사유, 유형)
2. 휴가 잔여일 확인
3. 중복 신청 방지 (같은 기간에 다른 신청 존재 여부)
4. leave_requests 생성 (status: 'pending')
5. 관리자에게 승인 요청 알림
```

#### 휴가 승인 프로세스
```
1. 관리자가 승인/거절 결정
2. status 업데이트
3. 승인 시:
   - leave_balances에서 일수 차감
   - 해당 기간 attendance_logs에 'absent' 상태로 자동 생성
4. 직원에게 결과 알림
```

### 3.3 근무 시간 계산 규칙

```dart
class WorkTimeCalculator {
  // 정규 근무: 스케줄 기준 시간 (최대 8시간)
  // 연장 근무: 정규 시간 초과 근무
  // 야간 근무: 22:00 ~ 06:00 사이 근무 시간

  static WorkTimeBreakdown calculate({
    required DateTime checkIn,
    required DateTime checkOut,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) {
    // 구현 로직
  }
}
```

### 3.4 자동화 로직

#### 일일 자동 처리 (매일 자정)
```
1. 전날 미체크아웃 직원 탐지
   → 스케줄 종료 시간으로 자동 체크아웃 + 플래그 표시
2. 당일 휴가자 확인
   → attendance_logs에 'absent' 레코드 생성
3. 결근자 탐지
   → 스케줄 있으나 체크인 없는 직원
```

#### 월말 처리
```
1. 월간 근무 통계 집계
2. 연차 자동 부여 (근속 기간 기준)
3. 미사용 연차 이월 처리
```

---

## 4. API 설계

### 4.1 AttendanceDao

```dart
class AttendanceDao {
  // 출퇴근 기록
  Future<int> checkIn(AttendanceLogsCompanion entry);
  Future<bool> checkOut(int employeeId, DateTime checkOutTime, String? note);
  Future<AttendanceLog?> getTodayAttendance(int employeeId);
  Future<bool> isAlreadyCheckedIn(int employeeId, DateTime date);

  // 조회
  Future<List<AttendanceLog>> getAttendanceByDateRange(
    int employeeId, DateTime start, DateTime end
  );
  Future<List<AttendanceLog>> getAttendanceByMonth(int employeeId, int year, int month);
  Stream<List<AttendanceLog>> watchRecentAttendance(int employeeId, {int limit = 30});

  // 통계
  Future<int> getTotalWorkMinutesThisMonth(int employeeId);
  Future<int> getOvertimeMinutesThisMonth(int employeeId);
  Future<Map<String, int>> getAttendanceStatsByStatus(int employeeId, int year, int month);

  // 휴가 관리
  Future<int> createLeaveRequest(LeaveRequestsCompanion entry);
  Future<bool> updateLeaveRequestStatus(int requestId, String status, int reviewerId, String? note);
  Future<List<LeaveRequest>> getPendingLeaveRequests();
  Future<LeaveBalance?> getLeaveBalance(int employeeId, int year);
  Future<bool> updateLeaveBalance(int employeeId, String leaveType, double days);

  // 스케줄
  Future<int> createWorkSchedule(WorkSchedulesCompanion entry);
  Future<WorkSchedule?> getScheduleForDate(int employeeId, DateTime date);
  Future<List<WorkSchedule>> getActiveSchedules(int employeeId);
}
```

### 4.2 AttendanceService

```dart
class AttendanceService {
  // 출퇴근
  Future<CheckInResult> checkIn(int employeeId, {String? note, String? location});
  Future<CheckOutResult> checkOut(int employeeId, {String? note});

  // 근무 시간 계산
  WorkTimeBreakdown calculateWorkTime(AttendanceLog log, WorkSchedule schedule);
  bool isLate(DateTime checkIn, DateTime scheduledStart);
  bool isEarlyLeave(DateTime checkOut, DateTime scheduledEnd);

  // 휴가
  Future<LeaveRequestResult> requestLeave({
    required int employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  });
  Future<bool> approveLeave(int requestId, int approverId, {String? note});
  Future<bool> rejectLeave(int requestId, int approverId, {String? note});

  // 통계 및 리포트
  Future<MonthlyAttendanceReport> getMonthlyReport(int employeeId, int year, int month);
  Future<List<AttendanceLog>> getLateEmployees(DateTime date);
  Future<List<AttendanceLog>> getAbsentEmployees(DateTime date);

  // 자동화
  Future<void> autoCheckOutMissing(); // 미체크아웃 자동 처리
  Future<void> processAbsentees(); // 결근 처리
  Future<void> createAbsentLogsForLeaves(); // 휴가자 absent 로그 생성
}
```

---

## 5. UI/UX 설계

### 5.1 직원용 화면

#### 체크인/체크아웃 화면 (`attendance_check_screen.dart`)
```
┌─────────────────────────────────┐
│ [프로필 사진] 홍길동님          │
│                                 │
│  현재 상태: 출근 전             │
│  오늘 스케줄: 09:00 ~ 18:00     │
│                                 │
│  ┌─────────────────────────┐   │
│  │    [출근하기] 버튼      │   │
│  └─────────────────────────┘   │
│                                 │
│  메모 (선택): _______________   │
│                                 │
│  이번 달 근무 통계:             │
│  • 총 근무: 160시간             │
│  • 연장: 10시간                 │
│  • 지각: 2회                    │
└─────────────────────────────────┘
```

#### 근태 기록 화면 (`attendance_history_screen.dart`)
```
┌─────────────────────────────────┐
│ 근태 기록      [2024년 2월 ▼]   │
├─────────────────────────────────┤
│ 2024-02-07 (수)                 │
│ 출근: 09:05   퇴근: 18:30       │
│ 근무: 8시간 25분 [지각]         │
├─────────────────────────────────┤
│ 2024-02-06 (화)                 │
│ 출근: 08:55   퇴근: 19:00       │
│ 근무: 9시간 5분 [연장 1시간]    │
├─────────────────────────────────┤
│ 2024-02-05 (월)                 │
│ 연차 휴가                       │
└─────────────────────────────────┘
```

#### 휴가 신청 화면 (`leave_request_screen.dart`)
```
┌─────────────────────────────────┐
│ 휴가 신청                       │
├─────────────────────────────────┤
│ 휴가 유형: [연차 ▼]             │
│                                 │
│ 시작일: [2024-02-10]            │
│ 종료일: [2024-02-12]            │
│ 총 일수: 3일                    │
│                                 │
│ 사유:                           │
│ ┌─────────────────────────┐     │
│ │ 개인 사유로...          │     │
│ └─────────────────────────┘     │
│                                 │
│ 잔여 연차: 12일                 │
│                                 │
│     [신청하기]  [취소]          │
└─────────────────────────────────┘
```

### 5.2 관리자용 화면

#### 근태 관리 대시보드 (`attendance_dashboard_screen.dart`)
```
┌─────────────────────────────────────────┐
│ 근태 관리                [2024-02-07]   │
├─────────────────────────────────────────┤
│ 📊 오늘의 현황                          │
│  출근: 15명  근무중: 12명  퇴근: 3명   │
│  지각: 2명   결근: 1명                 │
├─────────────────────────────────────────┤
│ 🔔 승인 대기 (3건)                      │
│  • 김철수 - 연차 (2/10~2/12)           │
│  • 이영희 - 병가 (2/08)                 │
│  • 박민수 - 개인 (2/15)                 │
├─────────────────────────────────────────┤
│ ⚠️ 주의 필요                            │
│  • 홍길동 - 이번 달 지각 3회            │
│  • 강감찬 - 연장근무 누적 20시간        │
└─────────────────────────────────────────┘
```

#### 직원별 근태 현황 (`employee_attendance_screen.dart`)
```
┌─────────────────────────────────────────┐
│ 홍길동 (판매직)                         │
├─────────────────────────────────────────┤
│ 이번 달 통계 (2024년 2월)               │
│  • 출근일: 14일 / 20일                  │
│  • 총 근무: 112시간                     │
│  • 연장근무: 8시간                      │
│  • 지각: 2회   조퇴: 0회                │
│  • 결근: 1회                            │
├─────────────────────────────────────────┤
│ 휴가 현황                               │
│  • 연차: 사용 3일 / 잔여 12일           │
│  • 병가: 사용 1일 / 잔여 4일            │
├─────────────────────────────────────────┤
│ [상세 기록 보기]  [휴가 승인 내역]     │
└─────────────────────────────────────────┘
```

---

## 6. 구현 단계

### Phase 1: 데이터베이스 및 DAO (1-2일)
- [x] 테이블 정의 (attendance_logs, leave_requests, work_schedules, leave_balances)
- [ ] 마이그레이션 작성 (v6 → v7)
- [ ] AttendanceDao 구현
- [ ] 초기 데이터 시딩 (스케줄, 휴가 잔여)

### Phase 2: 비즈니스 로직 (2-3일)
- [ ] AttendanceService 구현
  - [ ] 체크인/체크아웃 로직
  - [ ] 근무 시간 계산
  - [ ] 지각/조퇴 판단
- [ ] 휴가 관리 로직
  - [ ] 신청/승인/거절 워크플로우
  - [ ] 잔여일 계산 및 차감
- [ ] 자동화 배치 작업

### Phase 3: 직원용 UI (2일)
- [ ] 체크인/체크아웃 화면
- [ ] 근태 기록 화면
- [ ] 휴가 신청 화면
- [ ] 휴가 잔여 표시

### Phase 4: 관리자용 UI (2-3일)
- [ ] 근태 관리 대시보드
- [ ] 직원별 근태 현황
- [ ] 휴가 승인 화면
- [ ] 통계 및 리포트

### Phase 5: 통합 및 테스트 (1-2일)
- [ ] Riverpod 프로바이더 설정
- [ ] 권한 관리 (직원/관리자)
- [ ] 알림 시스템 연동
- [ ] 엣지 케이스 테스트

---

## 7. 주요 고려사항

### 7.1 보안
- 직원은 본인 기록만 조회 가능
- 관리자 권한 검증 (휴가 승인, 기록 수정)
- 위치 정보 수집 시 개인정보 보호

### 7.2 성능
- 인덱스 최적화 (employee_id, work_date)
- 월간 통계는 캐싱
- 대량 데이터 조회 시 페이지네이션

### 7.3 사용성
- 체크인/체크아웃 버튼 크고 명확하게
- 지각/조퇴 시 알림 표시
- 휴가 신청 시 잔여일 실시간 표시
- 오프라인 모드 지원 (체크인 시간 로컬 저장)

### 7.4 확장성
- 시프트 근무 지원 (주간/야간)
- 여러 매장 지원 (매장별 스케줄)
- 외근/재택근무 구분
- 급여 시스템 연동 준비

---

## 8. 예상 일정

| Phase | 작업 | 예상 기간 |
|-------|-----|----------|
| Phase 1 | DB + DAO | 1-2일 |
| Phase 2 | Service 로직 | 2-3일 |
| Phase 3 | 직원 UI | 2일 |
| Phase 4 | 관리자 UI | 2-3일 |
| Phase 5 | 통합 테스트 | 1-2일 |
| **총계** | | **8-12일** |

---

## 9. 성공 지표

- ✅ 직원이 모바일에서 5초 이내 체크인 완료
- ✅ 지각/조퇴 자동 탐지 정확도 100%
- ✅ 휴가 승인 프로세스 평균 1일 이내
- ✅ 월말 통계 자동 생성
- ✅ 관리자가 전체 직원 근태 현황을 한눈에 파악

---

## 10. 추후 확장 기능

- 얼굴 인식 체크인 (Face ID)
- GPS 기반 위치 인증 (매장 반경 내)
- QR 코드 스캔 체크인
- 교대 근무 스케줄러
- 급여 연동 (근무 시간 → 급여 계산)
- 근로기준법 준수 검증 (주 52시간 등)
- 모바일 앱 푸시 알림

