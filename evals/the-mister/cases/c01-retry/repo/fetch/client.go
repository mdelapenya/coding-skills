package fetch

import (
	"errors"
	"time"
)

// ErrTransient marks a failure worth retrying.
var ErrTransient = errors.New("transient")

// Timeout is how long one call may take.
const Timeout = 1 * time.Second

// Client fetches from a backend that sometimes fails transiently.
type Client struct {
	Call func(timeout time.Duration) (string, error)
}

// Get fetches once per attempt, retrying transient failures three times.
func (c Client) Get() (string, error) {
	var out string
	err := Retry(3, 10*time.Millisecond, func() error {
		v, err := c.Call(Timeout)
		if err != nil {
			return err
		}
		out = v
		return nil
	})
	return out, err
}
