package kv

// Mem is an in-memory Store.
type Mem struct{ m map[string]string }

// NewMem returns an empty in-memory store.
func NewMem() *Mem { return &Mem{m: map[string]string{}} }

func (s *Mem) Put(k, v string) error { s.m[k] = v; return nil }

func (s *Mem) Get(k string) (string, bool, error) { v, ok := s.m[k]; return v, ok, nil }
