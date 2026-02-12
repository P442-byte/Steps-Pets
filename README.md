# Steps & Pets 🐾

A fitness-focused pet collection mobile game where walking hatches eggs into adorable pets!

## Concept

Walk in real life → Incubate eggs → Hatch unique pets → Collect them all!

Think Pokémon GO meets Tamagotchi, but simpler and focused on the joy of collecting.

## Features

### MVP (Current)
- ✅ Step tracking via Google Fit / Apple HealthKit
- ✅ Egg incubation system (walk to hatch)
- ✅ 5 starter pets with different elements
- ✅ Pet collection gallery
- ✅ Pet leveling (XP from walking)
- ✅ Daily step goals & streak tracking
- ✅ Beautiful dark theme UI with animations

### Planned
- [ ] More pets and egg types
- [ ] Garden/habitat decoration
- [ ] Pet evolution system
- [ ] Daily challenges
- [ ] Achievements
- [ ] Social features (trading, battles)
- [ ] Cosmetic shop
- [ ] Ad rewards

## Tech Stack

- **Framework**: Flutter 3.24+
- **State Management**: Provider
- **Local Storage**: Hive
- **Health Data**: health package (Google Fit / HealthKit)
- **Animations**: flutter_animate

## Getting Started

### Prerequisites
- Flutter 3.24 or higher
- Android Studio (for Android builds)
- Xcode (for iOS builds, macOS only)

### Setup

```bash
# Clone the repo
cd steps_and_pets

# Get dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run
```

### Running on Different Platforms

```bash
# Web (for quick testing - step tracking won't work)
flutter run -d chrome

# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── models/              # Data models (Pet, Egg, UserProgress)
│   ├── providers/           # State management (GameProvider)
│   ├── services/            # Business logic (Storage, StepTracking)
│   └── theme/               # App theming
├── features/
│   ├── home/                # Home dashboard
│   ├── incubation/          # Egg hatching screen
│   ├── pets/                # Pet collection gallery
│   └── shell/               # Main app shell with navigation
└── shared/
    └── widgets/             # Reusable UI components
```

## Starter Pets

| Pet | Element | Egg Steps | Rarity |
|-----|---------|-----------|--------|
| Flameling | 🔥 Fire | 10 | Common |
| Bublet | 💧 Water | 20 | Common |
| Rocklet | 🌍 Earth | 40 | Common |
| Zephyr | 💨 Air | 70 | Uncommon |
| Phantling | ✨ Spirit | 100 | Rare |

## Development Notes

### Mock Mode
The app includes a `MockStepTrackingService` for development/testing without real health data. The "Add 50 Steps" debug button uses this.

### Health Permissions
For real step tracking:
- **Android**: Add to `AndroidManifest.xml` activity recognition permissions
- **iOS**: Add HealthKit capabilities and privacy descriptions

## License

MIT License - feel free to use this as a starting point for your own project!

## Contributing

Pull requests welcome! Please read the contributing guidelines first.
