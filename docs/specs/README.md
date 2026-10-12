# Specs: making Luna sticky

Roadmap for the next round of work, agreed on 2026-10-12. Each stage is built, tested, documented (ADR) and shipped before the next one starts.

**Principles** (from the planning discussion):
- **All ages, casual.** Relaxed by default, with optional harder goals for players who want them.
- **No way to lose.** Challenge comes from stars, times and collecting, never a game over.
- **The Park stays as it is** as level 1. New ideas arrive one per level.
- Keep the cute, cartoon tone. Tuning lives in one place per feature (see CLAUDE.md).

| Stage | Spec | Depends on |
|---|---|---|
| 1 | [Save data, stars and best times](01-progress-stars-times.md) | — |
| 2 | [Dogdex and rare variants](02-dogdex-rare-variants.md) | 1 |
| 3 | [Collars and cosmetics](03-cosmetics.md) | 1 (stars) |
| 4 | [Levels](04-levels.md) | 1 (stars to unlock), works with 2 and 3 |

Open questions are listed at the end of each spec. Decide them before implementation starts.
