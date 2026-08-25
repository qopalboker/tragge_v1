package wallet

import (
	"net/http"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/wallet"
	pkgwallet "github.com/Parsaeffatravesh/tragge/packages/wallet"
)

type Service = wallet.Service

func NewMemory() Service { return wallet.New() }

func NewWithPackagesWallet(svc *pkgwallet.Service) Service {
	return wallet.NewWithPackagesWallet(svc)
}

func PackagesWallet(s Service) *pkgwallet.Service { return wallet.PackagesWallet(s) }

func RegisterRoutes(mux *http.ServeMux, svc Service) {
	mux.HandleFunc("/api/wallet/v1/boundary", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"module":"wallet","sole_ledger_authority":true,"fin006":"out_of_scope"}`))
	})
}
