# 8주차 PR 대표 화면

8주차 v7 전용 브랜치에서 Android 앱을 실행하며 촬영했습니다. JWT·Authorization 값·비밀번호 원문은 표시하지 않았습니다.

- login-failure.png: 실제 로그인 AUTH401_1 Form 오류.
- member-info.png: 신규 로그인 후 MainScreen의 GET me로 받은 회원 정보·가입일.
- nickname-duplicate.png: 실제 PATCH me 중복 409, 입력 유지.
- unsaved-changes.png: 닉네임 수정 중 변경 이탈 확인. 배경의 연결 오류는 fixture로 재현한 상태입니다.
- rating-edit.png: 현재 세션 Rating의 기존 score·comment를 채운 수정 Dialog.
- session-expired.png: 실제 무효 토큰 AUTH401_3 후 로그인 화면·만료 Snackbar.

통계는 API가 없어 —로 표시합니다. 사진·장르는 기존 워크북 예시입니다. 전체 검증 범위와 수동 검증 여부는 ../../WEEK8_CHECKLIST.md를 확인하세요.
