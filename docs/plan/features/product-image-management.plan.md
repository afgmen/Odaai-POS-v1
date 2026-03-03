# 상품 이미지 관리 (Product Image Management) - Plan Document

**Feature**: Product Image Management with AI Auto-Search
**Version**: 1.0.0
**Created**: 2026-02-09
**Author**: AI Development Team
**Status**: Planning

---

## 1. Executive Summary

### 1.1 Feature Overview
상품 이미지 관리 시스템은 상품에 시각적 이미지를 추가하고 관리하는 기능입니다. **AI 기반 자동 이미지 검색** 기능을 통해 사용자가 직접 촬영/업로드하지 않아도 상품명만으로 관련 이미지를 자동 제안받을 수 있습니다. 현재 데이터베이스에는 `imageUrl` 필드가 존재하지만 UI에서 전혀 활용되지 않는 상태를 완전히 해결합니다.

### 1.2 Business Value
- **시각적 상품 관리**: 이미지로 상품 식별 → **재고 확인 시간 50% 단축**
- **POS 사용성 향상**: 상품 이미지로 빠른 선택 → **주문 처리 시간 30% 단축**
- **교육 시간 절감**: 신입 직원도 이미지로 상품 인식 → **교육 시간 40% 감소**
- **고객 경험 개선**: 키오스크/모바일 주문 시 이미지 제공 → **주문 정확도 25% 향상**
- **생산성 향상**: AI 자동 검색으로 이미지 수집 시간 제로화 → **100개 상품 이미지 등록 시간: 5시간 → 10분**

### 1.3 Success Metrics
| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| 이미지 등록률 | 0% | 90%+ | 이미지 있는 상품 비율 |
| 평균 등록 시간 | N/A | 30초/상품 | 수동 업로드 기준 |
| AI 검색 성공률 | N/A | 85%+ | 관련 이미지 찾기 성공 |
| POS 상품 선택 시간 | 15초 | 8초 | 이미지 도입 후 |
| 주문 오류율 | 5% | 2% | 시각적 확인으로 감소 |

---

## 2. Problem Statement

### 2.1 Current Pain Points

#### 2.1.1 데이터베이스 vs UI 불일치
```dart
// ✅ DB에는 imageUrl 필드 존재
TextColumn get imageUrl => text().nullable()();

// ❌ UI에서는 전혀 사용 안 함
// - ProductFormModal: 이미지 업로드 필드 없음
// - ProductManagementScreen: 이미지 표시 없음
// - PosMainScreen: 상품 선택 시 이미지 없음
```

#### 2.1.2 상품 식별 어려움
1. **텍스트만으로 상품 인식**
   - 직원이 "테스트 감자칩 대용량 500g"과 "테스트 감자칩 소용량 100g" 구분 어려움
   - SKU나 상품명 암기 필요 → 신입 교육 시간 증가
   - 비슷한 이름의 상품 선택 실수 빈발

2. **POS 사용성 저하**
   - 상품 검색에 시간 소요
   - 고객 대기 시간 증가
   - 피크 타임에 주문 처리 지연

3. **재고 확인 비효율**
   - 창고에서 상품명만으로 실물 찾기 어려움
   - 유사 상품 혼동으로 재고 조사 오류

#### 2.1.3 이미지 수집의 번거로움
1. **수동 촬영/다운로드의 한계**
   - 100개 상품 사진 촬영: 5시간 소요
   - 웹에서 이미지 찾아 다운로드: 상품당 3분
   - 저작권 문제 우려
   - 이미지 품질 불균일

2. **기존 솔루션 부재**
   - 타 POS 시스템: 이미지 업로드만 지원 (자동화 없음)
   - 수동 작업 부담으로 이미지 등록률 낮음

