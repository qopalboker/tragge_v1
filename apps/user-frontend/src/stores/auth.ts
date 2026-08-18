import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import axios from 'axios';
import * as Sentry from '@sentry/vue';
import {
  refreshAccessToken as sharedRefresh,
  hasSessionHint,
  clearSessionHintCookie,
  clearLegacySessionHint,
  createCrossTabChannel,
  createBootstrap,
  type SessionHintConfig,
} from '@tragge/frontend-shared';
import { api, setAccessToken as setApiAccessToken } from '@/api/client';
import { useToast } from '@/composables/useToast';
import { getErrorMessage } from '@/utils/errorHandler';
import { handleGoogleCallback, clearStoredState } from '@/services/oauth';
import type { GoogleCallbackResponse } from '@/services/oauth';
import { t } from '@/i18n';

// ---------------------------------------------------------------------------
// User-panel auth surface
// ---------------------------------------------------------------------------
//
// Deliberately narrow: no adminLogin, no fetchPermissions, no admin role
// computeds. A leaked user-frontend bundle cannot be coerced into
// logging into the admin panel because the admin endpoints and cookie
// names simply aren't in this file. The admin panel has its own store
// in apps/admin-frontend with its own endpoints and cookies.
//
// Step 7: suffixed cookie/hint/broadcast names so the admin panel —
// now served from a distinct origin — can share an eTLD+1 without
// browser cookie collisions. Dropping legacyLocalStorageKey is
// deliberate: it existed only to migrate from pre-cookie storage
// during the single-panel era and has no role across origin splits
// (a cross-origin admin tab cannot read the user panel's
// localStorage anyway).
const SESSION_HINT: SessionHintConfig = {
  cookieName: 'tragge_session_hint_user',
};
// Panel-scoped broadcast key: a user logout in one user-panel tab
// must NOT trigger an admin-panel tab to think it was logged out,
// and vice versa. The admin store uses tragge_auth_event_admin.
const CROSS_TAB_KEY = 'tragge_auth_event_user';
const crossTab = createCrossTabChannel(CROSS_TAB_KEY);

export type OAuthProvider = 'google' | 'github' | 'facebook' | 'apple' | 'discord';

export interface OAuthAccount {
  provider: OAuthProvider;
  provider_user_id: string;
  email?: string;
  linked_at: string;
}

interface User {
  id: string;
  email: string;
  roles: string[];
  email_verified: boolean;
  phone_verified?: boolean;
  username?: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  country?: string;
  phone?: string;
  created_at?: string;
  oauth_providers?: OAuthAccount[];
  has_password?: boolean;
}

interface LoginResponse {
  access_token: string;
  requires_verification?: boolean;
  available_methods?: string[];
  masked_email?: string;
  masked_phone?: string;
}

interface RegisterResponse {
  access_token: string;
  user_id: string;
  referred_by?: string;
  requires_verification?: boolean;
  available_methods?: string[];
  masked_email?: string;
  masked_phone?: string;
}

interface RegisterRequest {
  email: string;
  password: string;
  country: string;
  ref?: string;
  agree_terms: boolean;
  age_confirm: boolean;
  captcha_token?: string;
}

export function normalizeRegistrationCountry(value: string): string | null {
  const normalized = value.trim().toUpperCase();
  return /^[A-Z]{2}$/.test(normalized) ? normalized : null;
}
interface RegisterProfileData {
  username?: string;
  display_name?: string;
  country: string;
  phone?: string;
}

interface MeResponse {
  user_id: string;
  email: string;
  roles: string[];
  email_verified: boolean;
  phone_verified?: boolean;
  username?: string;
  display_name?: string;
  avatar_url?: string;
  bio?: string;
  country?: string;
  phone?: string;
  created_at: string;
  oauth_providers?: OAuthAccount[];
  has_password?: boolean;
}

interface JwtPayload {
  exp?: number;
  user_id?: string;
}

function decodeJwt(token: string): JwtPayload | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(atob(payload)) as JwtPayload;
  } catch {
    return null;
  }
}

function isTokenExpired(token: string, bufferSeconds = 300): boolean {
  const decoded = decodeJwt(token);
  if (!decoded?.exp) return true;
  const now = Date.now() / 1000;
  return decoded.exp < now + bufferSeconds;
}

