# 10주차 릴리스 실행 증거

Android 17 에뮬레이터에 lib/main.dart의 실제 release APK를 설치하고 UIAutomator/adb로 조작했습니다. TMDB와 v8 실서버 응답을 사용했으며 오류 응답을 주입하지 않았습니다.

- 정확한 PR 코드: analyze 통과, 단위·위젯 테스트 111개 통과 / 선택 실서버 테스트 3개 skip.
- APK/AAB 빌드, upload 인증서 SHA-256 일치, 설치·실행 성공.
- 로그인→홈→검색→상세→즐겨찾기 등록→내 즐겨찾기→해제→빈 목록→앱 정보→로그아웃→재실행의 14개 화면 검증 통과.
- vscode-*.jpg는 VS Code의 실제 소스·로그 창을 직접 캡처한 원본입니다. 임의로 렌더링한 코드·로그 이미지는 제외했습니다.
- android-launcher-original.png는 기존 com.example.movielog와 신규 dev.umc.movielog가 함께 보이는 실제 Android 앱 서랍 원본입니다. 동일 패키지 재설치 전후나 다양한 모양 전환을 검증한 것으로 주장하지 않습니다.
- 캡처에 사용한 이메일은 합성 학습 계정(@example.com)입니다. 토큰·JWT·비밀번호·서명키 경로는 포함하지 않습니다.
- iOS 생성 리소스와 식별자는 준비했으나 Windows 환경으로 Xcode 컴파일/시뮬레이터 실행은 미검증입니다. 스토어 업로드도 수행하지 않았습니다.

실제 APK/AAB에는 학습용 TMDB 토큰이 포함되므로 Git에 올리지 않습니다. 약 91초의 최종 PR 영상, 세션 복원 보충 영상, 상세 기록은 노션 10주차와 로컬 docs/week10/에 보관합니다.

학습 정리·영상·트러블슈팅: https://app.notion.com/p/b1d7698a8862827bb895019ec14c2278
