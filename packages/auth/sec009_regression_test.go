package auth

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/alicebob/miniredis/v2"
	redis "github.com/redis/go-redis/v9"
)

// SEC-009: sensitive-action reauth + Super Admin MFA policy gating.

func TestSEC009ReauthenticationMissingGrantRejected(t *testing.T) {
	service, err := NewReauthenticationService(newMemoryReauthenticationStore(), MaxReauthenticationTTL)
	if err != nil {
		t.Fatal(err)
	}
	expectation := ReauthenticationExpectation{
		Context: ContextAdmin, ActorID: "admin-1", SessionID: "session-1",
		Action: "wallet.adjust", ResourceID: "user-1",
		SecurityFingerprint: ReauthenticationSecurityFingerprint("hash", []string{RoleSuperAdmin}, []string{"users.wallet.charge"}),
	}
	if err := service.Consume(context.Background(), "", expectation); !errors.Is(err, ErrReauthenticationInvalid) {
		t.Fatalf("empty grant err=%v want ErrReauthenticationInvalid", err)
	}
	if err := service.Consume(context.Background(), "not-issued", expectation); !errors.Is(err, ErrReauthenticationInvalid) {
		t.Fatalf("missing grant err=%v want ErrReauthenticationInvalid", err)
	}
}

func TestSEC009SuperAdminMFAPolicyGating(t *testing.T) {
	if SuperAdminMFAAllowed(false, "") != true {
		t.Fatal("policy OFF must allow empty assurance")
	}
	if SuperAdminMFAAllowed(false, MFAAssuranceSuperAdminTOTPV1) != true {
		t.Fatal("policy OFF must allow TOTP assurance")
	}
	if SuperAdminMFAAllowed(true, "") != false {
		t.Fatal("policy ON must reject empty assurance")
	}
	if SuperAdminMFAAllowed(true, MFAAssuranceSuperAdminTOTPV1) != true {
		t.Fatal("policy ON must accept TOTP assurance")
	}
	if SuperAdminMFAAllowed(true, MFAAssurance("invented")) != false {
		t.Fatal("invented assurance must fail closed")
	}
}

func TestSEC009SuperAdminActionWithoutMFARejectedWhenPolicyOn(t *testing.T) {
	mini := miniredis.RunT(t)
	client := redis.NewClient(&redis.Options{Addr: mini.Addr()})
	cfg := DefaultConfig()
	cfg.Context = ContextAdmin
	cfg.JWTSecret = "access-secret-for-tests-only-32-bytes"
	cfg.JWTRefreshSecret = "refresh-secret-for-tests-only-32bytes"
	cfg.JWTIssuer = "tragge-admin-auth"
	cfg.JWTAudience = AudienceAdmin
	cfg.Redis = client
	cfg.SessionPrefix = "session:admin:"
	a := New(cfg)

	// Password-only Super Admin session (no MFA assurance).
	pair, _, err := a.LoginWithPermissions(context.Background(), "admin-policy-on", []string{RoleSuperAdmin}, []string{"users.edit"}, "test", "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}

	handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})

	// Policy ON → must reject.
	a.Middleware.SetSuperAdminMFAPolicy(func(context.Context) (bool, error) { return true, nil })
	req := httptest.NewRequest(http.MethodGet, "/api/admin/sensitive", nil)
	req.Header.Set("Authorization", "Bearer "+pair.AccessToken)
	rec := httptest.NewRecorder()
	a.Middleware.RequireAuth(a.Middleware.RequireAdminAccess(handler)).ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("policy ON without MFA: status=%d want 401", rec.Code)
	}

	// Policy OFF → password-only Super Admin allowed.
	a.Middleware.SetSuperAdminMFAPolicy(func(context.Context) (bool, error) { return false, nil })
	rec = httptest.NewRecorder()
	a.Middleware.RequireAuth(a.Middleware.RequireAdminAccess(handler)).ServeHTTP(rec, req)
	if rec.Code != http.StatusNoContent {
		t.Fatalf("policy OFF without MFA: status=%d want 204", rec.Code)
	}
}
