package ticket

import (
	"context"
	"testing"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/notification"
)

func TestCreateEnqueuesOutbox(t *testing.T) {
	notif := notification.New()
	svc := New(notif)
	if err := svc.Create(context.Background(), Ticket{ID: "t1", UserID: "u1", Subject: "help", Status: "open"}); err != nil {
		t.Fatal(err)
	}
	pending, err := notif.PendingOutbox(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(pending) != 1 || pending[0].Topic != "tickets.v1.created" {
		t.Fatalf("pending=%v", pending)
	}
}
