package kv

import "testing"

func TestMemPutGet(t *testing.T) {
	s := NewMem()
	_ = s.Put("a", "1")
	if v, ok, _ := s.Get("a"); !ok || v != "1" {
		t.Fatalf("got %q %v", v, ok)
	}
}
