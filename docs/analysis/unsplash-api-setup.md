# Unsplash API Key 설정 가이드

## 🔑 API Key 발급

### 1단계: Unsplash 개발자 계정 생성

1. https://unsplash.com 방문
2. 우측 상단 "Sign up" 클릭하여 계정 생성
3. 로그인 후 https://unsplash.com/developers 이동
4. "Register as a developer" 클릭

### 2단계: 새 애플리케이션 생성

1. "Your apps" 페이지에서 "New Application" 클릭
2. 애플리케이션 정보 입력:
   - **Application name**: Oda POS
   - **Description**: Product image management for restaurant POS system
   - **Accept terms**: 체크박스 모두 선택
3. "Create application" 클릭

### 3단계: Access Key 복사

1. 생성된 앱 페이지에서 "Keys" 섹션 확인
2. **Access Key** 복사 (예: `abc123...xyz789`)
3. ⚠️ **Secret Key**는 사용하지 않음 (복사 불필요)

---

## 📝 코드에 API Key 적용

### 파일 경로
```
lib/features/products/data/api/unsplash_api_client.dart
```

### 수정 전 (Line 12)
```dart
static const String _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY_HERE';
```

### 수정 후
```dart
static const String _accessKey = 'abc123...xyz789'; // 실제 Access Key 입력
```

---

## ⚡ API 사용 제한 (Free Tier)

### Demo 모드 (개발/테스트)
- **요청 제한**: 50 requests/hour
- **Rate Limiting**: 초당 최대 요청 없음
- **적용 대상**: 개발 및 테스트 환경

### Production 모드 (상용)
- **요청 제한**: 5,000 requests/hour
- **승인 필요**: Unsplash에 Production 승인 신청
- **요구사항**:
  - 앱에 "Photos by Unsplash" 크레딧 표시
  - Unsplash Guidelines 준수

---

## 🛡️ API Key 보안

### ⚠️ 중요 사항
1. **Git에 커밋하지 마세요**
   - `.gitignore`에 API key 파일 추가
   - 환경 변수 또는 secret 파일로 관리

2. **프로덕션 배포 시**
   - 환경변수로 주입
   - CI/CD 파이프라인에서 secret 관리

### 권장 방법: 환경 변수 사용

#### 1. `.env` 파일 생성
```bash
# .env (git에 포함하지 않음)
UNSPLASH_ACCESS_KEY=abc123...xyz789
```

#### 2. `.gitignore`에 추가
```
.env
```

#### 3. 코드 수정 (flutter_dotenv 사용)
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UnsplashApiClient {
  static final String _accessKey = dotenv.env['UNSPLASH_ACCESS_KEY'] ?? '';
  // ...
}
```

---

## 🧪 테스트

### API Key 정상 동작 확인

1. 앱 실행
2. 상품 관리 → 상품 추가
3. SKU: `TEST001`, 상품명: `coffee` 입력
4. "AI 자동 검색" 버튼 클릭
5. 5개 커피 이미지 표시 확인

### 예상 결과
✅ 5개 이미지 그리드 표시
✅ 각 이미지에 "Unsplash - 작가명" 표시
✅ 이미지 선택 및 다운로드 가능

### 에러 발생 시

#### 401 Unauthorized
```
원인: API Key가 잘못되었거나 만료됨
해결: Access Key 재확인 및 재발급
```

#### 403 Forbidden
```
원인: API 사용 제한 초과 (50 req/hour)
해결: 1시간 대기 또는 Production 승인 신청
```

#### 네트워크 에러
```
원인: 인터넷 연결 문제
해결: 네트워크 연결 확인
```

---

## 📊 사용량 모니터링

### Unsplash 대시보드
1. https://unsplash.com/oauth/applications 접속
2. 앱 선택
3. "Analytics" 탭에서 사용량 확인

### 주요 메트릭
- **Total requests**: 총 요청 수
- **Requests per hour**: 시간당 요청 수
- **Downloads**: 이미지 다운로드 수

---

## 🔄 대안: Pexels API (백업)

Unsplash가 동작하지 않을 경우 Pexels API를 대안으로 사용 가능:

### Pexels API Key 발급
1. https://www.pexels.com/api/ 방문
2. 계정 생성 및 API Key 발급
3. 무료: 200 requests/hour

### 코드 수정
```dart
// lib/features/products/data/api/pexels_api_client.dart
class PexelsApiClient {
  static const String _apiKey = 'YOUR_PEXELS_API_KEY';
  // ...
}
```

---

## ✅ 체크리스트

- [ ] Unsplash 개발자 계정 생성
- [ ] 애플리케이션 등록
- [ ] Access Key 복사
- [ ] `unsplash_api_client.dart`에 키 입력
- [ ] 테스트 실행 (상품명 "coffee"로 검색)
- [ ] 5개 이미지 표시 확인
- [ ] 이미지 다운로드 성공 확인
- [ ] `.gitignore`에 API Key 파일 추가

---

## 📞 문의

### Unsplash 지원
- 이메일: help@unsplash.com
- FAQ: https://help.unsplash.com

### Oda POS 개발팀
- API 관련 이슈는 GitHub Issues에 등록
