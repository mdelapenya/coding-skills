package kv

// Store is a key-value store. Keys are arbitrary strings.
type Store interface {
	Put(key, value string) error
	Get(key string) (string, bool, error)
}
