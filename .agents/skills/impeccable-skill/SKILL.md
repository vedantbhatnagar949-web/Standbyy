---
name: impeccable-skill
description: >-
  Precision craftsmanship and perfectionist design execution skill.
  Enforces zero-defect visual alignment, pixel-perfect layout geometry,
  artifact-free shaders, and uncompromising aesthetic rigor.
---

# Impeccable Skill

The standard of zero tolerance for visual defects, layout jitter, misaligned baselines, or tacky compromises.

## The Pillars of Impeccable Craft

### 1. Pixel Alignment & Geometry
- **Sub-Pixel Crispness**: Borders and divider strokes must be rounded or cleanly positioned on exact device pixel boundaries to eliminate blurry anti-aliasing artifacts.
- **Baseline Anchoring**: Text alignments in horizontal rows must always use matching baselines (`textBaseline: TextBaseline.alphabetic`) or precise optical vertical centering.
- **Corner Curvature (Squircle / Continuous Curvature)**: Avoid harsh abrupt transitions. Use continuous smoothing for pill and card radii.

### 2. Optical Balance vs. Mathematical Alignment
- Visual weight often differs from bounding-box center (e.g., play/arrow icons need 1-2px optical shift towards their point).
- Balance icon heights with adjacent typography cap heights, not total line heights.

### 3. Rendering Cleanliness
- Eliminate clipping jaggedness with proper `Clip.antiAliasWithSaveLayer` or anti-aliased custom paths.
- Ensure ambient shadows have adequate blur spread without banding or blocky clipping boxes.
