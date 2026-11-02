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


## 백엔드 5주차 미션 연동

- `/register`: 닉네임·이메일 중복 확인 버튼이 Spring Boot API를 호출합니다.
- `/my` → 내 평점 보기 (`/my/ratings`): 회원별 평점 조회, 페이지 크기 변경 및 이전/다음 이동.
- 기본 서버 주소: `http://localhost:8080`. 필요 시 `--dart-define=BACKEND_URL=...`로 지정합니다.
- 브라우저 실행 주소는 CORS 허용 출처 `http://localhost:5173`을 사용합니다.
- 회원가입 제출은 기존 화면 전환 데모이며 회원가입/로그인 API는 이번 주차 범위가 아닙니다.

## 6주차 워크북 — Essential / Guided Practice

현재 앱의 회원가입 중복 확인과 `/my/ratings`는 워크북 v5 서버(`https://workbook.devnoco.com`)를 사용합니다.
TMDB와 별도 Dio를 사용하며, 학습용 memberId는 1로 고정합니다. 실제 회원가입·평점 저장은 호출하지 않습니다.
이전 로컬 Spring Boot용 Service/평점 화면은 기존 실습 자료로 남아 있으며 현재 앱 경로에서는 사용하지 않습니다.

개념 분배 목록과 구현·캡처 기록은 로컬 `docs/week6/`에 있습니다. 이 폴더는 기존 Git 제외 정책을 따릅니다.
6주차 미션은 아직 전달되지 않아 Required 및 최종 스터디 인증 대조는 보류합니다.
