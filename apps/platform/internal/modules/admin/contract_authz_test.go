package admin

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

// Contract: Platform admin authorize endpoint mirrors application-service decisions.
func TestAuthorizeHTTPContract(t *testing.T) {
	mux := http.NewServeMux()
	RegisterRoutes(mux, New())

	body, _ := json.Marshal(map[string]any{
		"permission": "contests.view",
		"claims": map[string]any{
			"user_id":     "u1",
			"roles":       []string{auth.RoleSupportAdmin},
			"permissions": []string{"contests.view"},
		},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/admin/auth/v1/authorize", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}
