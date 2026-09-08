package server

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
)

// handleGetContestPrizePool exposes read-only custody evidence. Route-level
// authorization restricts this to Super Admin; no mutation route exists.
func (a *App) handleGetContestPrizePool(w http.ResponseWriter, r *http.Request) {
	page := 1
	if value := r.URL.Query().Get("page"); value != "" {
		parsed, err := strconv.Atoi(value)
		if err != nil || parsed < 1 {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid page"})
			return
		}
		page = parsed
	}
	view, err := a.walletService.GetContestPrizePool(r.Context(), chi.URLParam(r, "contestID"), 25, (page-1)*25)
	if err != nil {
		a.log().Error("Failed to read contest Prize Pool")
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": adminMsg.InternalError})
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"pool": view, "page": page, "per_page": 25})
}
