---
name: ui-ux-pro-max
description: >-
  Advanced UI/UX engineering and design system skill for building world-class,
  flawlessly crafted, ultra-responsive digital products with uncompromising visual hierarchy,
  motion choreography, and micro-interaction excellence.
---

# UI UX PRO MAX

A master skill for crafting top-tier user experiences with state-of-the-art visual design.

## Core Tenets

### 1. Visual Hierarchy & Contrast
- **Focal Dominance**: Every screen must have a clear primary focal point. Secondary and tertiary elements must be deliberately balanced.
- **Luminance Contrast**: On deep OLED/black surfaces (#000000), use high-contrast primary text (#FFFFFF, #F8FAFC) and muted supporting labels (#94A3B8, #64748B) to prevent eye strain and maintain razor-sharp legibility.
- **Rhythm & Spacing**: Strict adherence to an 8-point spatial grid (8, 16, 24, 32, 48, 64px) with generous breathing room.

### 2. Motion & Physics Choreography
- **Natural Physics**: UI animations must simulate natural inertia, spring damping, and harmonic oscillation (trochoidal and sinusoidal easing).
- **Curved Transitions**: Avoid linear transitions for UI states. Always use `Curves.easeOutCubic`, `Curves.easeInOutCubic`, or dampened springs.
- **Performance Budget**: Target locked 60/120fps. Keep heavy layout recalculations out of render loops; use CustomPainters, RepaintBoundaries, and hardware-accelerated shaders.

### 3. Touch Ergonomics & Responsiveness
- **Hit Targets**: Minimum interactive touch target of 44x44 points.
- **Edge Boundaries**: Respect safe areas, notch insets, and curved device corners.
- **State Feedback**: Immediate tactile and visual acknowledgment on hover, tap-down, release, and focus.