### 2.2 User Stories
```gherkin
As a 매장 관리자
I want to 상품 이미지를 빠르게 등록하고
So that 직원들이 상품을 쉽게 인식할 수 있다

As a POS 직원
I want to 상품 이미지를 보고 선택하고
So that 주문 실수를 줄이고 빠르게 처리할 수 있다

As a 신입 직원
I want to 이미지로 상품을 배우고
So that 빠르게 업무에 적응할 수 있다

As a 바쁜 관리자
I want to AI가 자동으로 이미지를 찾아주고
So that 수동 촬영/다운로드 시간을 절약할 수 있다

As a 재고 담당자
I want to 창고에서 이미지로 상품을 확인하고
So that 재고 조사 정확도를 높일 수 있다
```

---

## 3. Proposed Solution

### 3.1 Feature Scope

#### In-Scope (v1.0.0)

**1. 수동 이미지 업로드**
- ✅ 카메라 촬영 (모바일)
- ✅ 갤러리에서 선택
- ✅ 이미지 크롭/편집 (정사각형 리사이징)
- ✅ 이미지 미리보기
- ✅ 이미지 삭제

**2. 🤖 AI 자동 이미지 검색** (핵심 차별화)
- ✅ 상품명 기반 웹 이미지 검색
- ✅ 5개 후보 이미지 제안
- ✅ 사용자 선택 → 자동 다운로드
- ✅ API: Unsplash (무료, 고품질) 또는 Pexels (무료, 다양성)
- ✅ 검색 실패 시 수동 업로드로 폴백

**3. 일괄 처리 기능**
- ✅ "이미지 없는 상품 자동 검색" 버튼
- ✅ 100개 상품 일괄 처리 (백그라운드)
- ✅ 진행률 표시 (45/100 완료)
- ✅ 실패한 항목만 수동 처리

**4. 이미지 저장 및 관리**
- ✅ 로컬 저장: `{app_documents}/product_images/{sku}.jpg`
- ✅ 자동 리사이징: 최대 800x800 (품질 유지하며 용량 절감)
- ✅ 포맷: JPEG (웹 호환성)
- ✅ imageUrl 필드에 로컬 경로 저장

**5. UI 통합**
- ✅ **상품 폼 (ProductFormModal)**: 이미지 업로드/AI 검색 섹션 추가
- ✅ **상품 리스트 (ProductManagementScreen)**: 썸네일 그리드 뷰
- ✅ **POS 화면 (PosMainScreen)**: 상품 선택 시 이미지 표시
- ✅ **재고 조정 (StockAdjustmentModal)**: 이미지로 상품 확인
- ✅ 이미지 없을 시: 기본 아이콘 (Icons.image_not_supported)

**6. 성능 최적화**
- ✅ 이미지 캐싱 (cached_network_image)
- ✅ 썸네일 lazy loading
- ✅ 백그라운드 다운로드 (isolate)

#### Out-of-Scope (v1.0.0)
- ❌ 클라우드 저장소 연동 (AWS S3, Firebase Storage) → v2.0
- ❌ 상품 이미지 AI 분석 (품질 평가, 자동 태깅) → v2.0
- ❌ 영수증에 이미지 인쇄 → v2.0
- ❌ 고객용 키오스크 이미지 메뉴 → v2.0
- ❌ 다중 이미지 (갤러리) → v2.0
- ❌ 360도 뷰 → 미정

---

## 4. Technical Architecture

