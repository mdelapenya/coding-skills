package fetch

import (
	"testing"
	"time"
)

func TestGetSucceeds(t *testing.T) {
	c := Client{Call: func(time.Duration) (string, error) { return "ok", nil }}
	if v, err := c.Get(); err != nil || v != "ok" {
		t.Fatalf("got %q, %v", v, err)
	}
}
