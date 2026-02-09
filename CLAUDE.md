# DLoop Rider Prototype - Project Context

## Repository
- **Repo**: https://github.com/creamoj-ai/dloop_rider_prototype.git
- **Related app repo**: https://github.com/creamoj-ai/dloop_rider_app.git (full app with Riverpod, flavors, Supabase)

## Supabase Backend
- **URL**: https://aqpwfurradxbnqvycvkm.supabase.co
- **Anon Key**: sb_publishable_NBWU-byCV0TIsj5-8Mixog_CEV7IkrB
- **Account**: creamoj@gmail.com

## Tech Stack
- Flutter (web + Android)
- Google Fonts (Inter)
- GoRouter for navigation
- Supabase for auth/backend
- StatelessWidget (no Riverpod in prototype)

## Project Structure
```
lib/
  main.dart
  theme/tokens.dart          # AppColors, theme tokens
  navigation/
    app_router.dart           # GoRouter routes
    app_shell.dart            # Bottom nav (Home, Earn, Grow, Market, You)
  screens/
    you/
      you_screen.dart         # Profile page main layout
      widgets/
        profile_header.dart   # Avatar, name, level badge
        gamification_card.dart # Streak + Badge count
        lifetime_stats.dart   # 3 key stats + menu (Settings, Support, Logout)
  widgets/
    dloop_top_bar.dart        # Shared top bar
    dloop_card.dart           # Shared card container
    invite_sheet.dart         # Invite friends bottom sheet
    header_sheets.dart        # Search, Notifications, QuickActions sheets
```

## Routes
- `/` - Home
- `/earn` - Earn mode
- `/grow` - Grow mode
- `/market` - Market
- `/you` - Profile page

## Branches

### `master` - Original version
Base prototype with all features.

### `ui/lighten-profile-page` - Profile page UX improvements (2026-02-09)
Changes made to lighten/simplify the Profile ("You") page:

**profile_header.dart**:
- Removed XP progress bar (2450/3000 XP) and labels
- Removed "Membro dal Gen 2024" text
- Kept: avatar, name, "Livello 12 Rider" badge

**you_screen.dart**:
- Added centered "OGGI" label above today snapshot pills (Ordini/Ore/Guadagno)
- Reordered sections: GamificationCard -> LifetimeStats -> InviteSection

**gamification_card.dart**:
- Removed duplicate "Livello" stat (already shown in header)
- Removed horizontal badge list (9px font, illegible)
- Kept: Streak (12 giorni) + Badge count (8/20)

**lifetime_stats.dart**:
- Reduced grid from 6 stats to 3
- Kept: Ordini totali (1.247), Guadagno totale (18.450), Rating medio (4.8)
- Removed: Km percorsi, Best day, Ore totali

### PR created for `ui/lighten-profile-page` -> `master`

## Parallel Work: dloop_rider_app (staging branch)
The same profile lightening was also applied to `dloop_rider_app` on `staging`:
- Commit `d0df272` pushed to `origin/staging`
- File: `lib/features/profile/presentation/profile_page.dart`
- Same changes: removed Level stat + XP bar from Gamification, reduced Lifetime Stats to 3
- Also committed: all pages connected to live Supabase data, updated env config

## TODO
- [ ] Integrate "LE MIE TARIFFE" (My Rates) section into Profile page - feature built on itjob PC, needs to be pushed and merged
- [ ] Merge all prototype branches into a single unified version
- [ ] Run on Android (OnePlus Nord 2) for testing

## Running the App
```bash
# Web (use web-server mode if Chrome debug fails)
flutter run -d web-server --web-port=4800

# Android with flavor (dloop_rider_app only)
flutter run --flavor staging --dart-define=FLAVOR=staging
```