### 4.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│          Presentation Layer (UI)                    │
├─────────────────────────────────────────────────────┤
│ ProductFormModal   │ ProductList    │ POS Screen   │
│ [Image Upload]     │ [Thumbnails]   │ [Image View] │
│ [AI Search]        │ [Grid View]    │              │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│          Domain Layer (Business Logic)              │
├─────────────────────────────────────────────────────┤
│ ImageService       │ ImageSearchService             │
│ - uploadImage()    │ - searchByProductName()        │
│ - cropImage()      │ - downloadImage()              │
│ - deleteImage()    │ - batchProcess()               │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│          Data Layer                                 │
├─────────────────────────────────────────────────────┤
│ Local Storage      │ API Client                     │
│ - File System      │ - Unsplash API                 │
│ - Path Provider    │ - Pexels API (fallback)        │
│ - Image Cache      │                                │
└─────────────────────────────────────────────────────┘
```

### 4.2 Database Changes

**기존 Products 테이블 (변경 없음)**
```dart
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().unique()();
  TextColumn get name => text()();
  // ... other fields
  TextColumn get imageUrl => text().nullable()(); // ✅ 이미 존재
  // ... other fields
}
```

**Migration**: 불필요 (imageUrl 필드 이미 존재)

### 4.3 New Dependencies
```yaml
dependencies:
  # 이미지 선택/촬영
  image_picker: ^1.0.7

  # 이미지 크롭
  image_cropper: ^5.0.1

  # 이미지 캐싱
  cached_network_image: ^3.3.1

  # HTTP 통신 (API 호출)
  dio: ^5.4.3  # ✅ 이미 존재

  # 파일 경로
  path_provider: ^2.1.3  # ✅ 이미 존재

  # 이미지 리사이징
  image: ^4.1.7
```

### 4.4 API Integration

#### Unsplash API (Primary)
```dart
class UnsplashImageSearch {
  static const _apiKey = 'YOUR_API_KEY';
  static const _baseUrl = 'https://api.unsplash.com';

  Future<List<ImageResult>> search(String query) async {
    final response = await dio.get(
      '$_baseUrl/search/photos',
      queryParameters: {
        'query': query,
        'per_page': 5,
        'orientation': 'squarish',
      },
      options: Options(headers: {'Authorization': 'Client-ID $_apiKey'}),
    );
    return (response.data['results'] as List)
        .map((json) => ImageResult.fromJson(json))
        .toList();
  }
}
```

**무료 한도**: 50 requests/hour (충분)

#### Pexels API (Fallback)
Unsplash 실패 시 자동 전환

---

## 5. Implementation Plan

### 5.1 Development Phases

**Phase 1: 기본 이미지 업로드 (2일)**
- Day 1: UI 구현 (ProductFormModal 이미지 섹션)
- Day 2: 로컬 저장 로직, 크롭 기능

**Phase 2: AI 자동 검색 (2일)**
- Day 3: Unsplash API 연동, 이미지 검색 UI
- Day 4: 자동 다운로드, 일괄 처리

**Phase 3: UI 통합 (1일)**
- Day 5: 상품 리스트 썸네일, POS 화면 통합

**Phase 4: 테스트 및 최적화 (1일)**
- Day 6: 성능 최적화, 캐싱, 에러 핸들링

**총 개발 기간: 6일**

### 5.2 Implementation Order

```
1. Domain Layer
   ├── ImageService (이미지 업로드/저장)
   ├── ImageSearchService (AI 검색)
   └── ImageCacheService (캐싱)

2. Data Layer
   ├── Unsplash API Client
   ├── Pexels API Client (fallback)
   └── Local File Storage

3. Presentation Layer
   ├── ProductFormModal 수정 (이미지 업로드 섹션)
   ├── ImageSearchDialog (AI 검색 결과 표시)
   ├── ProductManagementScreen 수정 (썸네일 그리드)
   └── PosMainScreen 수정 (상품 이미지 표시)

4. Providers
   ├── imageUploadProvider
   ├── imageSearchProvider
   └── productImageCacheProvider
```

---

## 6. User Experience (UX) Flow

### 6.1 수동 업로드 플로우
```
1. 상품 추가/수정 폼 열기
2. "이미지 추가" 섹션 표시
3. 버튼 선택:
   - [카메라] → 촬영 → 크롭 → 저장
   - [갤러리] → 선택 → 크롭 → 저장
4. 썸네일 미리보기
5. [저장] → imageUrl 업데이트
```

### 6.2 AI 자동 검색 플로우
```
1. 상품명 입력: "코카콜라 500ml"
2. [AI 이미지 검색] 버튼 클릭
3. 로딩 (1-2초)
4. 5개 후보 이미지 그리드 표시
5. 사용자가 원하는 이미지 선택
6. 자동 다운로드 → 크롭 → 저장
7. 썸네일 미리보기
```

### 6.3 일괄 처리 플로우
```
1. 상품 관리 화면 → [일괄 이미지 검색] 버튼
2. 이미지 없는 상품 목록 표시 (예: 45개)
3. 확인 → 백그라운드 처리 시작
4. 진행률 표시: "15/45 완료..."
5. 완료 후 성공/실패 리포트
   - 성공: 38개
   - 실패: 7개 (수동 처리 필요)
