<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME 아이콘"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
macOS 화면에 지금 입력 언어(한 / EN / あ)를 항상 띄워 주는 뱃지 앱입니다.<br>
<a href="README.md">English</a> · <b>한국어</b> · <a href="README.ja.md">日本語</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

여러 언어를 섞어 쓰면서 터미널, Vim, CLI 도구를 자주 쓴다면 이런 일을 겪어 보셨을 겁니다. 단축키를 눌렀는데 아무 반응이 없고, 그제야 입력기가 한글로 되어 있었다는 걸 알게 됩니다. CheatIME는 화면에 작은 뱃지를 띄워서 지금 입력 언어를 한눈에 보여 주고, 특정 앱으로 넘어갈 때 입력기를 대신 바꿔 주기도 합니다.

<p align="center"><img src="docs/badges.png" width="480" alt="뱃지 모양"></p>

## 기능

**뱃지**
- 모든 데스크톱(Spaces)과 전체 화면 앱 위에도 항상 떠 있습니다
- 입력기 종류가 아니라 언어를 보고 판별하므로 Apple 기본 입력기, 구름, 일본어 입력기 등 어떤 입력기와도 함께 쓸 수 있습니다
- 언어마다 표시 글자, 배경색, 글자색을 정하고, 특정 언어일 때는 뱃지를 숨길 수 있습니다
- 모양(둥근 사각형, 캡슐, 원, 작은 점), 글자 크기, 불투명도, Liquid Glass 효과(macOS 26 이상)
- 입력기가 바뀔 때 macOS 시스템 소리로 알려 주는 옵션(macOS에는 이런 기본 옵션이 없습니다)

**위치**
- 고정 위치: 3×3 정렬과 여백으로 정하고, 모든 디스플레이·마우스가 있는 디스플레이·직접 고른 디스플레이 중에서 고릅니다. 뱃지를 끌어서 옮겨도 됩니다.
- 마우스 포인터 옆: 뱃지가 마우스 포인터를 따라다닙니다.
- 텍스트 커서 옆: 뱃지가 글자를 입력하는 커서 바로 옆에 붙습니다. 손쉬운 사용 권한이 필요하고, 일부 터미널처럼 커서 위치를 알려 주지 않는 앱에서는 마우스 포인터 옆에 표시합니다.

**앱**
- 체크한 앱이 앞에 있을 때만 뱃지를 띄웁니다. 체크한 앱은 목록 위쪽에 따로 모아 보여 줍니다.
- 자동 전환 규칙: 어떤 앱이 앞으로 나오면 원하는 입력기로 바꿉니다. 규칙마다 앱을 떠날 때 이전 입력기로 되돌릴 수 있습니다.

**그 밖에**
- 뱃지를 클릭하면 숨기고, 우클릭(또는 Control+클릭)하면 메뉴가 뜹니다
- 로그인할 때 자동 실행
- 한국어, 영어, 일본어 화면 지원
- 네트워크를 쓰지 않고, 키 입력을 읽지 않습니다

<p align="center"><img src="docs/settings-ko.png" width="560" alt="뱃지 설정"></p>
<p align="center"><img src="docs/rules-ko.png" width="560" alt="자동 전환 규칙"></p>

## 요구 사항

macOS 15 Sequoia 이상, Apple Silicon과 Intel Mac 모두 지원(유니버설 바이너리).

## 설치

1. [Releases](https://github.com/HikiJun97/CheatIME/releases)에서 `CheatIME-<버전>.zip`을 내려받습니다.
2. 압축을 풀고 `CheatIME.app`을 `/Applications`로 옮깁니다.
3. CheatIME는 Apple 공증을 받지 않아서 처음 실행할 때 macOS가 막습니다. 아래 둘 중 한 가지 방법으로 허용하세요.
   - CheatIME를 한 번 실행해서 막히면, **시스템 설정 → 개인정보 보호 및 보안**으로 가서 CheatIME 안내 옆의 **그래도 열기**를 누르고 확인합니다.
   - 또는 터미널에서 다음 명령을 실행합니다.
     ```sh
     xattr -dr com.apple.quarantine /Applications/CheatIME.app
     ```

로그인할 때 자동으로 켜려면 설정 → 일반에서 **로그인 시 실행**을 켜세요.

## 사용법

- **메뉴 막대 아이콘**: 설정…(⌘,), 뱃지 표시, 종료
- **뱃지**: 클릭하면 숨기기, 끌면 옮기기, 우클릭하면 메뉴
- 메뉴 막대 아이콘이 노치에 가려졌거나 시스템 설정의 메뉴 막대 항목에서 꺼져 있으면, Spotlight나 Finder에서 CheatIME를 한 번 더 실행하세요. 설정 창이 열립니다.

### 손쉬운 사용 권한

**텍스트 커서 옆** 위치를 쓸 때만 필요합니다. 설정 → 위치에서 이 방식을 고른 뒤, **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 CheatIME를 허용하세요.

CheatIME는 Apple Developer ID로 서명하지 않아서, macOS가 새 버전을 다른 앱으로 인식합니다. 업데이트한 뒤에는 손쉬운 사용 목록에서 CheatIME를 지웠다가 다시 허용해 주세요.

## 소스에서 빌드

Xcode 또는 macOS 27 SDK가 포함된 Command Line Tools(Swift 6.2 이상)가 필요합니다.

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # CheatIME.app 빌드(유니버설)
make install    # /Applications에 복사하고 실행
make dist       # CheatIME-<버전>.zip 만들기
```

## 삭제

CheatIME를 종료하고 `/Applications/CheatIME.app`을 지웁니다(`make uninstall`로도 됩니다). 설정까지 지우려면 다음 명령을 실행하세요.

```sh
defaults delete io.github.hikijun97.cheatime
```

**로그인 시 실행**을 켰거나 손쉬운 사용 권한을 줬다면, 시스템 설정의 해당 목록에서도 CheatIME를 지워 주세요.

## 개인정보

CheatIME는 Text Input Sources API로 지금 어떤 입력기가 선택돼 있는지 macOS에 묻고, 규칙에 해당할 때 입력기를 바꿉니다. 키 입력을 감시하지 않고 네트워크에 연결하지 않습니다. **텍스트 커서 옆** 위치를 쓸 때는 손쉬운 사용 권한을 텍스트 커서 위치를 읽는 데만 씁니다. 설정은 macOS 기본 사용자 설정(user defaults)에 저장됩니다.

## 라이선스

[MIT](LICENSE)
