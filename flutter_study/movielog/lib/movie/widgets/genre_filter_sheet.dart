import 'package:flutter/material.dart';

import '../../data/models/tmdb_genre_dto.dart';
import '../../theme/app_colors.dart';

// Reused from the week-3 BottomSheet, with TMDB IDs as selection values.
class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelectedGenres,
  });

  final List<TmdbGenreDto> genres;
  final Set<int> initialSelectedGenres;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<int> _draftGenres = Set.of(widget.initialSelectedGenres);

  void _toggleGenre(int genre, bool selected) {
    setState(() {
      if (selected) {
        _draftGenres.add(genre);
      } else {
        _draftGenres.remove(genre);
      }
    });
  }

  void _applyFilter() {
    Navigator.of(context).pop(Set<int>.of(_draftGenres));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '장르 필터',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '여러 장르를 선택할 수 있어요',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(left: 8, right: 20),
                  itemCount: widget.genres.length,
                  itemBuilder: (context, index) {
                    final genre = widget.genres[index];
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _draftGenres.contains(genre.id),
                      title: Text(genre.name),
                      onChanged: (value) =>
                          _toggleGenre(genre.id, value ?? false),
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('applyGenreFilterButton'),
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
