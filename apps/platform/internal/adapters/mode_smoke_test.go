package adapters_test

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/adapters/api"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/adapters/realtime"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/adapters/worker"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/compose"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/mode"
)

func TestModeStartupSmokeHealthAndReady(t *testing.T) {
	platform := compose.New()
	version := "test"

	cases := []struct {
		name  string
		mode  mode.Mode
		start func(lis net.Listener) (shutdown func(context.Context) error)
	}{
		{
			name: "api",
			mode: mode.API,
			start: func(lis net.Listener) func(context.Context) error {
				srv := api.New(platform, lis.Addr().String(), version)
				go func() { _ = srv.Serve(lis) }()
				return srv.Shutdown
			},
		},
		{
			name: "realtime",
			mode: mode.Realtime,
			start: func(lis net.Listener) func(context.Context) error {
				srv := realtime.New(platform, lis.Addr().String(), version)
				go func() { _ = srv.Serve(lis) }()
				return srv.Shutdown
			},
		},
		{
			name: "worker",
			mode: mode.Worker,
			start: func(lis net.Listener) func(context.Context) error {
				srv := worker.New(platform, lis.Addr().String(), version)
				go func() { _ = srv.Serve(lis) }()
				return srv.Shutdown
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			lis, err := net.Listen("tcp", "127.0.0.1:0")
			if err != nil {
				t.Fatal(err)
			}
			base := "http://" + lis.Addr().String()
			shutdown := tc.start(lis)
			defer func() {
				ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
				defer cancel()
				_ = shutdown(ctx)
			}()

			client := &http.Client{Timeout: 2 * time.Second}
			waitOK(t, client, base+"/healthz")
			waitOK(t, client, base+"/readyz")

			if tc.mode != mode.API {
				return
			}
			for _, path := range []string{
				"/v1/platform/modules",
				"/api/user/auth/v1/boundary",
				"/api/admin/auth/v1/boundary",
			} {
				resp, err := client.Get(base + path)
				if err != nil {
					t.Fatal(err)
				}
				body, _ := io.ReadAll(resp.Body)
				resp.Body.Close()
				if resp.StatusCode != http.StatusOK {
					t.Fatalf("%s status=%d body=%s", path, resp.StatusCode, body)
				}
			}
		})
	}
}

func waitOK(t *testing.T, client *http.Client, url string) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	var last error
	for time.Now().Before(deadline) {
		resp, err := client.Get(url)
		if err == nil {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			if resp.StatusCode == http.StatusOK {
				return
			}
			last = fmt.Errorf("status %d body %s", resp.StatusCode, body)
		} else {
			last = err
		}
		time.Sleep(25 * time.Millisecond)
	}
	t.Fatalf("%s not ready: %v", url, last)
}
