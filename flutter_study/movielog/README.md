# MovieLog

Flutter 영화 기록 앱입니다. TMDB 영화 정보와 MovieLog 워크북 v8 JWT API를 MVVM·Provider로 연결합니다.

## 주요 기능

- 홈 인기 영화 최대 5개 표시
- Discover 영화 페이지네이션 및 TMDB ID 중복 제거
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
TMDB 영화의 평점과 즐겨찾기는 MovieLog v8에 저장합니다.

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

## 6주차 기록 — Essential / Guided Practice

6주차에는 워크북 v5의 중복 확인과 샘플 회원 1의 평점 조회를 연결했습니다.
이전 로컬 Spring Boot용 Service/평점 화면은 기존 실습 자료로 남아 있습니다.

개념 분배 목록과 구현·캡처 기록은 로컬 `docs/week6/`에 있습니다. 이 폴더는 기존 Git 제외 정책을 따릅니다.

## 7주차 워크북 — v6 회원가입과 평점 CRUD

- 회원가입 화면에서 닉네임·이메일 중복 확인을 마치고 가입하면 영화 목록으로 이동합니다.
- 영화 상세에서 별점 1~5점과 선택 코멘트를 등록합니다. `/my/ratings`에서는 현재 학습용 회원의 평점을 조회·수정·삭제합니다.
- 가입 응답의 memberId는 실행 중 메모리에만 보관합니다. 앱을 다시 시작하면 사라집니다.
- [워크북 Swagger](https://workbook.devnoco.com/docs)의 v6 명세를 사용합니다. MovieLog API 요청에는 TMDB 토큰이 포함되지 않습니다.

7주차 학습 정리, 제출용 A·B 문서, Android 화면과 검증 결과는 로컬 `docs/week7/`에 보관합니다.

## 9주차 — v8 즐겨찾기·검색·페이지네이션

2026-11-19에 첨부 워크북과 기존 작업을 다시 확인하고 최신 Figma UI를 적용했습니다. 개념·Guided A/B·Required A~D·Challenge A~C 각각의 작업 내용, 문제와 해결, 코드·결과 캡처는 로컬 `docs/week9/refresh-2026-11-19/README.md`에서 확인합니다.

- JWT 로그인과 보안 저장소 세션 복원을 사용합니다. 보호용 MovieLog Client는 지정 호스트의 v8 보호 API에만 JWT를 붙입니다.
- 영화 상세의 북마크로 즐겨찾기를 등록·해제하고, 마이페이지의 내 즐겨찾기에서 TMDB 영화 정보를 함께 표시합니다. 상세에서 돌아오면 목록을 다시 조회합니다.
- 영화 목록은 첫 페이지부터 시작하며 하단에 가까워지면 다음 페이지를 불러옵니다. 실패 시 기존 카드를 유지하고 같은 페이지를 수동 재시도합니다.
- 영화 검색은 별도 화면·상태를 사용하며 제출 또는 입력 후 500ms에 검색합니다. 장르·검색 변경과 계정 전환 뒤 늦은 응답은 반영하지 않습니다.
- 평점 Dialog의 선택 체크박스로 평점·즐겨찾기를 `/v8/movie-records`에서 한 번에 저장합니다. 이미 즐겨찾기한 영화는 `/v8/ratings`로 평점만 저장합니다.
- v8에는 인증된 사용자의 전체 평점 GET이 없습니다. 평점 화면은 현재 로그인 세션에서 저장한 응답을 표시하며 재로그인·앱 재시작 뒤에는 비워집니다. JWT를 해석해 memberId를 추측하지 않습니다.

기본 실행은 Challenge 기능을 포함합니다. Required의 제출 검색·더 보기 화면은 다음 명령으로 실행할 수 있습니다.

```bash
flutter run --dart-define=WEEK9_CHALLENGE=false
```

학습 순서, 작업 내용·애로사항·해결 방법과 Android 캡처는 로컬 `docs/week9/practice-record.md`에 정리합니다. 이전 v6 서비스의 기본값은 기존 주차 단위 테스트용으로 유지하고 실제 앱에서는 v8 구성을 주입합니다.
## 8주차 — v7 인증·프로필·세션

8주차 화면은 아래 명령으로 실행합니다.

```bash
flutter run --dart-define=STUDY_WEEK=8
```

- v7 JWT 로그인, Android secure storage, GET me 검증 뒤 세션 복원과 실패 재시도
- 내 정보·가입일, 닉네임 수정(2~12자·409·네트워크 재시도), 변경 이탈 확인
- 현재 로그인 세션의 v7 평점 등록·수정·삭제, 만료 안내, 로그아웃 및 보호 화면 차단
- 이메일 저장 체크박스(SharedPreferences에는 이메일만 저장)
- 8주차 실행에서는 검색·즐겨찾기·북마크·통합 저장을 제외합니다. 기본 실행은 9주차 v8입니다.

학습 정리와 Android 인증 자료는 로컬 `docs/week8/practice-record.md` 및 `study-certification-checklist.md`에서 확인합니다. `docs/`는 기존 Git 제외 정책을 유지합니다.


## 10주차 — Android 릴리스와 앱 정보

- MovieLog 표시명, 1.0.0+1 버전, dev.umc.movielog 식별자를 사용합니다.
- flutter_launcher_icons / flutter_native_splash로 기존 MovieLog 로고를 사용하는 아이콘·네이티브 Splash를 생성합니다. 생성 도구는 dev_dependencies입니다.
- 마이페이지 ⓘ → /my/about에서 설치된 앱의 버전과 공식 TMDB 로고·출처, 사용자 에셋 라이선스를 확인합니다.
- Android release는 android/key.properties의 upload 키로 서명하며 debug 키로 대체하지 않습니다. key.properties와 keystore는 Git 제외 대상입니다. Windows의 한글 경로도 UTF-8로 읽습니다.
- 개인 키를 준비한 뒤 flutter build apk --release 및 flutter build appbundle --release로 빌드합니다. 서명키가 없으면 로컬 android/key.properties를 먼저 구성해야 합니다.
- APK: build/app/outputs/flutter-apk/app-release.apk / AAB: build/app/outputs/bundle/release/app-release.aab
- .env는 Git 제외 대상이지만 앱 asset에 들어갑니다. APK를 공유하면 TMDB 읽기 토큰도 전달되므로 바이너리는 공개 저장소에 올리지 않습니다.
- 학습 기록·캡처·영상·검증 로그는 로컬 docs/week10/에 보관합니다. Windows 환경에서 iOS 빌드/시뮬레이터 및 공개 스토어 배포는 검증 범위 밖입니다.
