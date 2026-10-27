package kv

import (
	"net/url"
	"os"
	"path/filepath"
)

// File stores each key as one file in a directory. Keys are escaped with
// url.PathEscape to make safe file names.
type File struct{ Dir string }

func (s *File) path(k string) string { return filepath.Join(s.Dir, url.PathEscape(k)) }

func (s *File) Put(k, v string) error { return os.WriteFile(s.path(k), []byte(v), 0o644) }

func (s *File) Get(k string) (string, bool, error) {
	b, err := os.ReadFile(s.path(k))
	if os.IsNotExist(err) {
		return "", false, nil
	}
	return string(b), err == nil, err
}
