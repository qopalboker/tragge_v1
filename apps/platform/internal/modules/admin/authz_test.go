package admin

import (
	"sync"
	"testing"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

func TestAuthorizePermissionApplicationLayer(t *testing.T) {
	svc := New()
	if err := svc.AuthorizePermission(nil, "contests.view"); err == nil {
		t.Fatal("expected unauthorized for nil claims")
	}
	denied := &auth.Claims{Roles: []string{auth.RoleSupportAdmin}, Permissions: []string{"stats.view"}}
	if err := svc.AuthorizePermission(denied, "contests.manage"); err == nil {
		t.Fatal("expected forbidden")
	}
	allowed := &auth.Claims{Roles: []string{auth.RoleSupportAdmin}, Permissions: []string{"contests.view"}}
	if err := svc.AuthorizePermission(allowed, "contests.view"); err != nil {
		t.Fatalf("expected allow: %v", err)
	}
	super := &auth.Claims{Roles: []string{auth.RoleSuperAdmin}}
	if err := svc.AuthorizePermission(super, "anything"); err != nil {
		t.Fatalf("super admin: %v", err)
	}
}

func TestAuthorizePermissionRace(t *testing.T) {
	svc := New()
	claims := &auth.Claims{Roles: []string{auth.RoleSupportAdmin}, Permissions: []string{"a", "b"}}
	var wg sync.WaitGroup
	for i := 0; i < 32; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_ = svc.AuthorizePermission(claims, "a")
			_ = svc.AuthorizeRole(claims, auth.RoleSupportAdmin)
		}()
	}
	wg.Wait()
}

func TestAuthContextIsAdmin(t *testing.T) {
	if New().AuthContext() != auth.ContextAdmin {
		t.Fatal("admin module must own admin auth context")
	}
}
