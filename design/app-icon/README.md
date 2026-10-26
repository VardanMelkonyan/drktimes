# drktimes app icon

The mark is a lowercase **d** set in JetBrains Mono ExtraBold, converted to outlines, followed by an amber block cursor.

Colours: ground `#0D0C0A`, paper `#ECE6D8`, amber `#F2A93B`.

## Flutter, the quick route

1. Copy `flutter/assets/icon/` into your project.
2. Copy `flutter/flutter_launcher_icons.yaml` into your project too, or merge its contents into `pubspec.yaml`.
3. Run `dart run flutter_launcher_icons`.

That generates the iOS icon set and the Android adaptive icon, including the themed (monochrome) layer.

## iOS

| File | Use |
|---|---|
| `ios/AppIcon-1024.png` | Any / Light appearance. 1024 × 1024, opaque, no alpha, square corners (iOS applies the mask). Xcode builds every other size from this one image. |
| `ios/AppIcon-Dark-1024.png` | Dark appearance. Transparent background, so the system's dark background shows through. |
| `ios/AppIcon-Tinted-1024.png` | Tinted appearance. Grayscale, with the foreground kept near-white. |
| `ios/icon-composer/*.svg` | Background, letter and cursor as separate full-canvas layers. Drag them into Icon Composer if you want the Liquid Glass `.icon` file. Glass is optional; turn it off for the flat look. |
| `ios/alternate/AppIcon-Safelight-1024.png` | Optional alternate icon in the red channel only, for a "darkroom" icon choice. |

## Android

| File | Use |
|---|---|
| `android/app/src/main/res/…` | Drop-in resources. Includes the adaptive icon (`mipmap-anydpi-v26`) with background, foreground and monochrome layers as vectors, plus legacy PNGs from 48 to 192 px. |
| `android/adaptive-png/*-432.png` | The same three layers as 432 px PNGs (108 dp at xxxhdpi), for tools that want bitmaps. |
| `android/play-store-512.png` | Google Play listing icon. 512 × 512, full square; Play applies its own corner mask. |

Adaptive layers are 108 × 108 dp. The mark fits inside the central 66 dp safe zone, so no launcher mask (circle, squircle, rounded square) can clip it.

## Masters

- `svg/drktimes-icon-1024.svg`: the full icon.
- `svg/drktimes-mark-on-dark.svg`: the mark alone, on a transparent background.

The font is JetBrains Mono, licensed under the SIL Open Font License, so using its outlined letterform in a logo is allowed.
