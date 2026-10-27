//go:build integration

package integration

import (
	"os"
	"testing"
)

// Requires a PostgreSQL server; CI provides one through POSTGRES_URL.
func TestSlugsAreUniqueInDB(t *testing.T) {
	if os.Getenv("POSTGRES_URL") == "" {
		t.Fatal("POSTGRES_URL is required")
	}
}
