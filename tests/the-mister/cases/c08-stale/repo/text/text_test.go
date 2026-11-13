package text

import "testing"

func TestShout(t *testing.T) {
	if got := Shout("hi"); got != "HI!" {
		t.Fatalf("got %q", got)
	}
}
