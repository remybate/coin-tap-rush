# Coin Tap Rush — branding assets

Add the PNG files below before exporting to Android. Paths match `export_presets.cfg` and `project.godot` boot splash settings.

All images should be **PNG**. Use sRGB. Avoid tiny text at the edges of adaptive icons (Android crops to a circle/squircle).

---

## 1. Android launcher icons

Place these files in `assets/branding/android/`:

| File | Size | Required | Notes |
|------|------|----------|--------|
| `icon_192.png` | **192×192** px | Yes | Standard launcher icon. |
| `adaptive_foreground_432.png` | **432×432** px | Yes | Logo / main art. Keep important content in the center **~66%** “safe zone”; edges may be clipped. Transparency is OK. |
| `adaptive_background_432.png` | **432×432** px | Yes | Flat color or simple pattern behind the foreground. Usually no transparency. |
| `adaptive_monochrome_432.png` | **432×432** px | No | Android 13+ themed icon (single-color silhouette). Leave unset in export preset until you add this file. |

**Workflow tip:** Design one **1024×1024** master, then export each size above. Foreground and `icon_192` can share the same artwork; background is often a solid brand color.

After adding files, open the project in Godot so imports run, then check **Project → Export → Android → Launcher Icons** if anything looks wrong.

---

## 2. Boot splash screen

| File | Size | Required | Notes |
|------|------|----------|--------|
| `splash.png` | **1080×1920** px | Yes | Portrait splash (matches game viewport). Path: `assets/branding/splash.png` |

Configured in **Project Settings → Application → Boot Splash** (`fullsize` off — image is centered, not stretched to fill). Use a centered logo or title; letterbox areas use the boot splash background color in `project.godot`.

---

## Checklist

- [ ] `assets/branding/android/icon_192.png`
- [ ] `assets/branding/android/adaptive_foreground_432.png`
- [ ] `assets/branding/android/adaptive_background_432.png`
- [ ] `assets/branding/splash.png`
- [ ] (Optional) `assets/branding/android/adaptive_monochrome_432.png`

**Release signing:** Do not commit `.keystore` / `.jks` files (see root `.gitignore`). Configure release keystore in Godot **Export → Android → Keystore** or via environment variables.
