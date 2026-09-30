import '../models/movie.dart';

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    secondaryGenre: '로맨스',
    year: 2024,
    durationMinutes: 124,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    averageRating: 4.5,
    reviewCount: 1245,
    moods: ['감동적인'],
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    secondaryGenre: '어드벤처',
    year: 2024,
    durationMinutes: 132,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    averageRating: 4.2,
    reviewCount: 986,
    moods: ['웅장한'],
  ),
  Movie(
    id: 3,
    title: '심연을 걷는 자',
    genre: '스릴러',
    secondaryGenre: '미스터리',
    year: 2023,
    durationMinutes: 118,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    averageRating: 4.8,
    reviewCount: 842,
    moods: ['긴장감 있는'],
  ),
  Movie(
    id: 4,
    title: '네 번째 오후',
    genre: '드라마',
    secondaryGenre: '로맨스',
    year: 2022,
    durationMinutes: 111,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    averageRating: 4.4,
    reviewCount: 576,
    moods: ['따뜻한'],
  ),
  Movie(
    id: 5,
    title: '밤의 그림자',
    genre: '미스터리',
    secondaryGenre: '스릴러',
    year: 2024,
    durationMinutes: 126,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    averageRating: 3.8,
    reviewCount: 731,
    moods: ['어두운'],
  ),
  Movie(
    id: 6,
    title: '속삭이는 숲',
    genre: '애니메이션',
    secondaryGenre: '판타지',
    year: 2023,
    durationMinutes: 103,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    averageRating: 4.9,
    reviewCount: 1102,
    moods: ['몽환적인'],
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
