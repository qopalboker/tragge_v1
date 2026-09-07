package server

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestContestFeeWalletRouteIsSuperAdminOnly(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	raw, err := os.ReadFile(filepath.Join(filepath.Dir(file), "app.go"))
	if err != nil {
		t.Fatal(err)
	}
	source := string(raw)
	route := `r.With(app.auth.Middleware.RequireSuperAdmin).Get("/contest-fee-wallet", app.handleGetContestFeeWallet)`
	if !strings.Contains(source, route) {
		t.Fatal("fee wallet route lacks explicit Super Admin authorization")
	}
	if strings.Contains(source, `/api/user/financial/contest-fee-wallet`) {
		t.Fatal("fee wallet exposed in user trust domain")
	}
}
