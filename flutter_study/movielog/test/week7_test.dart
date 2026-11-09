import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

Map<String, Object?> envelope(int status, String message, [Object? result]) => {
  'isSuccess': status < 400,
  'code': 'COMMON$status',
  'message': message,
  'result': result,
};

Dio fakeWorkbook(FutureOr<(int, Object?)> Function(RequestOptions) respond) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) async {
        final (status, data) = await respond(request);
        final response = Response<dynamic>(
          requestOptions: request,
          statusCode: status,
          data: data,
        );
        if (status >= 400) {
          handler.reject(
            DioException.badResponse(
              statusCode: status,
              requestOptions: request,
              response: response,
            ),
          );
        } else {
          handler.resolve(response);
        }
      },
    ),
  );
  return dio;
}

void main() {
  test('signup requires both current checks, preserves password bytes, and routes only password 400 to the field', () async {
    final seen = <RequestOptions>[];
    final pending = Completer<(int, Object?)>();
    var answer = pending.future;
    final service = SignUpService(
      fakeWorkbook((request) {
        seen.add(request);
        if (request.method == 'GET') return (200, {'available': true});
        return answer;
      }),
    );
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    const payload = CreateMemberRequest(
      email: ' new@example.com ',
      password: 'Abc1234! ',
      nickname: ' 테스트 ',
    );
    vm.onNicknameChanged(payload.nickname);
    vm.onEmailChanged(payload.email);
    await vm.submit(payload);
    expect(seen, isEmpty);
    await vm.checkNickname(payload.nickname);
    await vm.checkEmail(payload.email);
    final submitting = vm.submit(payload);
    expect(vm.isSubmitting, isTrue);
    await vm.submit(payload);
    pending.complete((400, envelope(400, '비밀번호 형식을 확인해 주세요.')));
    await submitting;
    expect(vm.passwordErrorText, contains('비밀번호'));
    expect(vm.snackbarMessage, isNull);
    expect(seen.where((r) => r.method == 'POST'), hasLength(1));
    expect(seen.last.path, '/v6/members');
    expect(seen.last.data, {
      'email': 'new@example.com',
      'nickname': '테스트',
      'password': 'Abc1234! ',
    });
    vm.onPasswordChanged();
    expect(vm.passwordErrorText, isNull);
    answer = Future.value((400, envelope(400, '입력값을 확인해 주세요.')));
    await vm.submit(payload);
    expect(vm.snackbarMessage, '입력값을 확인해 주세요.');
    expect(vm.passwordErrorText, isNull);
    answer = Future.value((409, envelope(409, '이미 사용 중인 이메일입니다.')));
    await vm.submit(payload);
    expect(vm.snackbarMessage, '이미 사용 중인 이메일입니다.');
    vm.onEmailChanged('different@example.com');
    expect(vm.snackbarMessage, isNull);
    expect(vm.canSubmit, isFalse);
  });

  test('rating POST permits null result; PATCH refresh retry only sends GET; DELETE 204 has no body', () async {
    final calls = <String>[];
    var failRead = false;
    int? editErrorStatus;
    var count = 1;
    final dio = fakeWorkbook((request) {
      calls.add('${request.method} ${request.path}');
      switch (request.method) {
        case 'POST':
          expect(request.data, {'movieId': 550, 'score': 4});
          return (201, envelope(201, '등록'));
        case 'PATCH':
          if (editErrorStatus == 403) {
            return (403, envelope(403, '내 평점만 수정할 수 있습니다.'));
          }
          if (editErrorStatus != null) {
            return (editErrorStatus, 'invalid body');
          }
          expect(request.data, {'score': 5, 'comment': null});
          failRead = true;
          return (200, envelope(200, '수정'));
        case 'DELETE':
          count = 0;
          return (204, null);
        default:
          if (failRead) {
            failRead = false;
            return (500, 'failed');
          }
          return (
            200,
            List.generate(
              count,
              (_) => {
                'ratingId': 7,
                'movieId': 550,
                'score': 5,
                'comment': null,
                'createdAt': '2026-11-07T00:00:00Z',
              },
            ),
          );
      }
    });
    final api = RatingApiService(dio);
    await api.createRating(
      memberId: 19,
      request: const CreateRatingRequest(movieId: 550, score: 4, comment: ' '),
    );
    final movies = TmdbMovieService(fakeWorkbook((_) => (404, null)));
    final vm = MyRatingsViewModel(api, movies, 19);
    addTearDown(vm.dispose);
    await vm.updateRating(ratingId: 7, score: 5);
    expect(vm.refreshWarning, contains('저장은 완료'));
    expect(vm.status, MyRatingsLoadStatus.error);
    await vm.load();
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.refreshWarning, isNull);
    expect(calls.take(4), [
      'POST /v6/members/19/ratings',
      'PATCH /v6/members/19/ratings/7',
      'GET /v6/members/19/ratings',
      'GET /v6/members/19/ratings',
    ]);
    editErrorStatus = 403;
    await expectLater(
      vm.updateRating(ratingId: 7, score: 5),
      throwsA(isA<DioException>()),
    );
    expect(calls.last, 'GET /v6/members/19/ratings');
    expect(vm.message, '내 평점만 수정할 수 있습니다.');
    for (final (status, message) in [
      (400, '평점이나 코멘트의 입력 형식을 확인해 주세요.'),
      (404, '요청한 회원 또는 평점을 찾을 수 없습니다.'),
      (409, '이미 등록된 평점이 있습니다. 내 평점 목록을 확인해 주세요.'),
    ]) {
      editErrorStatus = status;
      await expectLater(
        vm.updateRating(ratingId: 7, score: 5),
        throwsA(isA<DioException>()),
      );
      expect(vm.message, message);
      expect(
        calls.last,
        status == 404
            ? 'GET /v6/members/19/ratings'
            : 'PATCH /v6/members/19/ratings/7',
      );
    }
    await vm.deleteRating(7);
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(calls.skip(calls.length - 2), [
      'DELETE /v6/members/19/ratings/7',
      'GET /v6/members/19/ratings',
    ]);
  });
}
