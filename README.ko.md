<p align="center"><img src="docs/icon.png" width="128" alt="CheatIME 아이콘"></p>

<h1 align="center">CheatIME</h1>

<p align="center">
지금 입력 언어를 macOS 화면에 항상 띄워 주는 뱃지 앱입니다.<br>
<a href="README.md">English</a> · <b>한국어</b> · <a href="README.ja.md">日本語</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

입력 언어를 화면 구석 원하는 곳 어딘가, 혹은 커서 옆에 항상 표시해주는 always-on-top 형식의 입력 모드 표시기입니다. 영어가 아니면 숏컷 등의 커맨드가 동작하지 않는 nvim과 같은 터미널 환경에서 다국어 사용자 지원을 위해 만들어졌습니다.

<p align="center"><img src="docs/badges.png" width="560" alt="여러 언어와 모양의 뱃지 예시"></p>

## 기능

- 전체 화면 앱을 포함해 모든 창보다 위에 표시됩니다.
- 인디케이터를 화면상의 고정된 자리, 마우스 포인터 옆, 텍스트 커서 옆 등 원하는 곳에 띄울 수 있습니다. (텍스트 커서는 일부 앱 한정)
- 언어마다 인디케이터의 스타일을 원하는 대로 지정할 수 있습니다.
- 상시 표시 혹은 언어가 바뀔 때만 표시 전환이 가능합니다.
- 원하는 앱에서만 인디케이터를 띄울 수 있습니다.
- 특정 앱으로 전환 시 특정 언어로 자동 전환되도록 규칙을 설정할 수 있습니다.
- 사운드 알림이 가능합니다.

<p align="center"><img src="docs/settings-ko.png" width="560" alt="뱃지 설정"></p>
<p align="center"><img src="docs/rules-ko.png" width="560" alt="자동 전환 규칙"></p>

## 요구 사항

macOS 15 이상, Apple Silicon 또는 Intel Mac

## 설치

1. [Releases](https://github.com/HikiJun97/CheatIME/releases)에서 `CheatIME-<버전>.dmg`를 내려받습니다.
2. DMG를 열고 **CheatIME**를 **Applications**로 끌어다 놓습니다.
3. 한 번 실행한 뒤 **시스템 설정 → 개인정보 보호 및 보안**에서 **그래도 열기**를 누릅니다. 혹은 터미널에서 다음 명령을 실행합니다.
   ```sh
   xattr -dr com.apple.quarantine /Applications/CheatIME.app
   ```

## 주의사항

- **텍스트 커서 옆**에 인디케이터를 표시하는 기능은 손쉬운 사용 권한(macOS 27에서는 **기기 제어 및 데이터 접근**)이 필요합니다. **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 CheatIME를 허용합니다.

## 소스에서 빌드

macOS 27 SDK(Xcode 또는 Command Line Tools)가 필요합니다. 처음 빌드할 때 Sparkle 프레임워크를 내려받습니다. `make dist`를 쓰려면 [dmgbuild](https://github.com/dmgbuild/dmgbuild)도 설치해야 합니다(`uv tool install dmgbuild==1.6.7`).

```sh
git clone https://github.com/HikiJun97/CheatIME.git
cd CheatIME
make            # CheatIME.app 빌드
make install    # /Applications에 복사하고 실행
make dist       # dist/에 DMG와 ZIP 만들기
```

## Inspired by

- [ShowyEdge](https://github.com/pqrs-org/ShowyEdge)
- [Input Source Pro](https://github.com/runjuu/InputSourcePro)

## 라이선스

[MIT](LICENSE)

업데이트에는 [Sparkle](https://sparkle-project.org)을 쓰며, Sparkle의 라이선스는 앱에 함께 들어 있습니다.
국기 이미지는 [flag-icons](https://github.com/lipis/flag-icons)(MIT)에서 가져왔으며, 라이선스는 앱에 함께 들어 있습니다.
