import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

class Checks implements MemberAvailabilityService {
  final requests = <Completer<bool>>[];
  @override
  Future<bool> checkNickname(String value) {
    final result = Completer<bool>();
    requests.add(result);
    return result.future;
  }

  @override
  Future<bool> checkEmail(String value) => checkNickname(value);
}

class Ratings extends RatingApiService {
  Ratings() : super(Dio());
  List<RatingDto> result = [];
  DioException? error;
  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    expect(memberId, 1);
    if (error != null) throw error!;
    return result;
  }
}

class Movies extends TmdbMovieService {
  Movies() : super(Dio());
  int calls = 0;
  bool fail = false;
  @override
  Future<TmdbMovieDto?> findMovieById(int id) async {
    calls++;
    if (fail) throw DioException(requestOptions: RequestOptions());
    return null;
  }
}

void main() {
  test('nullable comment and raw rating JSON', () {
    final rating = RatingDto.fromJson({
      'ratingId': 1,
      'movieId': 550,
      'score': 5,
      'comment': null,
      'createdAt': '2026-09-06T12:14:03.000Z',
    });
    expect(rating.comment, isNull);
    expect(rating.movieId, 550);
    expect(rating.createdAt.isUtc, isTrue);
  });
  test(
    'field isolation, duplicate recall, A-B-A stale response, disposal',
    () async {
      final service = Checks();
      final vm = SignUpViewModel(service);
      vm.onNicknameChanged('수현');
      final first = vm.checkNickname('수현');
      expect(vm.nicknameCheckStatus, CheckStatus.checking);
      vm.onNicknameChanged('새닉네임');
      vm.onNicknameChanged('수현');
      final second = vm.checkNickname('수현');
      service.requests[1].complete(false);
      await second;
      service.requests[0].complete(true);
      await first;
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      vm.onNicknameChanged('변경');
      expect(vm.nicknameErrorText, isNull);
      vm.onNicknameChanged('수현');
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      expect(service.requests.length, 2);
      vm.onEmailChanged('a@example.com');
      final email = vm.checkEmail('a@example.com');
      service.requests.last.completeError(
        DioException(requestOptions: RequestOptions()),
      );
      await email;
      expect(vm.emailCheckStatus, CheckStatus.error);
      expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
      final retry = vm.checkEmail('a@example.com');
      vm.dispose();
      service.requests.last.complete(true);
      await retry;
    },
  );
  test(
    'ratings states, preserved ratings, 404 cache and transient retry',
    () async {
      final service = Ratings();
      final movies = Movies();
      final vm = MyRatingsViewModel(service, movies, sampleMemberId);
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.empty);
      final rating = RatingDto(
        ratingId: 1,
        movieId: 550,
        score: 5,
        comment: null,
        createdAt: DateTime(2026),
      );
      service.result = [rating, rating];
      movies.fail = true;
      await vm.load();
      expect(vm.ratings.length, 2);
      expect(vm.status, MyRatingsLoadStatus.success);
      expect(vm.message, isNotNull);
      movies.fail = false;
      final before = movies.calls;
      await vm.load();
      expect(movies.calls, before + 1);
      await vm.load();
      expect(movies.calls, before + 1);
      service.error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.error);
      expect(vm.message, '존재하지 않는 회원입니다.');
      vm.dispose();
    },
  );
}
