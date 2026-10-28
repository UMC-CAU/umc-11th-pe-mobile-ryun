# MovieLog

Flutter 영화 기록 앱의 5주차 실습입니다. TMDB API, MVVM, Provider를 사용합니다.

## 주요 기능

- 홈 인기 영화 최대 5개 표시
- Discover 영화 최대 30개 조회 및 TMDB ID 중복 제거
- 장르 다중 선택 및 OR 조건 조회
- 기존 목록을 유지하는 Pull to Refresh
- 요청 실패 Dialog, 같은 장르 조건 재시도, 포스터 대체 표시
- 영화 ID의 상세 화면 및 평점 Dialog 전달

## 실행

1. 프로젝트 루트에 `.env.example`을 복사하여 `.env`를 만듭니다.
2. `TMDB_ACCESS_TOKEN`에 본인의 TMDB API Read Access Token을 입력합니다. `Bearer ` 접두사는 넣지 않습니다.
3. 다음 명령을 실행합니다.

```bash
flutter pub get
flutter run
```

`.env`는 Flutter asset으로 사용되지만 Git에서는 제외합니다.
실제 토큰이 없는 `.env.example`만 공유합니다.
평점과 즐겨찾기는 화면 내 상태이며 자체 API 저장은 아직 연결하지 않았습니다.

## 검증

```bash
flutter analyze
flutter test
```

일반 테스트는 테스트용 Service를 사용합니다. 실제 API 테스트는 기본적으로 건너뜁니다.
유효한 로컬 `.env`와 네트워크가 있을 때 아래 명령으로 별도 실행할 수 있습니다.

```bash
flutter test --dart-define=TMDB_LIVE_TEST=true test/tmdb_popular_live_test.dart
flutter test --dart-define=TMDB_LIVE_TEST=true test/tmdb_required_live_test.dart
flutter test --dart-define=TMDB_LIVE_TEST=true test/tmdb_failure_live_test.dart
flutter test --dart-define=dart.vm.product=true test/tmdb_logging_mode_test.dart
```

실패 재현 테스트는 실제 `.env`를 수정하지 않고 테스트용 잘못된 토큰을 사용합니다.
실패 로그 파일 저장이 필요한 경우에만 `--dart-define=TMDB_WRITE_EVIDENCE=true`를 추가합니다.
`docs/`의 학습 기록·캡처·로그는 로컬에만 보관하고 Git에서는 제외합니다.
