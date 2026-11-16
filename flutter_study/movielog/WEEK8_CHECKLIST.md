# 8주차 최종 체크리스트

대상: feature/week-8 · 워크북 v7 · Android 에뮬레이터

- [x] 비밀번호를 저장하거나 로그에 남기지 않습니다.
- [x] 보호 대상 host/path에만 Bearer를 붙입니다.
- [x] 로그인 401·보호 401·403을 구분합니다.
- [x] 앱 재시작은 GET me 검증 뒤 signedIn이 됩니다. 신규 로그인은 토큰 저장 뒤 MainScreen.loadMember()로 내 정보를 불러옵니다.
- [x] 네트워크 실패에 토큰을 자동 삭제하지 않습니다.
- [x] v7 경로·parser·status·error code를 함께 변경했습니다.
- [x] TMDB Token과 MovieLog JWT를 서로 다른 Client에만 보냅니다.
- [x] 평점 movieId로 TMDB 영화 정보를 연결하며 없는 정보는 placeholder 처리합니다.
- [x] 로그아웃/회원 전환 뒤 이전 응답을 무시합니다.
- [x] 내 평점 전체 복원 계약의 한계를 문서화했습니다.
- [x] 선택한 실제 플랫폼에서 secure storage를 검증했습니다.
- [ ] flutter analyze와 Guided/Required 수동 검증 결과를 기록했습니다. 별도 제공되지 않은 자동 테스트 작성을 제출 조건으로 요구하지 않습니다.

마지막 항목의 정적 분석과 Android Guided/Required 시나리오 기록은 완료했습니다. 다만 사람의 직접 수동 조작 여부는 확인하지 못해 원문 체크는 미완료로 남겼습니다. 자동 조작 검증과 직접 수동 검증을 구분합니다.

## 검증 근거

| 항목 | 결과·근거 |
| --- | --- |
| 정적 분석 | flutter analyze --no-pub: No issues found |
| 전체 단위·위젯 테스트 | 93개 통과, 선택형 TMDB 실서버 테스트 3개 skip |
| 인증 전용 테스트 | test/week8_test.dart: 13개 통과 |
| 신규 로그인 순서 | 저장소 저장 전에는 로그인 미확정, 로그인 안에서 GET me 호출 0회, loadMember에서 1회 호출 검증 |
| 실제 Android Guided/Required | 실제 v7/TMDB 응답으로 로그인 실패·성공, 프로필 수정·중복, 평점 CRUD, 무효 토큰·로그아웃·보호 경로 차단 |
| 보안 저장소 | Android write/read/delete 및 force-stop 후 새 프로세스 read → GET me → 홈 |
| 오류 재현 | 프로필 PATCH·세션 복원 GET me·내 정보 GET me 연결 오류는 fixture, 이후 재시도는 실제 서버 응답 |
| 세션 경계 | 동시 401 한 번 정리, 403 유지, 늦은 이전 세션 응답·저장소 실패 자동 테스트 |

AuthStatus 역할은 AuthSession의 initialized/authenticated/busy/restoreFailed/memberStatus가 담당합니다. 신규 로그인과 재시작 복원을 분리합니다. 앱 재설치 검증이 아니며 iOS/Windows 저장소는 미검증입니다. 서버 TTL까지 기다린 만료 검증 대신 실제 무효 토큰 AUTH401_3과 AUTH401_2/3/4 분기 테스트를 사용했습니다.

## API 계약의 한계

v7 로그인·GET me에는 memberId가 없고, 토큰 기반 내 전체 평점 GET도 없습니다. JWT claim을 추측하지 않고 현재 로그인 세션에서 받은 Rating만 수정·삭제합니다. 재시작 후 전체 내 평점 복원을 완료 기능으로 표시하지 않습니다. 공개 유저별 조회는 memberId 경로와 공개 Client를 유지합니다.

## 실행 화면과 로그 보관

대표 캡처는 pr-evidence/week8/에 PR 검토용으로 포함합니다. 원본 영상·전체 학습 노트·민감값을 제외한 상세 로그는 기존 정책대로 로컬 docs/week8/에 보관하고 커밋하지 않습니다. .env와 실제 토큰·비밀번호·생성 계정 자격 증명은 포함하지 않습니다.
