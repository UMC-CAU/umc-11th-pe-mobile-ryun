import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/profile/member_ratings_screen.dart';
import 'package:movielog/register_screen.dart';

class FakeMemberApi extends MemberApiService {
  Completer<bool>? nicknameResponse;
  final requests = <String>[];
  @override
  Future<bool> checkNickname(String nickname) async {
    requests.add('nickname:$nickname');
    return nicknameResponse == null
        ? nickname != '수현'
        : nicknameResponse!.future;
  }

  @override
  Future<bool> checkEmail(String email) async {
    requests.add('email:$email');
    return email != 'noco@umc.com';
  }

  @override
  Future<MemberRatingPage> getRatings({
    required int memberId,
    int page = 0,
    int size = 10,
  }) async {
    requests.add('ratings:$memberId:$page:$size');
    if (memberId == 999) {
      throw const MemberApiException('존재하지 않는 회원입니다.', statusCode: 404);
    }
    final all = [
      MemberRating(
        ratingId: 2,
        movieId: 155,
        score: 4,
        comment: '다시 봐도 명작',
        createdAt: DateTime(2026, 10, 28),
      ),
      MemberRating(
        ratingId: 1,
        movieId: 550,
        score: 5,
        comment: '최고의 영화!',
        createdAt: DateTime(2026, 10, 28),
      ),
    ];
    return MemberRatingPage(
      content: all.skip(page * size).take(size).toList(),
      page: page,
      size: size,
      totalElements: 2,
      totalPages: (2 / size).ceil(),
      first: page == 0,
      last: (page + 1) * size >= 2,
    );
  }
}

void main() {
  late FakeMemberApi service;
  setUp(() {
    service = FakeMemberApi();
  });
  tearDown(() {
    service.close();
  });

  Future<void> wideScreen(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();
  }

  testWidgets('회원가입 화면에서 기존 닉네임과 이메일의 중복을 표시한다', (tester) async {
    await wideScreen(tester, RegisterScreen(memberService: service));
    await tester.enterText(find.byKey(const Key('nicknameField')), '수현');
    await tester.pump();
    await tester.tap(find.byKey(const Key('nicknameCheckButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emailField')), 'noco@umc.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('emailCheckButton')));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(service.requests, ['nickname:수현', 'email:noco@umc.com']);
    await tester.enterText(find.byKey(const Key('nicknameField')), '새닉네임');
    await tester.pump();
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    await tester.tap(find.byKey(const Key('nicknameCheckButton')));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
  });

  testWidgets('값을 수정한 뒤 도착한 과거 중복 응답은 무시한다', (tester) async {
    service.nicknameResponse = Completer<bool>();
    await wideScreen(tester, RegisterScreen(memberService: service));
    await tester.enterText(find.byKey(const Key('nicknameField')), '수현');
    await tester.pump();
    await tester.tap(find.byKey(const Key('nicknameCheckButton')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('nicknameField')), '다른닉네임');
    await tester.pump();
    service.nicknameResponse!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    expect(find.text('확인 중...'), findsNothing);
  });

  testWidgets('평점 화면에서 페이지 크기 변경과 다음 페이지 이동이 동작한다', (tester) async {
    await wideScreen(tester, MemberRatingsScreen(memberService: service));
    expect(find.text('영화 #155'), findsOneWidget);
    expect(find.text('영화 #550'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ratingsPageSize')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1개').last);
    await tester.pumpAndSettle();
    expect(find.text('영화 #155'), findsOneWidget);
    expect(find.text('영화 #550'), findsNothing);
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('영화 #550'), findsOneWidget);
    expect(find.text('영화 #155'), findsNothing);
    expect(service.requests.last, 'ratings:1:1:1');
  });

  testWidgets('존재하지 않는 회원의 서버 오류를 화면에 표시한다', (tester) async {
    await wideScreen(tester, MemberRatingsScreen(memberService: service));
    await tester.enterText(find.byKey(const Key('ratingsMemberId')), '999');
    await tester.pump();
    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();
    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
    expect(find.text('영화 #155'), findsNothing);
  });
}
