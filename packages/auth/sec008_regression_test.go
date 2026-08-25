package auth

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// SEC-008 regression lock: ?token= URL auth must fail closed, and User/Admin
// trust domains must not cross via middleware.

func TestSEC008RejectsTokenQueryAuthentication(t *testing.T) {
	config := DefaultJWTConfig("sec008-query-token-fixture-secret-32b")
	tokenService := NewTokenService(config)
	middleware := NewMiddleware(tokenService)

	pair, err := tokenService.GenerateTokenPair("sec008-user", []string{"user"})
	if err != nil {
		t.Fatal(err)
	}

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler must not run when ?token= is present")
	})

	req := httptest.NewRequest(http.MethodGet, "/protected?token="+pair.AccessToken, nil)
	rec := httptest.NewRecorder()
	middleware.RequireAuth(handler).ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusUnauthorized)
	}
	if !strings.Contains(rec.Body.String(), "url_authentication_unsupported") {
		t.Fatalf("missing migration code: %s", rec.Body.String())
	}
	if strings.Contains(rec.Body.String(), pair.AccessToken) {
		t.Fatal("response echoed query credential")
	}
	if !HasProhibitedCredentialQuery(req) {
		t.Fatal("HasProhibitedCredentialQuery must detect token query")
	}
}

func TestSEC008UserAdminSessionIsolation(t *testing.T) {
	userAuth, adminAuth, _ := newIsolatedAuthPair(t, nil)

	userPair, err := userAuth.Token.GenerateTokenPair("sec008-user", []string{"user"})
	if err != nil {
		t.Fatal(err)
	}
	adminPair, err := adminAuth.Token.GenerateTokenPair("sec008-admin", []string{"support_admin"})
	if err != nil {
		t.Fatal(err)
	}

	okHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	// Admin session must not reach a User-protected route.
	req := httptest.NewRequest(http.MethodGet, "/api/user/me", nil)
	req.Header.Set("Authorization", "Bearer "+adminPair.AccessToken)
	rec := httptest.NewRecorder()
	userAuth.Middleware.RequireAuth(okHandler).ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("admin token on user route: status=%d want 401", rec.Code)
	}

	// User session must not reach an Admin-protected route.
	req = httptest.NewRequest(http.MethodGet, "/api/admin/contests", nil)
	req.Header.Set("Authorization", "Bearer "+userPair.AccessToken)
	rec = httptest.NewRecorder()
	adminAuth.Middleware.RequireAuth(okHandler).ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("user token on admin route: status=%d want 401", rec.Code)
	}

	// Cryptographic validators must also reject cross-context tokens.
	if _, err := adminAuth.Token.ValidateAccessToken(userPair.AccessToken); err == nil {
		t.Fatal("Admin validator accepted User access token")
	}
	if _, err := userAuth.Token.ValidateAccessToken(adminPair.AccessToken); err == nil {
		t.Fatal("User validator accepted Admin access token")
	}
}
