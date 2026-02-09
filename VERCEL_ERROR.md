# ⚠️ Vercel 배포 오류 안내

## 문제
Vercel에서 404 NOT_FOUND 오류 발생

## 원인
**Oda POS는 Flutter 데스크톱 애플리케이션입니다.**
- Vercel은 **웹 애플리케이션** 호스팅 플랫폼입니다
- Flutter Desktop 앱은 Vercel에 배포할 수 없습니다

## 해결 방법

### 옵션 1: GitHub Releases (권장) ✅

Flutter 데스크톱 앱의 표준 배포 방법입니다.

**수동 Release 생성 방법:**

1. **GitHub 리포지토리 접속:**
   https://github.com/afgmen/Odaai-POS-v1

2. **Releases 페이지 이동:**
   - "Releases" 탭 클릭
   - "Create a new release" 버튼 클릭

3. **릴리즈 정보 입력:**
   - **Tag:** `v1.0.0` (새 태그 생성)
   - **Release title:** `Release v1.0.0 - Oda POS with i18n and multi-currency`
   - **Description:**
   ```markdown
   ## ✨ Features

   - ✅ Multi-language support (Korean, English, Vietnamese)
   - ✅ Multi-currency support (KRW, USD, VND)
   - ✅ Product management with barcode scanning
   - ✅ Cart and payment processing
   - ✅ Employee management with PIN authentication
   - ✅ Discount and promotion system
   - ✅ Sales history and receipt printing

   ## 🛠️ Technical Stack

   - Flutter desktop (macOS, Windows)
   - Riverpod + Drift ORM
   - Material Design 3

   ## 📦 Download

   ### macOS
   - **File:** oda_pos_macos_v1.0.0.zip (60MB)
   - **SHA-256:**
     ```
     4ba91e1f9f9ec7653e66e81088d4622b18f27f8726fe7a7fdbe951a7c17fd7e4
     ```

   ## 📖 Installation

   See [DISTRIBUTION_GUIDE.md](DISTRIBUTION_GUIDE.md)

   ### Quick Start (macOS)

   1. Download oda_pos_macos_v1.0.0.zip
   2. Extract and move to Applications
   3. First launch: System Preferences → Security → "Open Anyway"

   ### Initial Setup
   - Default PIN: 1234
   - Language: Settings (Korean/English/Vietnamese)
   - Currency: Settings (KRW/USD/VND)

   ## 🔧 System Requirements
   - macOS 10.14 or later
   ```

4. **파일 첨부:**
   - 파일 경로: `/Users/JINLee/Documents/AI-coding/Odaai-POS/oda_pos_macos_v1.0.0.zip`
   - Finder에서 위 경로로 이동
   - ZIP 파일을 Release 페이지의 "Attach binaries" 영역에 드래그앤드롭

5. **"Publish release" 클릭**

### 옵션 2: Flutter Web 빌드 (Vercel 사용 시)

Vercel을 사용하려면 **Flutter Web** 버전을 빌드해야 합니다.

```bash
# Flutter Web 빌드
flutter build web --release

# build/web 폴더가 생성됨
# Vercel에서 Output Directory를 "build/web"으로 설정
```

**주의사항:**
- Drift 데이터베이스는 웹에서 작동하지 않을 수 있음
- 데스크톱 기능(파일 시스템 접근 등) 제한됨
- 바코드 스캐너 등 일부 기능 미지원

### 옵션 3: 웹 버전 별도 개발

웹에서도 사용하려면:
- 웹 전용 버전을 별도로 개발
- Firebase, Supabase 등 웹 호환 백엔드 사용
- PWA로 배포

## 권장 사항

**✅ 현재 프로젝트(Desktop App):**
→ **GitHub Releases** 사용 (옵션 1)

**웹 버전이 필요한 경우:**
→ 별도 웹 프로젝트 생성 (옵션 3)

## 다음 단계

1. Vercel 프로젝트 삭제 (불필요)
2. GitHub Releases로 배포 (위 옵션 1 참조)
3. 사용자에게 GitHub Release 다운로드 링크 공유

---

**배포 파일 위치:**
- macOS: `/Users/JINLee/Documents/AI-coding/Odaai-POS/oda_pos_macos_v1.0.0.zip`
- GitHub: https://github.com/afgmen/Odaai-POS-v1
