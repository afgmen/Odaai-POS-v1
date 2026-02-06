# Oda POS 배포 가이드

## 개요
이 문서는 Oda POS 애플리케이션을 제3자에게 실행 파일로 배포하는 방법을 설명합니다.

## 목차
1. [macOS 배포](#macos-배포)
2. [Windows 배포](#windows-배포)
3. [배포 패키지 준비](#배포-패키지-준비)
4. [배포 방법](#배포-방법)

---

## macOS 배포

### 1. 릴리즈 빌드 생성

```bash
cd /Users/JINLee/Documents/AI-coding/Odaai-POS/oda_pos
flutter build macos --release
```

### 2. 빌드 결과물 위치

빌드가 완료되면 다음 경로에 실행 가능한 앱이 생성됩니다:

```
build/macos/Build/Products/Release/oda_pos.app
```

### 3. 앱 서명 (선택사항 - 권장)

macOS에서 외부 배포를 위해서는 Apple Developer 계정으로 앱에 서명하는 것이 좋습니다.

**서명 없이 배포할 경우 사용자가 겪을 문제:**
- "개발자를 확인할 수 없습니다" 경고 메시지
- 사용자가 시스템 환경설정 > 보안 및 개인 정보 보호에서 수동으로 허용해야 함

**서명 방법 (Apple Developer 계정 필요):**

```bash
# 개발자 ID 확인
security find-identity -v -p codesigning

# 앱 서명
codesign --deep --force --verify --verbose --sign "Developer ID Application: YOUR_NAME" build/macos/Build/Products/Release/oda_pos.app

# 공증 (Notarization) - macOS 10.15 이상 필수
xcrun notarytool submit build/macos/Build/Products/Release/oda_pos.app --apple-id YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD --team-id YOUR_TEAM_ID
```

### 4. DMG 이미지 생성 (선택사항)

DMG 파일을 생성하면 사용자가 더 쉽게 설치할 수 있습니다.

```bash
# DMG 생성 도구 설치
brew install create-dmg

# DMG 생성
create-dmg \
  --volname "Oda POS Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "oda_pos.app" 200 190 \
  --hide-extension "oda_pos.app" \
  --app-drop-link 600 185 \
  "OdaPOS-Installer.dmg" \
  "build/macos/Build/Products/Release/oda_pos.app"
```

### 5. ZIP 압축 배포 (간단한 방법)

```bash
cd build/macos/Build/Products/Release
zip -r oda_pos_macos.zip oda_pos.app
```

---

## Windows 배포

### 1. Windows 환경 준비

Windows 빌드를 위해서는 Windows PC가 필요합니다. 또는 Parallels Desktop, VMware 등의 가상화 소프트웨어를 사용할 수 있습니다.

### 2. 릴리즈 빌드 생성

```bash
flutter build windows --release
```

### 3. 빌드 결과물 위치

```
build\windows\x64\runner\Release\
```

다음 파일들이 필요합니다:
- `oda_pos.exe` - 실행 파일
- `*.dll` - 필요한 라이브러리 파일들
- `data/` 폴더 - 앱 리소스

### 4. 배포 패키지 준비

모든 필요한 파일을 하나의 폴더에 모아서 압축합니다:

```
OdaPOS-Windows/
├── oda_pos.exe
├── flutter_windows.dll
├── data/
│   └── (리소스 파일들)
└── README.txt (사용 설명서)
```

### 5. 인스톨러 생성 (선택사항 - 권장)

**Inno Setup 사용:**

1. Inno Setup 다운로드 및 설치: https://jrsoftware.org/isinfo.php

2. 설치 스크립트 작성 (`installer_script.iss`):

```iss
[Setup]
AppName=Oda POS
AppVersion=1.0
DefaultDirName={pf}\OdaPOS
DefaultGroupName=Oda POS
OutputDir=dist
OutputBaseFilename=OdaPOS-Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Oda POS"; Filename: "{app}\oda_pos.exe"
Name: "{commondesktop}\Oda POS"; Filename: "{app}\oda_pos.exe"

[Run]
Filename: "{app}\oda_pos.exe"; Description: "Launch Oda POS"; Flags: postinstall nowait skipifsilent
```

3. 인스톨러 빌드:
```bash
iscc installer_script.iss
```

---

## 배포 패키지 준비

### 1. 사용 설명서 작성

`README.txt` 또는 `사용설명서.pdf` 작성:

```
Oda POS 설치 및 사용 가이드

1. 시스템 요구사항
   - macOS: macOS 10.14 이상
   - Windows: Windows 10 이상

2. 설치 방법
   [macOS]
   - oda_pos.app을 응용 프로그램 폴더로 드래그
   - 처음 실행 시 "개발자를 확인할 수 없습니다" 메시지가 나타나면
     시스템 환경설정 > 보안 및 개인 정보 보호에서 "확인 없이 열기" 클릭

   [Windows]
   - OdaPOS-Setup.exe 실행
   - 설치 마법사 안내에 따라 진행

3. 초기 설정
   - 기본 PIN: 1234
   - 언어 설정: 설정 > 언어에서 변경 가능
   - 통화 설정: 설정 > 통화에서 변경 가능

4. 문의
   - 이메일: support@example.com
```

### 2. 라이선스 파일

`LICENSE.txt` 작성:

```
상용 라이선스

Copyright (c) 2024 [회사명]

이 소프트웨어는 저작권법의 보호를 받습니다.
무단 복제, 배포, 수정을 금지합니다.

라이선스 사용자는 다음 권한을 가집니다:
- 구매한 컴퓨터에서 소프트웨어 설치 및 사용
- 백업 목적의 복사본 1부 생성

다음 행위는 금지됩니다:
- 소프트웨어의 재배포
- 리버스 엔지니어링, 디컴파일, 디어셈블
- 소스 코드 추출 시도
```

---

## 배포 방법

### 1. GitHub Releases (권장)

**장점:**
- 버전 관리 용이
- 다운로드 통계 제공
- 자동 업데이트 시스템 구축 가능

**배포 방법:**

1. GitHub 프라이빗 리포지토리 생성 (또는 기존 리포지토리 사용)
2. Releases 페이지에서 "Create a new release" 클릭
3. 버전 태그 생성 (예: v1.0.0)
4. 릴리즈 노트 작성
5. 빌드된 파일 업로드:
   - `oda_pos_macos.zip`
   - `OdaPOS-Setup.exe` (Windows)
   - `README.txt`
   - `LICENSE.txt`
6. "Publish release" 클릭

**접근 권한 관리:**
- 프라이빗 리포지토리: Collaborator로 추가된 사용자만 다운로드 가능
- 퍼블릭 리포지토리: 누구나 다운로드 가능

### 2. 클라우드 스토리지 배포

**Google Drive / Dropbox / iCloud:**

1. 배포 패키지를 업로드
2. 링크 공유 설정:
   - "링크가 있는 모든 사용자" 또는
   - "특정 사용자만" 선택
3. 링크를 제3자에게 전달

**OneDrive / SharePoint:**

1. 파일 업로드
2. 공유 > "특정 사용자" 선택
3. 이메일로 초대

### 3. 자체 웹사이트 배포

**간단한 다운로드 페이지:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Oda POS 다운로드</title>
</head>
<body>
    <h1>Oda POS 다운로드</h1>

    <h2>버전 1.0.0</h2>
    <p>출시일: 2024-02-06</p>

    <h3>다운로드</h3>
    <ul>
        <li><a href="downloads/oda_pos_macos.zip">macOS용 다운로드</a></li>
        <li><a href="downloads/OdaPOS-Setup.exe">Windows용 다운로드</a></li>
    </ul>

    <h3>시스템 요구사항</h3>
    <ul>
        <li>macOS 10.14 이상</li>
        <li>Windows 10 이상</li>
    </ul>

    <h3>문의</h3>
    <p>이메일: support@example.com</p>
</body>
</html>
```

### 4. 이메일 직접 전송

소수의 사용자에게 배포할 경우:

1. 파일을 ZIP으로 압축 (25MB 이하 권장)
2. 이메일에 첨부 또는 클라우드 링크 공유
3. 설치 가이드를 이메일 본문에 포함

---

## 보안 고려사항

### 1. 바이러스 검사

배포 전 빌드 파일에 대해 바이러스 검사를 수행하세요:
- macOS: Malwarebytes, Sophos Home
- Windows: Windows Defender, Malwarebytes

### 2. 체크섬 제공

파일 무결성 확인을 위한 SHA-256 체크섬 제공:

```bash
# macOS/Linux
shasum -a 256 oda_pos_macos.zip

# Windows
certutil -hashfile OdaPOS-Setup.exe SHA256
```

체크섬을 README 또는 다운로드 페이지에 명시하세요.

### 3. HTTPS 사용

웹사이트를 통해 배포할 경우 반드시 HTTPS를 사용하세요.

---

## 업데이트 관리

### 1. 버전 번호 관리

`pubspec.yaml`에서 버전 관리:

```yaml
version: 1.0.0+1
```

- `1.0.0`: 사용자에게 보이는 버전
- `+1`: 빌드 번호

### 2. 릴리즈 노트 작성

각 버전의 변경사항을 명확히 기록:

```
버전 1.1.0 (2024-03-01)
- 새로운 기능: 할인 자동 적용
- 개선: 성능 최적화
- 버그 수정: 결제 오류 수정

버전 1.0.0 (2024-02-06)
- 초기 릴리즈
- 다국어 지원 (한국어, 영어, 베트남어)
- 다중 통화 지원 (KRW, USD, VND)
```

### 3. 자동 업데이트 시스템 (고급)

향후 구현을 위한 옵션:
- Sparkle (macOS): https://sparkle-project.org/
- Squirrel (Windows): https://github.com/Squirrel/Squirrel.Windows
- 자체 업데이트 서버 구축

---

## 문제 해결

### macOS

**문제: "손상되었기 때문에 열 수 없습니다" 오류**

해결:
```bash
xattr -cr /Applications/oda_pos.app
```

**문제: "개발자를 확인할 수 없습니다" 경고**

해결:
1. 시스템 환경설정 > 보안 및 개인 정보 보호
2. "확인 없이 열기" 버튼 클릭

### Windows

**문제: "Windows에서 PC를 보호했습니다" 경고**

해결:
1. "추가 정보" 클릭
2. "실행" 버튼 클릭

**문제: DLL 누락 오류**

해결:
- Visual C++ Redistributable 설치
- 모든 DLL 파일이 EXE와 같은 폴더에 있는지 확인

---

## 체크리스트

배포 전 확인사항:

- [ ] 릴리즈 빌드 생성 완료
- [ ] 앱 정상 동작 테스트 완료
- [ ] 사용 설명서 작성 완료
- [ ] 라이선스 파일 포함
- [ ] 버전 번호 업데이트
- [ ] 릴리즈 노트 작성
- [ ] 바이러스 검사 수행
- [ ] 체크섬 생성 및 문서화
- [ ] 배포 패키지 압축
- [ ] 배포 경로 준비 (GitHub/클라우드/웹사이트)
- [ ] 테스트 사용자에게 사전 배포 및 피드백 수집

---

## 추가 리소스

- Flutter 데스크톱 배포 가이드: https://docs.flutter.dev/deployment/desktop
- macOS 앱 배포: https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases
- Windows 앱 배포: https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/

---

**마지막 업데이트:** 2024-02-06