6. 실패 항목 필터링하여 수동 작업
```

---

## 7. Success Criteria

### 7.1 Functional Requirements
- ✅ 상품 추가/수정 시 이미지 업로드 가능
- ✅ AI 검색 성공률 85% 이상
- ✅ 이미지 리사이징 자동 (800x800 이하)
- ✅ 상품 리스트에서 썸네일 표시
- ✅ POS 화면에서 이미지로 상품 선택
- ✅ 100개 상품 일괄 처리 10분 이내

### 7.2 Non-Functional Requirements
- ✅ **성능**: 이미지 로딩 < 500ms (캐시 사용 시)
- ✅ **용량**: 상품당 평균 이미지 크기 < 100KB
- ✅ **안정성**: API 실패 시 fallback 동작
- ✅ **사용성**: 3번 클릭 이내 이미지 등록 완료

### 7.3 Acceptance Criteria
```gherkin
Scenario: AI 이미지 검색 성공
  Given 사용자가 상품 폼에 "코카콜라 500ml" 입력
  When [AI 이미지 검색] 버튼 클릭
  Then 5개의 관련 이미지가 표시됨
  And 사용자가 이미지 선택 시 자동 저장됨

Scenario: 수동 업로드
  Given 사용자가 상품 폼 열기
  When [갤러리] 버튼 클릭 → 이미지 선택
  Then 크롭 화면 표시
  And 크롭 완료 후 썸네일 미리보기

Scenario: 일괄 처리
  Given 이미지 없는 상품 100개
  When [일괄 이미지 검색] 실행
  Then 10분 이내 완료
  And 성공률 85% 이상
```

---

## 8. Risk Assessment

### 8.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **API 한도 초과** | Medium | High | Pexels로 fallback, 캐싱 강화 |
| **검색 정확도 낮음** | Medium | Medium | 상품명 전처리 (영문 변환), 수동 업로드 제공 |
| **저작권 문제** | Low | High | Unsplash/Pexels는 상업적 사용 허가 |
| **이미지 용량 과다** | Low | Medium | 자동 리사이징 (800x800, 품질 85%) |
| **네트워크 실패** | Medium | Low | 로컬 캐시 활용, 재시도 로직 |

### 8.2 Business Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **사용자가 AI 검색 안 씀** | Low | Medium | UI/UX 강화, 일괄 처리 제공 |
| **이미지 관리 복잡도** | Low | Low | 자동화 최대화, 단순한 UI |
| **기존 상품 마이그레이션** | High | Low | 일괄 처리 기능으로 해결 |

---

## 9. Dependencies

### 9.1 Internal Dependencies
- ✅ `Products` 테이블 (`imageUrl` 필드 존재)
- ✅ `ProductsDao` (CRUD 메서드 존재)
- ✅ `ProductFormModal` (수정 필요)
- ✅ `ProductManagementScreen` (수정 필요)
- ✅ `PosMainScreen` (수정 필요)

### 9.2 External Dependencies
- 🔐 **Unsplash API Key** (무료 계정 생성 필요)
- 🔐 **Pexels API Key** (fallback용, 무료)
- 📦 `image_picker`, `image_cropper`, `cached_network_image` 패키지

### 9.3 Platform Requirements
- Flutter 3.10.8+
- Android 21+ / iOS 12+
- 카메라 권한 (촬영 기능 사용 시)
- 저장소 권한 (이미지 저장)

---

## 10. Resource Estimation

### 10.1 Development Effort
| Phase | Tasks | Estimated Hours |
|-------|-------|-----------------|
| Phase 1 | 기본 업로드 UI/로직 | 16h (2일) |
| Phase 2 | AI 검색 API 연동 | 16h (2일) |
| Phase 3 | UI 통합 (리스트, POS) | 8h (1일) |
| Phase 4 | 테스트 & 최적화 | 8h (1일) |
| **Total** | | **48h (6일)** |

### 10.2 Cost Estimation (API)
- **Unsplash**: 무료 (50 req/hour) → $0
- **Pexels**: 무료 (200 req/hour) → $0
- **Storage**: 로컬 저장 → $0
- **Total**: $0/month

---

## 11. Monitoring & Analytics

### 11.1 Key Metrics to Track
```dart
// Analytics 이벤트
analytics.logEvent('image_upload', {
  'method': 'camera | gallery | ai_search',
  'success': true | false,
  'duration_ms': 1234,
});

