# 9주차 PR 실행 화면

Required 화면은 2026-11-23, Challenge 화면은 2026-11-19 Android 에뮬레이터의 실제 v8/TMDB 연동으로 확인한 최신 UI 화면이다.

- favorite-added: 실제 즐겨찾기 등록 후 아이콘·안내
- favorites-list / favorites-return-empty: 목록 결합과 상세 해제 후 복귀 재조회
- partial-movie-error: TMDB 한 건 실패를 주입해도 다른 카드 유지
- same-page-retry: 다음 page 실패 주입 후 기존 카드·같은 page 재시도 유지
- search-results: 제출 검색의 실제 결과
- record-input-retained: 통합 저장 전송 실패를 주입한 뒤 입력 유지
- record-saved: 실제 통합 저장 성공 후 Snackbar·북마크 동기화

실패 화면은 fixture로 재현했으며 실제 서버 장애를 뜻하지 않는다. API 호출·오류 분기 확인은 자동 테스트 및 Android 자동 조작 시나리오로 진행했다. 사람의 직접 수동 조작과 구분한다. 전체 영상·학습 노트·민감값을 제외한 상세 로그는 로컬 docs/week9/에 보관하며 .env는 커밋하지 않는다.
