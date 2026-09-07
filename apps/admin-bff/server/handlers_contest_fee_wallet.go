package server

import (
	"net/http"
	"strconv"
)

func (a *App) handleGetContestFeeWallet(w http.ResponseWriter, r *http.Request) {
	page := 1
	limit := 25
	if value := r.URL.Query().Get("page"); value != "" {
		parsed, err := strconv.Atoi(value)
		if err != nil || parsed < 1 {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid page"})
			return
		}
		page = parsed
	}
	if value := r.URL.Query().Get("limit"); value != "" {
		parsed, err := strconv.Atoi(value)
		if err != nil || parsed < 1 || parsed > 100 {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid limit"})
			return
		}
		limit = parsed
	}
	view, err := a.walletService.GetContestFeeWallet(r.Context(), limit, (page-1)*limit)
	if err != nil {
		a.log().Error("Failed to read Contest Fee Wallet")
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": adminMsg.InternalError})
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"wallet":   view,
		"page":     page,
		"per_page": limit,
	})
}
