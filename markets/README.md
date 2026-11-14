# 마켓(스토어) 등록용 아이콘 및 그래픽 리소스 (`markets/`)

`여주자전거여행-관리자` (`com.grepiu.yeoju_cy_manager`) 앱의 Google Play Store 및 Apple App Store 등록 시 바로 업로드할 수 있도록 규격별로 정리한 리소스 모음입니다.

---

## 디렉토리 구성

```text
markets/
├── README.md
├── google_play/
│   ├── app_icon_512x512.png               # Play Console 앱 아이콘 (512×512 PNG, 32-bit)
│   ├── feature_graphic_1024x500.png       # Play Console 그래픽 이미지 (1024×500 PNG)
│   └── adaptive_foreground_1024x1024.png  # Android Adaptive Icon 전경 레이어 원본 (1024×1024 투명 PNG)
├── app_store/
│   └── app_icon_1024x1024.png             # App Store Connect 앱 아이콘 (1024×1024 PNG, 알파 채널 없음)
└── common/
    ├── master_icon_1024x1024.png          # 사각 마스터 원본 (1024×1024, 투명 없음)
    ├── preview_squircle_1024x1024.png     # 라운드(Squircle) 미리보기 아이콘 (1024×1024 투명 PNG)
    └── brand_badge_512x512.png            # 웹·문서·소개 페이지용 라운드 배지 (512×512 투명 PNG)
```

---

## 스토어별 업로드 가이드

### 1. Google Play Console
- **앱 아이콘**: `google_play/app_icon_512x512.png`
  - 512 × 512 px, 32-bit PNG (Google Play가 자동으로 라운드 마스크를 적용하므로 정사각 풀 블리드 원본으로 제공)
- **그래픽 이미지 (Feature Graphic)**: `google_play/feature_graphic_1024x500.png`
  - 1024 × 500 px, 알파 채널 없는 RGB PNG
- **앱 내부 Android 런처 아이콘**:
  - `android/app/src/main/res/mipmap-*/ic_launcher.png` 및 `ic_launcher_foreground.png`
  - `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (Adaptive Icon 적용 완료)

### 2. Apple App Store Connect
- **App Store 아이콘**: `app_store/app_icon_1024x1024.png`
  - 1024 × 1024 px, RGB PNG (알파 채널·투명 모서리 미포함 — Apple 심사 정책 준수)
- **앱 내부 iOS 번들 아이콘**:
  - `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 전 해상도 반영 완료

### 3. 기타 플랫폼
- **macOS**: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Windows**: `windows/runner/resources/app_icon.ico`
- **Web PWA**: `web/favicon.png`, `web/icons/Icon-*.png`