/** Deterministic session bootstrap phases for router + Mini App. */
export type AuthBootstrapPhase =
  | 'initializing'
  | 'telegram_authenticating'
  | 'authenticated'
  | 'unauthenticated'
  | 'error';

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref<string | null>(null);
  const user = ref<User | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);
  const referredByName = ref<string | null>(null);
  // `ready` flips to true after bootstrap finishes (success or failure).
  // Router guards rely on this to avoid redirecting to /login while the
  // silent refresh from the httpOnly cookie is still in flight.
  const ready = ref(false);
  /** Full startup phase including optional Telegram initData exchange. */
  const bootstrapPhase = ref<AuthBootstrapPhase>('initializing');
  const bootstrapError = ref<string | null>(null);
  /** True when this tab established (or restored) a Telegram Mini App session. */
  const isTelegramSession = ref(false);
  /** Safe diagnostics for Mini App UI/E2E (never includes initData payload). */
  const telegramDiagnostics = ref<{
    telegramScriptInDom: boolean;
    telegramScriptLoaded: boolean;
    telegramObjectPresent: boolean;
    webAppObjectPresent: boolean;
    webAppVersion: string | null;
    platform: string | null;
    isExpanded: boolean | null;
    bridgePresent: boolean;
    initDataPresent: boolean;
    initDataLength: number;
    likelyTelegramClient: boolean;
    authRequestStatus: number | null;
    authResponseCode: string | null;
    retryCount: number;
    lastError: string | null;
  }>({
    telegramScriptInDom: false,
    telegramScriptLoaded: false,
    telegramObjectPresent: false,
    webAppObjectPresent: false,
    webAppVersion: null,
    platform: null,
    isExpanded: null,
    bridgePresent: false,
    initDataPresent: false,
    initDataLength: 0,
    likelyTelegramClient: false,
    authRequestStatus: null,
    authResponseCode: null,
    retryCount: 0,
    lastError: null,
  });
  /** In-flight Telegram exchange (bootstrap + Retry share this). */
  let telegramAuthInflight: Promise<boolean> | null = null;

  const lastAuthResponse = ref<{
    requires_verification?: boolean;
    available_methods?: string[];
    masked_email?: string;
    masked_phone?: string;
  } | null>(null);

  const oauthLoginResult = ref<{
    is_new_user: boolean;
    was_linked: boolean;
    has_password: boolean;
  } | null>(null);

  const isAuthenticated = computed(() => !!accessToken.value);

  function hasRole(role: string): boolean {
    return user.value?.roles?.includes(role) ?? false;
  }

  function setTokens(access: string | null): void {
    accessToken.value = access;
    setApiAccessToken(access);

    if (access) {
      // Success path: the server just issued a fresh session-hint
      // cookie in the same response. Evict the legacy localStorage
      // fallback so we stop consulting it.
      clearLegacySessionHint(SESSION_HINT);
    } else {
      clearSessionHintCookie(SESSION_HINT);
      clearLegacySessionHint(SESSION_HINT);
      isTelegramSession.value = false;
      crossTab.broadcastLogout();
    }
  }

  function setUser(userData: User | null): void {
    user.value = userData;
    if (userData) {
      Sentry.setUser({
        id: userData.id,
      });
    } else {
      Sentry.setUser(null);
    }
  }

  // Refresh the access token via the httpOnly cookie. Only invalidates
  // the session on explicit 401/403; transient failures (network,
  // 5xx) preserve cookies/hint so the next interaction can recover.
  async function refreshAccessToken(): Promise<boolean> {
    const result = await sharedRefresh({
      endpoint: '/api/user/auth/refresh',
    });
    if (result.ok) {
      setTokens(result.accessToken);
      return true;
    }
    if (result.error.kind === 'auth') {
      setTokens(null);
    }
    return false;
  }

  async function ensureValidToken(): Promise<boolean> {
    const currentAccessToken = accessToken.value;
    if (!currentAccessToken || isTokenExpired(currentAccessToken)) {
      return await refreshAccessToken();
    }
    return true;
  }

  async function login(email: string, password: string): Promise<boolean> {
    const toast = useToast();
    loading.value = true;
    error.value = null;

    try {
      const response = await api.post<LoginResponse>('/api/user/auth/login', {
        email,
        password,
      });

      const {
        access_token,
        requires_verification,
        available_methods,
        masked_email,
        masked_phone,
      } = response.data;
      setTokens(access_token);

      lastAuthResponse.value = requires_verification
        ? { requires_verification, available_methods, masked_email, masked_phone }
        : null;

      await fetchUser(true);
      toast.success(t('auth.loginSuccess'));
      return true;
    } catch (err: unknown) {
      const message = getErrorMessage(err, t('auth.loginError'));
      error.value = message;
      toast.error(message);
      return false;
    } finally {
      loading.value = false;
    }
  }

  async function register(
    email: string,
    password: string,
    profileData: RegisterProfileData,
    agreeTerms?: boolean,
    ageConfirm?: boolean,
    referralCode?: string,
    captchaToken?: string,
  ): Promise<boolean> {
    const toast = useToast();
    loading.value = true;
    error.value = null;
    referredByName.value = null;

    try {
      const country = normalizeRegistrationCountry(profileData.country);
      if (!country) {
        error.value = t('auth.errorRequired');
        return false;
      }
      const payload: RegisterRequest = {
        email,
        password,
        country,
        agree_terms: agreeTerms ?? false,
        age_confirm: ageConfirm ?? false,
      };
      if (referralCode) payload.ref = referralCode;
      if (captchaToken) payload.captcha_token = captchaToken;

      const response = await api.post<RegisterResponse>('/api/user/auth/register', payload);

      const {
        access_token,
        referred_by,
        requires_verification,
        available_methods,
        masked_email,
        masked_phone,
      } = response.data;
      setTokens(access_token);

      lastAuthResponse.value = requires_verification
        ? { requires_verification, available_methods, masked_email, masked_phone }
        : null;

      if (referred_by) referredByName.value = referred_by;

      if (profileData) {
        try {
          await api.put('/api/user/me/profile', profileData);
          // If a phone was saved, the backend now has SMS as an
          // additional verification method. Reflect it in the modal
          // so the user sees the choice immediately rather than after
          // a refetch.
          if (profileData.phone && lastAuthResponse.value) {
            if (!lastAuthResponse.value.available_methods?.includes('sms')) {
              lastAuthResponse.value.available_methods = [
                ...(lastAuthResponse.value.available_methods || []),
                'sms',
              ];
            }
            const ph = profileData.phone;
            lastAuthResponse.value.masked_phone =
              ph.length <= 4 ? '***'
              : ph.length <= 7 ? ph.slice(0, 2) + '***' + ph.slice(-2)
              : ph.slice(0, 4) + '***' + ph.slice(-2);
          }
        } catch {
          // User is registered and logged in — they can update their
          // profile from the profile page later.
          console.warn('Profile update after registration failed');
        }
      }

      await fetchUser(true);
      toast.success(t('auth.registrationSuccess'));
      return true;
    } catch (err: unknown) {
      const message = getErrorMessage(err, t('auth.registrationError'));
      error.value = message;
      toast.error(message);
      return false;
    } finally {
      loading.value = false;
    }
  }

  async function fetchUser(throwOnError = false): Promise<void> {
    if (!accessToken.value) return;

    try {
      const response = await api.get<MeResponse>('/api/user/me');
      setUser({
        id: response.data.user_id,
        email: response.data.email,
        roles: response.data.roles,
        email_verified: response.data.email_verified,
        phone_verified: response.data.phone_verified,
        username: response.data.username,
        display_name: response.data.display_name,
        avatar_url: response.data.avatar_url,
        bio: response.data.bio,
        country: response.data.country,
        phone: response.data.phone,
        created_at: response.data.created_at,
        oauth_providers: response.data.oauth_providers,
        has_password: response.data.has_password,
      });
    } catch (err) {
      logout();
      if (throwOnError) throw err;
    }
  }

  /**
   * Telegram Mini App session exchange.
   * Sends only signed initData — never client-supplied telegram_id.
   */
  async function loginWithTelegram(initData: string): Promise<boolean> {
    const trimmed = initData.trim();
    if (!trimmed) {
      error.value = 'telegram_initdata_missing';
      telegramDiagnostics.value = {
        ...telegramDiagnostics.value,
        lastError: 'telegram_initdata_missing',
        authRequestStatus: null,
        authResponseCode: 'telegram_initdata_missing',
      };
      return false;
    }
    // Dedup concurrent exchanges (bootstrap + Retry / double-tap).
    if (telegramAuthInflight) {
      return telegramAuthInflight;
    }
    loading.value = true;
    error.value = null;
    telegramDiagnostics.value = {
      ...telegramDiagnostics.value,
      initDataPresent: true,
      initDataLength: trimmed.length,
      lastError: null,
      authRequestStatus: null,
      authResponseCode: null,
    };
    telegramAuthInflight = (async () => {
      try {
        const response = await api.post<{
          access_token: string;
          user_id?: string;
          roles?: string[];
          code?: string;
        }>('/api/user/auth/telegram', {
          init_data: trimmed,
        });
        telegramDiagnostics.value = {
          ...telegramDiagnostics.value,
          authRequestStatus: 200,
          authResponseCode: null,
        };
        setTokens(response.data.access_token);
        await fetchUser(true);
        isTelegramSession.value = true;
        bootstrapPhase.value = 'authenticated';
        bootstrapError.value = null;
        return true;
      } catch (err: unknown) {
        const message = getErrorMessage(err, t('auth.loginError'));
        error.value = message;
        let status: number | null = null;
        let code: string | null = null;
        if (err && typeof err === 'object' && 'response' in err) {
          const ax = err as { response?: { status?: number; data?: { code?: string; error?: string } } };
          status = ax.response?.status ?? null;
          code = ax.response?.data?.code ?? ax.response?.data?.error ?? null;
        }
        telegramDiagnostics.value = {
          ...telegramDiagnostics.value,
          authRequestStatus: status,
          authResponseCode: code,
          lastError: code || message,
        };
        bootstrapError.value = code || message;
        return false;
      } finally {
        loading.value = false;
        telegramAuthInflight = null;
      }
    })();
    return telegramAuthInflight;
  }

  /**
   * Explicit Retry path — not memoized by createBootstrap.
   * Re-reads Telegram.WebApp.initData and re-posts /auth/telegram.
   */
  async function retryTelegramAuth(): Promise<boolean> {
    telegramDiagnostics.value = {
      ...telegramDiagnostics.value,
      retryCount: telegramDiagnostics.value.retryCount + 1,
      lastError: null,
    };
    bootstrapPhase.value = 'telegram_authenticating';
    bootstrapError.value = null;
    error.value = null;

    const {
      waitForSignedInitData,
      prepareTelegramViewport,
      getTelegramDiagnostics,
    } = await import('@/modules/miniapp/telegram');
    const { setLocale } = await import('@/i18n');

    setLocale('fa');
    document.documentElement.setAttribute('dir', 'rtl');
    document.documentElement.lang = 'fa';
    prepareTelegramViewport();

    const waited = await waitForSignedInitData();
    const diag = getTelegramDiagnostics();
    telegramDiagnostics.value = {
      ...telegramDiagnostics.value,
      ...diag,
    };

    if (waited.phase !== 'init_data_available' || !waited.initData) {
      bootstrapPhase.value = 'error';
      bootstrapError.value =
        waited.phase === 'bridge_absent'
          ? 'telegram_bridge_absent'
          : 'telegram_initdata_missing';
      telegramDiagnostics.value = {
        ...telegramDiagnostics.value,
        lastError: bootstrapError.value,
      };
      ready.value = true;
      return false;
    }

    const ok = await loginWithTelegram(waited.initData);
    if (ok && accessToken.value) {
      isTelegramSession.value = true;
      bootstrapPhase.value = 'authenticated';
      bootstrapError.value = null;
      ready.value = true;
      return true;
    }
    bootstrapPhase.value = 'error';
    if (!bootstrapError.value) {
      bootstrapError.value = error.value || 'telegram_auth_failed';
    }
    ready.value = true;
    return false;
  }

  async function loginWithGoogle(
    code: string,
    state: string,
  ): Promise<{
    success: boolean;
    is_new_user?: boolean;
    was_linked?: boolean;
    has_password?: boolean;
  }> {
    const toast = useToast();
    loading.value = true;
    error.value = null;
    oauthLoginResult.value = null;

    try {
      const storedReferralCode = localStorage.getItem('referral_code');
      const response: GoogleCallbackResponse = await handleGoogleCallback(code, state);

      const { access_token, is_new_user, was_linked, has_password } = response;
      setTokens(access_token);

      oauthLoginResult.value = {
        is_new_user: is_new_user ?? false,
        was_linked: was_linked ?? false,
        has_password: has_password ?? false,
      };

      await fetchUser(true);

      if (is_new_user && storedReferralCode) {
        try {
          await api.post('/api/user/referral/apply', { code: storedReferralCode });
          localStorage.removeItem('referral_code');
        } catch (refErr) {
          console.warn('Failed to apply referral code for OAuth signup:', refErr);
        }
      }

      const successMessage = is_new_user
        ? t('auth.googleAccountCreated')
        : was_linked
          ? t('auth.googleAccountLinked')
          : t('auth.loginSuccess');
      toast.success(successMessage);

      return { success: true, is_new_user, was_linked, has_password };
    } catch (err: unknown) {
      clearStoredState();
      const message = getErrorMessage(err, t('auth.googleLoginFailed'));
      error.value = message;
      toast.error(message);
      return { success: false };
    } finally {
      loading.value = false;
    }
  }

  function logout(): void {
    const currentToken = accessToken.value;

    setTokens(null);
    setUser(null);
    lastAuthResponse.value = null;
    oauthLoginResult.value = null;

    // Fire-and-forget backend logout so the server can invalidate the
    // session and clear the httpOnly cookie. If it fails, local state
    // is already cleared and the session will expire via TTL anyway.
    if (currentToken) {
      axios
        .post(
          '/api/user/logout',
          {},
          {
            withCredentials: true,
            headers: {
              Authorization: `Bearer ${currentToken}`,
              'X-Requested-With': 'XMLHttpRequest',
            },
          },
        )
        .catch(() => {
          /* ignore */
        });
    }
  }

  function clearError(): void {
    error.value = null;
  }

  // Cross-tab logout propagation with self-heal.
  //
  // When a peer tab signals a logout, don't unconditionally wipe our
  // state — the peer may have seen a stale 401 while our refresh just
  // succeeded. Verify before acting: if our cookies still produce a
  // fresh access token, ignore the broadcast. Costs one /refresh
  // round-trip per peer per broadcast. Logout is rare; this is cheap.
  if (typeof window !== 'undefined') {
    crossTab.onRemoteLogout(async () => {
      if (!accessToken.value && !user.value) return;
      try {
        const ok = await ensureValidToken();
        if (ok && accessToken.value) return;
      } catch {
        /* fall through to logout */
      }

      // Clear in-memory state directly rather than routing through
      // setTokens(null), which would echo another broadcast back out.
      accessToken.value = null;
      setApiAccessToken(null);
      setUser(null);
      lastAuthResponse.value = null;
      oauthLoginResult.value = null;
      ready.value = true;

      const { default: router } = await import('@/router');
      const route = router.currentRoute.value;
      const onProtectedRoute = route.matched.some((r) => r.meta.requiresAuth);
      if (onProtectedRoute) {
        router.push({ name: 'login', query: { redirect: route.fullPath } });
      }
    });
  }

  // Restore the session from the httpOnly refresh cookie on app
  // startup / before router guards evaluate `isAuthenticated`.
  //
  // Deduped so concurrent callers (main.ts awaiting before mount +
  // router guard awaiting before the first navigation) share a single
  // in-flight promise. Safe to call from anywhere — always resolves,
  // never rejects.
  const bootstrap = createBootstrap(async () => {
    // Anonymous visitors (e.g. landing on /user/register from a cold
    // tab) have no session hint and no refresh cookie worth trying.
    // Skipping saves one guaranteed-401 POST per cold load.
    if (!hasSessionHint(SESSION_HINT)) {
      ready.value = true;
      return;
    }
    try {
      const valid = await ensureValidToken();
      if (!valid || !accessToken.value) {
        // Either a genuine 401 (state already cleared) or a transient
        // failure (state preserved). Either way, bail without
        // broadcasting; the next navigation will retry.
        return;
      }
      await fetchUser();
    } finally {
      ready.value = true;
    }
  });

  /**
   * Full app-entry bootstrap: cookie session first, then Telegram Mini App
   * initData exchange when present. Must finish before the router is
   * installed so `/miniapp/*` guards never race ahead of Telegram auth.
   *
   * Memoized via createBootstrap (cold start once). Use retryTelegramAuth()
   * for explicit Retry — that path is not memoized.
   */
  const bootstrapFull = createBootstrap(async () => {
    bootstrapPhase.value = 'initializing';
    bootstrapError.value = null;
    try {
      await bootstrap();
      if (accessToken.value) {
        bootstrapPhase.value = 'authenticated';
        return;
      }

      const {
        isTelegramWebAppBridgePresent,
        isLikelyTelegramClient,
        waitForSignedInitData,
        prepareTelegramViewport,
        getTelegramDiagnostics,
      } = await import('@/modules/miniapp/telegram');
      const { setLocale } = await import('@/i18n');

      // Only enter Telegram auth when the WebApp bridge or Telegram client
      // is actually present. Merely visiting /miniapp/* in a normal browser
      // must stay on the normal web auth path (not the TG error page).
      const wantTelegram =
        isTelegramWebAppBridgePresent() || isLikelyTelegramClient();

      if (!wantTelegram) {
        bootstrapPhase.value = 'unauthenticated';
        telegramDiagnostics.value = {
          ...telegramDiagnostics.value,
          ...getTelegramDiagnostics(),
        };
        return;
      }

      setLocale('fa');
      document.documentElement.setAttribute('dir', 'rtl');
      document.documentElement.lang = 'fa';
      prepareTelegramViewport();

      // Wait for signed initData if the bridge is (or will be) present.
      // Empty initData on the first tick is not a terminal failure.
      bootstrapPhase.value = 'telegram_authenticating';
      const waited = await waitForSignedInitData();
      telegramDiagnostics.value = {
        ...telegramDiagnostics.value,
        ...getTelegramDiagnostics(),
      };

      if (waited.phase !== 'init_data_available' || !waited.initData) {
        bootstrapPhase.value = 'error';
        bootstrapError.value =
          waited.phase === 'bridge_absent'
            ? 'telegram_bridge_absent'
            : 'telegram_initdata_missing';
        telegramDiagnostics.value = {
          ...telegramDiagnostics.value,
          lastError: bootstrapError.value,
        };
        return;
      }

      const ok = await loginWithTelegram(waited.initData);
      if (ok && accessToken.value) {
        isTelegramSession.value = true;
        bootstrapPhase.value = 'authenticated';
        return;
      }
      bootstrapPhase.value = 'error';
      bootstrapError.value =
        bootstrapError.value || error.value || 'telegram_auth_failed';
    } catch (err) {
      bootstrapPhase.value = 'error';
      bootstrapError.value =
        err instanceof Error ? err.message : 'telegram_auth_failed';
      telegramDiagnostics.value = {
        ...telegramDiagnostics.value,
        lastError: bootstrapError.value,
      };
    } finally {
      ready.value = true;
      if (accessToken.value) {
        bootstrapPhase.value = 'authenticated';
      } else if (
        bootstrapPhase.value === 'initializing' ||
        bootstrapPhase.value === 'telegram_authenticating'
      ) {
        bootstrapPhase.value = 'unauthenticated';
      }
    }
  });

  return {
    accessToken,
    user,
    loading,
    error,
    referredByName,
    lastAuthResponse,
    oauthLoginResult,
    ready,
    bootstrapPhase,
    bootstrapError,
    isTelegramSession,
    telegramDiagnostics,
    isAuthenticated,
    setTokens,
    login,
    loginWithTelegram,
    retryTelegramAuth,
    register,
    loginWithGoogle,
    logout,
    fetchUser,
    clearError,
    refreshAccessToken,
    ensureValidToken,
    bootstrap,
    bootstrapFull,
    hasRole,
  };
});
