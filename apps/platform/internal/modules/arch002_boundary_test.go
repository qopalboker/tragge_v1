package modules_test

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// ARCH-002: identity module must not import admin module internals.
func TestIdentityDoesNotImportAdminModule(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("caller")
	}
	root := filepath.Join(filepath.Dir(thisFile), "identity")
	entries, err := os.ReadDir(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".go") {
			continue
		}
		b, err := os.ReadFile(filepath.Join(root, e.Name()))
		if err != nil {
			t.Fatal(err)
		}
		if strings.Contains(string(b), "internal/modules/admin") {
			t.Fatalf("%s imports admin module — admin repository must stay unreachable from identity", e.Name())
		}
	}
}

// ARCH-002: admin repository type stays unexported.
func TestAdminRepositoryUnexported(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("caller")
	}
	src, err := os.ReadFile(filepath.Join(filepath.Dir(thisFile), "admin", "module.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(src)
	if !strings.Contains(s, "type adminRepository interface") {
		t.Fatal("expected unexported adminRepository")
	}
	if strings.Contains(s, "type AdminRepository interface") {
		t.Fatal("AdminRepository must not be exported")
	}
}