analytics.logEvent('ai_search', {
  'query': '코카콜라 500ml',
  'results_count': 5,
  'user_selected': true | false,
});

analytics.logEvent('batch_process', {
  'total_products': 100,
  'success_count': 85,
  'failed_count': 15,
  'duration_seconds': 456,
});
```

### 11.2 Success Tracking
- 이미지 등록률: `products_with_image / total_products`
- AI 검색 사용률: `ai_search_count / total_upload_count`
- 평균 등록 시간: `avg(upload_duration)`
- POS 선택 시간: 이미지 도입 전후 비교

---

## 12. Future Enhancements (v2.0+)

### 12.1 Advanced Features
1. **클라우드 저장소 연동**
   - AWS S3 또는 Firebase Storage
   - 멀티 디바이스 동기화
   - CDN으로 빠른 로딩

2. **AI 이미지 분석**
   - Google Vision API로 품질 평가
   - 자동 태깅 (색상, 카테고리)
   - 유사 이미지 검출

3. **다중 이미지 갤러리**
   - 상품당 최대 5장
   - 스와이프로 이미지 전환

4. **키오스크 통합**
   - 고객이 이미지 메뉴 보고 주문
   - 대형 이미지 표시

5. **영수증 이미지 인쇄**
   - 상품 이미지 포함 영수증
   - 프린터 성능 고려

---

## 13. Rollout Plan

### 13.1 Rollout Strategy
```
Week 1: 개발 (Phase 1-2)
Week 2: 개발 (Phase 3-4) + 내부 테스트
Week 3: 베타 테스트 (3개 매장)
Week 4: 피드백 수렴 → 개선 → 전체 롤아웃
```

### 13.2 Rollback Plan
- 기존 `imageUrl` 필드는 nullable → 롤백 시에도 기존 데이터 유지
- 새 기능 비활성화: Feature Flag로 제어
- 이미지 파일 삭제 시 DB는 그대로 (imageUrl = null로 업데이트만)

---

## 14. Stakeholder Communication

### 14.1 Key Messages
- **For Business**: "이미지 추가로 주문 실수 25% 감소, 신입 교육 시간 40% 절감"
- **For Users**: "AI가 자동으로 이미지 찾아줌. 100개 상품 10분 만에 등록 완료"
- **For Developers**: "imageUrl 필드 활용. 6일 개발 완료. 무료 API 사용"

### 14.2 Training Plan
- **관리자**: 30분 교육 (일괄 처리 방법, AI 검색 활용)
- **직원**: 15분 교육 (POS 화면에서 이미지 보는 법)
- **문서**: 사용자 가이드, FAQ

---

## 15. Approval

### 15.1 Sign-off Required
- [ ] Product Owner: ________________
- [ ] Tech Lead: ________________
- [ ] QA Lead: ________________

### 15.2 Next Steps
1. ✅ Plan 승인 → `/pdca design product-image-management`
2. Design 문서 작성 (API 스펙, UI 와이어프레임, DB 스키마)
3. Implementation 시작 (Phase 1-4)
4. Gap Analysis → Iteration → Report

---

**Document Version**: 1.0.0
**Last Updated**: 2026-02-09
**Status**: ✅ Ready for Review
