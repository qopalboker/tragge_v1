package identity

import (
	"context"
	"testing"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

func TestAuthContextIsUser(t *testing.T) {
	if New().AuthContext() != auth.ContextUser {
		t.Fatal("identity module must own user auth context")
	}
}

func TestValidateAccessTokenWithoutAuth(t *testing.T) {
	_, err := New().ValidateAccessToken(context.Background(), "token")
	if err == nil {
		t.Fatal("expected unauthorized without auth")
	}
}
