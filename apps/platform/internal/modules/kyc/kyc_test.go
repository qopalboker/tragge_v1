package kyc

import (
	"context"
	"testing"
)

func TestKYCReviewStateMachine(t *testing.T) {
	svc := New()
	if err := svc.RequireApproved(context.Background(), "u1"); err == nil {
		t.Fatal("expected not approved")
	}
	if err := svc.Submit(context.Background(), "u1"); err != nil {
		t.Fatal(err)
	}
	if err := svc.Approve(context.Background(), "u1", "ok"); err != nil {
		t.Fatal(err)
	}
	if err := svc.RequireApproved(context.Background(), "u1"); err != nil {
		t.Fatal(err)
	}
}
