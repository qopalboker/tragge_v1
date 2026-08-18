// User panel theme wrapper: keep the shared Pinia store API, but lock the
// default "dark" palette onto the canonical MVP emerald/navy surface so
// Settings / Support / tickets (--theme-*) match Dashboard (--mvp-*).
// Admin keeps the upstream indigo Obsidian palette (separate SPA bundle).

export {
  useThemeStore,
  type Theme,
  type ResolvedTheme,
  type ThemeId,
  type ThemeColors,
} from '@tragge/frontend-shared';

import { themes as sharedThemes } from '@tragge/frontend-shared';

const mvpDark = sharedThemes.dark;
mvpDark.name = 'Tragge MVP';
mvpDark.bg = 'radial-gradient(120% 80% at 50% -10%, #0d1f2e 0%, #050810 45%, #03060c 100%)';
mvpDark.surface = 'rgba(14, 24, 42, 0.72)';
mvpDark.surfaceHover = 'rgba(0, 212, 160, 0.08)';
mvpDark.glass = 'rgba(14, 24, 42, 0.72)';
mvpDark.glassBorder = 'rgba(0, 212, 160, 0.14)';
mvpDark.glassHighlight = 'rgba(255, 255, 255, 0.06)';
mvpDark.text = '#f2f5fa';
mvpDark.textSecondary = '#8b95a8';
mvpDark.accent = '#00d4a0';
mvpDark.accentGlow = 'rgba(0, 212, 160, 0.35)';
mvpDark.green = '#00d4a0';
mvpDark.navBg = 'rgba(5, 10, 18, 0.92)';
mvpDark.sidebarBg = 'rgba(5, 10, 18, 0.96)';

// Ocean variant stays teal-family; nudge to the same emerald brand.
sharedThemes.darkOcean.accent = '#00d4a0';
sharedThemes.darkOcean.accentGlow = 'rgba(0, 212, 160, 0.3)';
sharedThemes.darkOcean.green = '#00d4a0';

export { sharedThemes as themes };
