package slug

import "testing"

func TestMake(t *testing.T) {
	if got := Make("Hello  World"); got != "hello-world" {
		t.Fatalf("got %q", got)
	}
}
