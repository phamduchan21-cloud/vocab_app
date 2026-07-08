---
name: VocaEng (MeuBeu)
colors:
  surface: '#FFFFFF'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#434655'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#0058be'
  on-secondary: '#ffffff'
  secondary-container: '#2170e4'
  on-secondary-container: '#fefcff'
  tertiary: '#824500'
  on-tertiary: '#ffffff'
  tertiary-container: '#a65900'
  on-tertiary-container: '#ffede1'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#d8e2ff'
  secondary-fixed-dim: '#adc6ff'
  on-secondary-fixed: '#001a42'
  on-secondary-fixed-variant: '#004395'
  tertiary-fixed: '#ffdcc3'
  tertiary-fixed-dim: '#ffb77d'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6e3900'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
  surface-subtle: '#F1F3F5'
  ink: '#1A1D23'
  ink-soft: '#6B7280'
  blue-bg: '#EFF6FF'
  success: '#059669'
  success-bg: '#ECFDF5'
  danger: '#DC2626'
  danger-bg: '#FEF2F2'
  warning-bg: '#FFFBEB'
typography:
  display-brand:
    fontFamily: Nunito
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
  headline-lg:
    fontFamily: Work Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-lg-mobile:
    fontFamily: Work Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Work Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Work Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Work Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: Work Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  mono-data:
    fontFamily: IBM Plex Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 24px
  sidebar-width: 230px
---

## Brand & Style

The design system embodies a **friendly, encouraging, and professional** personality tailored for language learners. It balances the playful charm of a feline-themed mascot ("MeuBeu") with the structured efficiency required for educational software. The target audience is Vietnamese learners seeking an accessible yet dependable tool for vocabulary mastery.

The visual style is a **Modern Material 3 Hybrid**. It leverages the clean layouts and accessibility of Material 3 but infuses it with tactile, approachable elements. While the core experience remains minimalist and white-space heavy to maintain focus on content, subtle glassmorphism and "stamp-like" UI patterns introduce a unique character. The goal is to evoke a sense of progress and warmth—transforming the often-tedious task of rote memorization into an inviting, daily ritual.

## Colors

The palette is anchored by **Cobalt Blue**, a professional and trustworthy primary color that drives the brand identity and primary interaction states.

- **Primary & Secondary**: Used for active navigation, primary action buttons, and focus indicators.
- **Tertiary (Warning)**: Reserved for high-energy states like streaks, XP milestones, and "Hard" difficulty buttons.
- **Semantic Feedback**: A disciplined application of green (success) and red (danger) provides immediate visual confirmation during quizzes and flashcard sessions.
- **Surface Strategy**: The design utilizes `surface-subtle` and `blue-bg` to create hierarchy without relying on heavy borders. `blue-bg` is specifically used to highlight active or selected educational content.

## Typography

This design system uses a dual-font strategy to separate editorial content from technical data.

1.  **Work Sans**: The workhorse font for all interface elements, headings, and body text. Its friendly, grotesque nature ensures readability across all Vietnamese diacritics.
2.  **IBM Plex Mono**: Exclusively used for "technical" data points—IPA transcriptions, timers, percentages, and word counts. This adds a layer of precision and helps users mentally categorize data-heavy information.
3.  **Nunito**: Restricted to high-level branding and splash screens to reinforce the "soft" cat-themed identity.

**Scale and Hierarchy**:
- Headlines use a tight line-height to maintain punchiness.
- Body text uses a generous 1.5x line-height to reduce eye strain during long reading or practice sessions.

## Layout & Spacing

The layout follows a **fluid grid** model that adapts based on device orientation and screen width.

- **Mobile (< 768px)**: Uses a 4-column layout with 16px margins. Primary navigation is anchored at the bottom for thumb-reachability.
- **Desktop (≥ 768px)**: Content transitions to a fixed-width container with a persistent 230px left-hand sidebar for navigation.
- **Responsive Behavior**: At a 500px breakpoint, "Progress" cards and dashboard panels switch from a 2-column horizontal layout to a stacked vertical layout.

Spacing is based on a **4px base unit**. All gaps between elements, card padding, and vertical rhythm must be multiples of 4 (e.g., 8px, 16px, 24px, 32px).

## Elevation & Depth

Visual hierarchy is achieved through a combination of **tonal layering** and **ambient shadows**.

- **Surface Levels**: The base background (`#F8F9FA`) serves as the lowest tier. Cards and primary containers sit on `surface` (`#FFFFFF`).
- **Shadow Character**: Elevation 2 is the standard for interactive cards. Shadows are extremely soft (8% opacity `ink`), using a wide blur radius to avoid a "heavy" or dated feel.
- **Flat AppBars**: Top AppBars remain flat (0 elevation) even during scroll to maintain a modern, airy feel.
- **Interaction Depth**: On press or hover, cards do not necessarily "lift" higher. Instead, they utilize subtle scale-down effects (98%) or color shifts to the secondary brand tint to signify activity.

## Shapes

The shape language is consistently **rounded and approachable**, avoiding sharp corners entirely.

- **Standard Elements**: Cards, badges, and primary containers use a 12px - 18px radius (`rounded-lg` or `rounded-xl` logic).
- **Interactive Components**: Buttons and input fields use a 10px - 16px radius.
- **Brand Motifs**: Topic icons and mascot containers use a distinct 14px radius to stand out.
- **Special Borders**: A "Stamp" effect is used for bookmarked words, featuring a dashed border to evoke a stationery or correspondence feel.

## Components

### Buttons
- **Primary**: Full-width on mobile, rounded (12px), background `primary_color`, text `surface`.
- **Secondary**: Outlined with 1.5px stroke or `blue-bg` fill with blue text.
- **Semantic**: Success/Danger buttons follow the same rounding but use their respective semantic colors.

### Cards
- Standard cards use elevation 2, white background, and 12px-18px padding.
- **Topic Cards**: Feature a large 48px icon in a `blue-bg` box with a 14px radius.

### Input Fields
- Filled style using `background` (`#F8F9FA`) as the fill. 10px border radius.
- On focus: 1.5px solid `primary_color` border.
- Hint text uses `ink-soft`.

### Lists & Items
- Learning items use a 1px `ink` divider at 10% opacity.
- Selected items use a `blue-bg` background tint rather than a border.

### Navigation
- **Mobile Bottom Nav**: 0 elevation, white surface, using outlined Material icons. Active state uses `primary_color` for both icon and label.
- **Desktop Sidebar**: Background uses `ink` or a very dark tint of blue for high contrast, ensuring the navigation is clearly separated from the content area.

### Specialized Components
- **Flashcards**: Standardized size with 3D rotation logic. The "front" uses high-contrast typography, and the "back" integrates the `mono-data` font for IPA guides.
- **CatWidget**: A persistent brand anchor used for feedback. It should be placed in the corner of dashboards or empty states, utilizing the "bouncing" animation to provide a friendly presence.