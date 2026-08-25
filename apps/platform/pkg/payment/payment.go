package payment

import (
	"net/http"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/payment"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/wallet"
)

type Service = payment.Service
type Provider = payment.Provider
type CreatePaymentRequest = payment.CreatePaymentRequest
type CreatePaymentResponse = payment.CreatePaymentResponse

func New(wallets wallet.Service) Service { return payment.New(wallets) }

func RegisterRoutes(mux *http.ServeMux, svc Service) {
	payment.RegisterRoutes(mux, svc)
}
