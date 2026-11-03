<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME 아이콘"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
macOS 화면 구석에 지금 입력 언어(한 / EN / あ)를 항상 띄워 주는 뱃지 앱입니다.<br>
<a href="README.md">English</a> · <b>한국어</b> · <a href="README.ja.md">日本語</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

여러 언어를 섞어 쓰면서 터미널, Vim, CLI 도구를 자주 쓴다면 이런 일을 겪어 보셨을 겁니다. 단축키를 눌렀는데 아무 반응이 없고, 그제야 입력기가 한글로 되어 있었다는 걸 알게 됩니다. CheatIME는 화면 구석에 작은 뱃지를 띄워서 지금 입력 언어를 한눈에 보여 줍니다.

<p align="center"><img src="docs/badges.png" width="420" alt="뱃지 모양"></p>

## 기능

- 모든 데스크톱(Spaces)과 전체 화면 앱 위에도 항상 떠 있는 뱃지
- 입력기 종류가 아니라 언어를 보고 판별하므로 Apple 기본 입력기, 구름, 일본어 입력기 등 어떤 입력기와도 함께 쓸 수 있음
- 언어마다 표시 글자, 배경색, 글자색을 정하고, 특정 언어일 때는 뱃지를 숨길 수 있음
- 표시할 디스플레이 선택: 모든 디스플레이, 마우스가 있는 디스플레이, 직접 고른 디스플레이
- 모양(둥근 사각형, 캡슐, 원), 글자 크기, 불투명도, Liquid Glass 효과(macOS 26 이상)
- 3×3 정렬과 여백으로 위치를 정하거나, 뱃지를 끌어서 옮기기
- 뱃지를 클릭하면 숨기고, 우클릭(또는 Control+클릭)하면 메뉴가 뜸
- 한국어, 영어, 일본어 화면 지원
- 권한 요청 없음, 네트워크 사용 없음, 키 입력을 읽지 않음

<p align="center"><img src="docs/settings-ko.png" width="560" alt="설정 창"></p>

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

로그인할 때 자동으로 켜려면 **시스템 설정 → 일반 → 로그인 항목**에 CheatIME를 추가하세요.

## 사용법

- **메뉴 막대 아이콘**: 설정…(⌘,), 뱃지 표시, 종료
- **뱃지**: 클릭하면 숨기기, 끌면 옮기기, 우클릭하면 메뉴
- 메뉴 막대 아이콘이 노치에 가려졌거나 시스템 설정의 메뉴 막대 항목에서 꺼져 있으면, Spotlight나 Finder에서 CheatIME를 한 번 더 실행하세요. 설정 창이 열립니다.

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

## 개인정보

CheatIME는 Text Input Sources API로 지금 어떤 입력기가 선택돼 있는지만 macOS에 묻습니다. 키 입력을 감시하지 않고, 손쉬운 사용이나 입력 모니터링 권한이 필요 없으며, 네트워크에 연결하지 않습니다. 설정은 macOS 기본 사용자 설정(user defaults)에 저장됩니다.

## 라이선스

[MIT](LICENSE)
