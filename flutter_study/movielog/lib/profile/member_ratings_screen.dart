import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common/common_app_bar.dart';
import '../data/services/member_api_service.dart';
import '../theme/app_colors.dart';

class MemberRatingsScreen extends StatefulWidget {
  const MemberRatingsScreen({super.key, this.memberService});
  final MemberApiService? memberService;
  @override
  State<MemberRatingsScreen> createState() => _MemberRatingsScreenState();
}

class _MemberRatingsScreenState extends State<MemberRatingsScreen> {
  late final MemberApiService _service;
  final _memberController = TextEditingController(text: '1');
  MemberRatingPage? _ratings;
  String? _error;
  bool _loading = true;
  int _memberId = 1;
  int _size = 10;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.memberService ?? MemberApiService();
    _load(0);
  }

  @override
  void dispose() {
    _requestId++;
    _memberController.dispose();
    if (widget.memberService == null) _service.close();
    super.dispose();
  }

  Future<void> _load(int page) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ratings = await _service.getRatings(
        memberId: _memberId,
        page: page,
        size: _size,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _ratings = ratings;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error is MemberApiException
            ? error.message
            : '평점을 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  void _search() {
    final memberId = int.tryParse(_memberController.text.trim());
    if (memberId == null || memberId < 1) {
      setState(() => _error = '회원 번호는 1 이상의 숫자로 입력해주세요.');
      return;
    }
    _memberId = memberId;
    _load(0);
  }

  @override
  Widget build(BuildContext context) {
    final ratings = _ratings;
    return Scaffold(
      appBar: CommonAppBar(title: '내 평점', onBack: () => context.go('/my')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '내가 남긴 영화의 기록',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  '회원별 평점을 최신순으로 확인해보세요.',
                  style: TextStyle(color: AppColors.bodyText),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextField(
                        key: const Key('ratingsMemberId'),
                        controller: _memberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '회원 번호',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    FilledButton(
                      onPressed: _loading ? null : _search,
                      child: const Text('조회'),
                    ),
                    const Text('페이지당'),
                    DropdownButton<int>(
                      key: const Key('ratingsPageSize'),
                      value: _size,
                      items: [1, 5, 10]
                          .map(
                            (size) => DropdownMenuItem(
                              value: size,
                              child: Text('$size개'),
                            ),
                          )
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (size) {
                              if (size != null) {
                                _size = size;
                                _load(0);
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_loading && _error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(_error!, key: const Key('ratingsError')),
                          TextButton(
                            onPressed: () => _load(0),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_loading && _error == null && ratings != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '회원 $_memberId · 평점 ${ratings.totalElements}개',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Chip(
                        label: Text('최신순'),
                        avatar: Icon(Icons.sort, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (ratings.content.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Text(
                        '아직 남긴 평점이 없습니다.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ...ratings.content.map(
                    (rating) => Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '영화 #${rating.movieId}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '평점 #${rating.ratingId}',
                                  style: const TextStyle(
                                    color: AppColors.bodyText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (index) => Icon(
                                    index < rating.score
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: const Color(0xFFE8A032),
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${rating.score} / 5'),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              rating.comment ?? '코멘트가 없습니다.',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              rating.createdAt.toIso8601String().replaceFirst(
                                'T',
                                ' ',
                              ),
                              style: const TextStyle(
                                color: AppColors.bodyText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: ratings.first
                            ? null
                            : () => _load(ratings.page - 1),
                        child: const Text('이전'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${ratings.totalPages == 0 ? 0 : ratings.page + 1} / ${ratings.totalPages} 페이지',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: ratings.last
                            ? null
                            : () => _load(ratings.page + 1),
                        child: const Text('다음'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
