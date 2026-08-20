---
name: Planazo Design System
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f4'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#4a454e'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#7c757f'
  outline-variant: '#ccc4cf'
  surface-tint: '#6e528b'
  primary: '#6e528b'
  on-primary: '#ffffff'
  primary-container: '#c9a9e9'
  on-primary-container: '#563b73'
  inverse-primary: '#dab9fa'
  secondary: '#714e98'
  on-secondary: '#ffffff'
  secondary-container: '#d2abfd'
  on-secondary-container: '#5d3b83'
  tertiary: '#6e5d1e'
  on-tertiary: '#ffffff'
  tertiary-container: '#cbb56d'
  on-tertiary-container: '#564607'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#efdbff'
  primary-fixed-dim: '#dab9fa'
  on-primary-fixed: '#280c43'
  on-primary-fixed-variant: '#553b72'
  secondary-fixed: '#efdbff'
  secondary-fixed-dim: '#dbb8ff'
  on-secondary-fixed: '#2a0250'
  on-secondary-fixed-variant: '#58367e'
  tertiary-fixed: '#fae195'
  tertiary-fixed-dim: '#dcc57b'
  on-tertiary-fixed: '#231b00'
  on-tertiary-fixed-variant: '#554506'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  display:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-bold:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-margin: 24px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style
The design system is built to evoke a sense of effortless planning and social warmth. The personality is "The Helpful Friend"—approachable, enthusiastic, and reliable without being rigid. 

The aesthetic leverages a **Modern-Friendly** style, mixing soft geometry with high-contrast functional elements. It avoids corporate coldness through the use of organic "squircle" influences, generous whitespace, and a pastel-adjacent palette that feels optimistic. The goal is to make the act of organizing an event feel as joyful as the event itself.

## Colors
The palette is centered on a hierarchy of purples to establish brand recognition while ensuring maximum legibility.

- **Primary (Light Lavender):** Used for large surfaces, decorative backgrounds, and soft highlights. It provides the "friendly" atmosphere.
- **Secondary (Dark Purple):** The functional workhorse. Used for all body text, primary action buttons, and high-emphasis strokes to ensure accessibility and grounding.
- **Accent (Pale Yellow):** Reserved for "moments of delight"—badges, active status indicators, and weather-related iconography.
- **Neutral:** A crisp white background maintains a high-end, clean feel, preventing the pastel tones from feeling muddy.

## Typography
This design system utilizes **Plus Jakarta Sans** for its modern, rounded terminals and optimistic character. 

- **Headlines:** Use a tighter letter-spacing and heavier weights to create a "bold" friendly impact.
- **Body Text:** Always rendered in the Secondary Dark Purple at 400 or 500 weight to ensure high contrast against white or lavender backgrounds.
- **Hierarchy:** Use the `Display` style sparingly for empty states or welcome screens. `Headline-lg` transitions to `Headline-lg-mobile` on devices smaller than 768px.

## Layout & Spacing
The layout follows a **fluid-to-fixed** hybrid model. On mobile, elements use a 24px safe-margin with a flexible 2-column or 1-column stack. On desktop, the content max-width is 1200px.

- **Rhythm:** An 8px base grid is strictly followed for all padding and margins.
- **Vertical Rhythm:** Content blocks should be separated by `stack-lg` (32px), while internal card elements use `stack-sm` (8px).
- **Alignment:** All text and icons should be vertically center-aligned within rows to maintain a "balanced" and calm visual feel.

## Elevation & Depth
This design system uses a "Soft-Layer" approach. Rather than deep shadows, depth is communicated through subtle tonal changes and very soft, diffused shadows.

- **Level 0 (Base):** White background.
- **Level 1 (Cards):** 1px solid border in Primary Lavender OR a soft shadow: `0px 4px 12px rgba(74, 40, 112, 0.08)`.
- **Level 2 (Interactive):** When hovered or pressed, the shadow deepens slightly and the element moves 2px up (Y-axis) to provide a tactile physical response.
- **Overlays:** Modals and bottom sheets use a 40% opacity blur of the Secondary color for the backdrop to keep focus on the action.

## Shapes
A **Rounded (2)** shape language is applied globally. This 0.5rem (8px) base radius ensures that UI elements feel soft to the touch without looking juvenile.

- **Small Components:** Checkboxes and small tags use `rounded` (8px).
- **Medium Components:** Buttons and Input fields use `rounded-lg` (16px).
- **Large Components:** Plan cards and Modals use `rounded-xl` (24px).
- **Icons:** Must feature rounded caps and joins to match the typography and shape language.

## Components
- **Buttons:** Primary buttons are Secondary Dark Purple with White text. They feature `rounded-lg` corners. Secondary buttons are Primary Lavender with Dark Purple text.
- **Chips/Badges:** Used for activity categories (e.g., "Outdoors," "Dining"). These use the Accent Pale Yellow background with Dark Purple text for maximum visibility.
- **Cards:** White background with a 1px Lavender border. They should have a generous 24px internal padding.
- **Inputs:** Soft Lavender background with 10% opacity, transitioning to a solid Lavender border on focus. Icons inside inputs should always be the Dark Purple.
- **Weather Icons:** Custom-drawn with thick, rounded strokes (2px minimum). Use the Pale Yellow for sun elements and the Primary Lavender for clouds/rain.
- **Map Pins:** A simplified teardrop shape with a circular cutout, using the Secondary Dark Purple to stand out against map textures.