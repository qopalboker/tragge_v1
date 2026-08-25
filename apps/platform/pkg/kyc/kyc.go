package kyc

import (
	"net/http"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/kyc"
)

type Service = kyc.Service

func New() Service { return kyc.New() }

func RegisterRoutes(mux *http.ServeMux, svc Service) {
	kyc.RegisterRoutes(mux, svc)
}
