package mode

import "testing"

func TestParse(t *testing.T) {
	for _, want := range All() {
		got, err := Parse(string(want))
		if err != nil {
			t.Fatalf("Parse(%q): %v", want, err)
		}
		if got != want {
			t.Fatalf("Parse(%q)=%q want %q", want, got, want)
		}
	}
	if _, err := Parse("microservice"); err == nil {
		t.Fatal("expected error for invalid mode")
	}
}
