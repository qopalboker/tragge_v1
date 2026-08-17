package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
	"go.uber.org/zap"
)

const adminMFAPolicyKey = "admin_mfa_enabled"

// isAdminMFAEnabled returns the persistent global Super Admin MFA policy.
// Missing row defaults to false (MVP: MFA off).
func (a *App) isAdminMFAEnabled(ctx context.Context) (bool, error) {
	var enabled bool
	err := a.pool.Primary().QueryRowContext(ctx,
		`SELECT value_bool FROM admin_security_settings WHERE key = $1`,
		adminMFAPolicyKey,
	).Scan(&enabled)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		// Pre-migration / missing table: fail open to MVP-off for availability,
		// but log so operators can apply 0104.
		a.log().Warn("admin MFA policy read failed; defaulting to disabled", zap.Error(err))
		return false, nil
	}
	return enabled, nil
}

type adminMFAPolicyResponse struct {
	Enabled           bool       `json:"admin_mfa_enabled"`
	ActorEnrolled     bool       `json:"actor_enrolled"`
	UpdatedAt         *time.Time `json:"updated_at,omitempty"`
	CanToggle         bool       `json:"can_toggle"`
	RequiresEnrollment bool      `json:"requires_enrollment_to_enable"`
}

func (a *App) handleGetAdminMFAPolicy(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userID := auth.GetUserID(ctx)
	if userID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	enabled, err := a.isAdminMFAEnabled(ctx)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": adminMsg.InternalError})
		return
	}

	var enrolled bool
	_ = a.pool.Primary().QueryRowContext(ctx,
		`SELECT EXISTS (SELECT 1 FROM admin_mfa_credentials WHERE user_id=$1)`,
		userID,
	).Scan(&enrolled)

	var updatedAt *time.Time
	var ts time.Time
	if err := a.pool.Primary().QueryRowContext(ctx,
		`SELECT updated_at FROM admin_security_settings WHERE key=$1`, adminMFAPolicyKey,
	).Scan(&ts); err == nil {
		updatedAt = &ts
	}

	canToggle := false
	for _, role := range auth.GetRoles(ctx) {
		if role == auth.RoleSuperAdmin {
			canToggle = true
			break
		}
	}

	writeJSON(w, http.StatusOK, adminMFAPolicyResponse{
		Enabled:            enabled,
		ActorEnrolled:      enrolled,
		UpdatedAt:          updatedAt,
		CanToggle:          canToggle,
		RequiresEnrollment: !enrolled,
	})
}

type setAdminMFAPolicyRequest struct {
	Enabled bool `json:"admin_mfa_enabled"`
}

func (a *App) handleSetAdminMFAPolicy(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userID := auth.GetUserID(ctx)
	if userID == "" {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
		return
	}

	// Super Admin only (strongest existing role for global security policy).
	isSuper := false
	for _, role := range auth.GetRoles(ctx) {
		if role == auth.RoleSuperAdmin {
			isSuper = true
			break
		}
	}
	if !isSuper {
		writeJSON(w, http.StatusForbidden, map[string]string{"error": "forbidden"})
		return
	}

	var req setAdminMFAPolicyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": adminMsg.InvalidBody})
		return
	}

	oldEnabled, _ := a.isAdminMFAEnabled(ctx)
	if oldEnabled == req.Enabled {
		a.handleGetAdminMFAPolicy(w, r)
		return
	}

	if req.Enabled {
		var enrolled bool
		if err := a.pool.Primary().QueryRowContext(ctx,
			`SELECT EXISTS (SELECT 1 FROM admin_mfa_credentials WHERE user_id=$1)`,
			userID,
		).Scan(&enrolled); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": adminMsg.InternalError})
			return
		}
		if !enrolled {
			writeJSON(w, http.StatusConflict, map[string]interface{}{
				"error":               "mfa_enrollment_required",
				"message":             "Enable MFA only after completing authenticator enrollment for this Super Admin.",
				"enrollment_required": true,
			})
			return
		}
	}

	_, err := a.pool.Primary().ExecContext(ctx, `
		INSERT INTO admin_security_settings (key, value_bool, updated_at, updated_by)
		VALUES ($1, $2, NOW(), $3)
		ON CONFLICT (key) DO UPDATE SET
			value_bool = EXCLUDED.value_bool,
			updated_at = NOW(),
			updated_by = EXCLUDED.updated_by
	`, adminMFAPolicyKey, req.Enabled, userID)
	if err != nil {
		a.log().Error("failed to update admin MFA policy", zap.Error(err))
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": adminMsg.InternalError})
		return
	}

	// Audit without secrets/OTP
	a.logAuditEvent(ctx, userID, "admin.security.mfa_policy.changed", "security", adminMFAPolicyKey,
		map[string]string{
			"old_value": boolString(oldEnabled),
			"new_value": boolString(req.Enabled),
		})

	a.handleGetAdminMFAPolicy(w, r)
}

func boolString(v bool) string {
	if v {
		return "true"
	}
	return "false"
}

const adminMFAPolicyResourceID = "admin_mfa_policy"

// requireAdminMFAPolicySensitive binds reauth grants to a fixed global resource id.
func (a *App) requireAdminMFAPolicySensitive() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if err := a.consumeSensitiveGrant(r, actionAdminMFAPolicy, adminMFAPolicyResourceID, "settings.manage"); err != nil {
				writeJSON(w, http.StatusForbidden, map[string]string{"error": "sensitive action denied"})
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
