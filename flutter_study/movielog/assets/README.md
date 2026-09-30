# MovieLog Flutter Asset Pack

Flutter 워크북 1~3주차에서 공통으로 사용하는 실습용 Asset입니다.

## 구성

```text
assets/
├── fonts/
│   └── Manrope-VariableFont_wght.ttf
├── logos/
│   ├── movielog_logo.svg
│   └── movielog_logo.png
├── icons/
│   ├── arrow_back.svg
│   ├── bookmark.svg
│   ├── check_circle.svg
│   ├── error.svg
│   ├── home.svg
│   ├── info.svg
│   ├── movie.svg
│   ├── person.svg
│   ├── search.svg
│   ├── share.svg
│   ├── star.svg
│   ├── visibility.svg
│   └── visibility_off.svg
└── images/
    ├── profile/
    │   └── profile_movielog.jpg
    └── posters/
        ├── hero_under_the_starlight.jpg
        ├── poster_abyss_walker.jpg
        ├── poster_echoes_of_the_void.jpg
        ├── poster_fourth_afternoon.jpg
        ├── poster_night_shadows.jpg
        └── poster_whispering_woods.jpg
```

프로젝트 루트에 이 폴더의 `assets` 디렉터리를 복사한 뒤 `pubspec-snippet.yaml` 내용을 프로젝트의 `pubspec.yaml`에 반영합니다.

## SVG 패키지

```bash
flutter pub add flutter_svg
```

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/icons/search.svg',
  width: 24,
  height: 24,
)
```

MovieLog 로고도 SVG로 사용할 수 있습니다.

```dart
SvgPicture.asset(
  'assets/logos/movielog_logo.svg',
  width: 48,
  height: 48,
)
```

`flutter_svg` 없이 간단히 사용하려면 PNG를 선택합니다.

```dart
Image.asset(
  'assets/logos/movielog_logo.png',
  width: 48,
  height: 48,
)
```

## 이미지

```dart
Image.asset(
  'assets/images/posters/poster_abyss_walker.jpg',
  fit: BoxFit.cover,
)
```

## Manrope

```dart
ThemeData(
  fontFamily: 'Manrope',
)
```

Manrope는 Latin, Cyrillic, Greek, Vietnamese 문자를 지원하지만 한글 Glyph는 포함하지 않습니다. 한글 문자열은 플랫폼의 대체 Font로 표시됩니다. 1~3주차 과제에서는 Manrope 자체를 평가 기준으로 삼지 않고 색상, 간격, 레이아웃을 기준으로 비교합니다.

## 출처와 라이선스

- Manrope: Google Fonts, SIL Open Font License 1.1
- SVG Icons: Google Material Symbols, Apache License 2.0
- 프로필·영화 이미지: 사용자의 `Remix of MovieLog` Stitch 프로젝트에서 생성된 실습용 이미지

자세한 라이선스 원문은 `licenses` 디렉터리에 포함되어 있습니다.
