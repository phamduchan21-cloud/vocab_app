---
name: taste-skill-design
description: Taste-skill design rules applied — cobalt palette, no Fraunces/serif, tabbed profile
metadata:
  type: reference
---

# Taste-Skill Design Applied (2026-07-03)

Applied anti-slop frontend design rules from [[taste-skill-install]].

## Changes made to `app.dart`
- New `AppColors`: cool off-white `#F8F9FA` background, cobalt blue `#2563EB` single accent, off-black `#1A1D23` text
- Beige `#F5F1E5` / brass `#C99A3D` palette removed (banned AI tell)
- `GoogleFonts.fraunces` removed entirely — all headings now Work Sans
- Card shadows replace border-all (no `border-t`+`border-b` on every row)

## Profile Screen redesigned (`profile_screen.dart`)
- Tabbed layout: Overview / Tests / Badges / Settings
- Profile header with avatar circle + level badge
- XP progress bar with remaining count
- Overview tab: 4 stat cards + weekly bar chart
- Tests tab: links to quiz history, mini test, progress
- Badges tab: 3-column grid with locked/unlocked states
- Settings tab: change password, notifications, language, logout
- Edit profile bottom sheet (replaces placeholder snackbar)
- No Fraunces font anywhere, no em-dashes, no beige palette

## Still needed
- Connect Badges tab to real [[gamification-api]] data
- Connect Tests tab to real quiz/mock-test history
- Replace Fraunces references in remaining screens
- Update old color token references in screens/widgets
