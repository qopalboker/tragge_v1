package adapters_test

import (
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// ARCH-001: adapters (HTTP/mode shells) must not import foreign module packages
// directly. They obtain Service interfaces only via compose.Platform.
func TestAdaptersDoNotImportModulePackagesDirectly(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	root := filepath.Dir(thisFile)

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		fset := token.NewFileSet()
		f, parseErr := parser.ParseFile(fset, path, nil, parser.ImportsOnly)
		if parseErr != nil {
			return parseErr
		}
		for _, imp := range f.Imports {
			impPath := strings.Trim(imp.Path.Value, `"`)
			if strings.Contains(impPath, "/internal/modules/") {
				t.Errorf("%s imports module package %s — adapters must use compose.Platform Service fields only",
					path, impPath)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
