package compose

import (
	"context"
	"testing"
)

func TestNewWiresRequiredModules(t *testing.T) {
	p := New()
	want := []string{
		"identity", "contest", "wallet", "payment", "kyc",
		"settlement", "leaderboard", "notification", "ticket", "admin", "scheduler",
		"events",
	}
	mods := p.Modules()
	if len(mods) != len(want) {
		t.Fatalf("modules=%d want %d", len(mods), len(want))
	}
	for i, name := range want {
		if mods[i].Name() != name {
			t.Fatalf("module[%d]=%q want %q", i, mods[i].Name(), name)
		}
	}
	if err := p.Ready(context.Background()); err != nil {
		t.Fatalf("Ready: %v", err)
	}
}
