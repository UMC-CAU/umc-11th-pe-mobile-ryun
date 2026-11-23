# 9주차 최종 체크리스트

대상: feature/week-9 → feature/week-8 · 기본 v8 · Android 에뮬레이터

- [x] 영화 상세의 즐겨찾기 등록·해제·실패·재조회와 내 즐겨찾기 빈 결과를 movieId로 처리한다.
- [x] 내 즐겨찾기 진입·상세 복귀 갱신·뒤로가기와 root Navigator/하단 탭 경계를 구분한다.
- [x] 홈은 Popular API 최대 5개를 유지하고, 영화 목록은 30개 수집 제한 없이 page 단위로 이어서 조회한다.
- [x] 초기·추가·빈·오류·끝 상태를 구분하고 추가 실패 시 기존 카드와 실패한 page 번호를 유지한다.
- [x] 검색·장르 변경, 화면 dispose, 로그아웃·계정 전환에서 이전 요청의 응답·오류·finally를 반영하지 않는다.
- [x] TMDB 상세 한 건의 실패로 전체 즐겨찾기 목록을 비우지 않는다. 해당 카드만 재조회한다.
- [x] MovieLog JWT는 지정 HTTPS 호스트·보호 경로에만 붙인다. TMDB Client는 분리하고 로그의 인증 헤더는 마스킹한다.
- [ ] flutter analyze·제공된 테스트·Required **사람의 직접 수동 검증**을 기록했다.

마지막 항목의 정적 분석·테스트·실제 Android Required 시나리오 기록은 완료했다. Android 화면은 테스트 자동 조작으로 검증했으며 사람이 직접 조작한 수동 검증과 구분하므로 원문 항목은 미확인으로 남긴다.

## 검증 근거

- 최종 브랜치 `flutter analyze --no-pub`: No issues found.
- 최종 브랜치 `flutter test --no-pub`: 108개 통과, 선택형 TMDB 실서버 테스트 3개 skip. 이전 8주차 로그인 순서 회귀 테스트도 유지한다.
- `test/week9_test.dart`: 같은 page 재시도·중복 제거·마지막 page, 늦은 검색·장르 응답, dispose, 최대 5개 동시 상세 요청, 개별 카드 재시도, 계정 전환, timeout 뒤 GET 확인, 이전 세션 401, JWT 호스트 경계, 500ms debounce, 상세 Route 왕복을 검증한다.
- 실제 Android Required: v8/TMDB 응답으로 즐겨찾기 등록·해제·목록 결합·복귀 재조회·제출 검색·계정 전환과 page 재시도 검증. 의도한 실패는 fixture로 표시한다.
- Challenge A/B/C: 500ms 자동 검색, 무한 스크롤, 평점·즐겨찾기 단일 트랜잭션 저장을 구현하고 Android 시나리오 및 기존 캡처로 확인했다.

## API·환경 범위

- 즐겨찾기 DELETE는 200/result null이다. 경로의 ID는 favoriteId가 아닌 movieId다.
- FAVORITE409_1·FAVORITE404_1은 GET으로 여부를 동기화한다. AUTH401_2/3/4만 세션을 정리하고 로그인 실패·403·네트워크 실패와 구분한다.
- v8은 토큰 기반 전체 내 평점 GET을 제공하지 않는다. JWT claim에서 memberId를 추측하지 않고 현재 세션에서 저장한 평점 응답만 보관한다.
- 실제 토큰 TTL까지 기다린 만료, iOS·웹·Windows의 동일 화면·보안 저장소는 이번 검증 범위가 아니다.
- Required 실행: `flutter run --dart-define=WEEK9_CHALLENGE=false`. 기본 실행은 Challenge를 포함한다. 8주차 실행은 `--dart-define=STUDY_WEEK=8`을 사용한다.

전체 로그·학습 기록·영상은 로컬 docs/week9/에 보관한다. 대표 이미지 8장만 pr-evidence/week9/에 포함하며 .env·자격 증명·다른 스터디 변경은 커밋하지 않는다.
