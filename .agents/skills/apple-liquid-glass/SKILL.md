---
name: apple-liquid-glass
description: >-
  Apple Liquid Glass UI design system based on MockFlow specification.
  Creates high-gloss surfaces, optical glass slabs, frosted backdrop refraction,
  specular perimeter borders, and liquid glossy pill components.
---

# Apple Liquid Glass Skill

Derived from the Apple Liquid Glass design framework (`https://mockflow.com/skills/apple-liquid-glass`).

## Aesthetic Overview
Design screens following a modern iOS aesthetic with a liquid glass finish. The visual language centers on high-gloss optical surfaces, thick glass slabs with soft ambient depth, and luminous accents.

## Core Visual Specifications

### 1. Liquid Glass Slabs & Cards
- **Backdrop Blur & Refraction**: Optical blur using high-sigma filters (`sigmaX: 20` to `28`, `sigmaY: 20` to `28`) allowing background colors and moving fluid to refract through the glass.
- **Borders & Edge Refraction**: Very thin (0.8px to 1.5px) border with a two-tone angled gradient:
  - Top-Left: Bright specular white highlight (`Colors.white.withAlpha(200)` to `240`).
  - Bottom-Right: Ambient refraction tint reflecting background hues (`withAlpha(40)` to `80`).
- **Convex Optical Highlight**: An elliptical or top-half crescent white gradient simulating the curved surface of thick physical glass.
- **Ambient Shadow Depth**: Multi-layer drop shadows — a deep diffused black ambient shadow combined with a subtle colored aura glow matching the accent color.

### 2. Buttons & Interactive Controls
- **Geometry**: Continuous rounded pill shape (`BorderRadius.circular(32)`).
- **Body Material**: Translucent glass body with subtle top-to-bottom glossy gradient.
- **Dynamic Liquid Sheen**: Diagonal light streak traversing across the glass surface.
- **Micro-Interactions**: Smooth scale compression on press (`0.95` scale) with tactile glow bloom.
- **Typography**: Crisp, high-contrast, letterspaced typography with subtle drop-shadow to float legibly above the glass surface.

### 3. Layout & Breathing Room
- Spacious and breathable composition.
- Extreme rounded corners (20px to 32px) throughout all containers.
- Clean hierarchy with high-contrast text and luminous accents.
