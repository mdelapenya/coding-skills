package fetch

import "time"

// Retry calls fn up to attempts times, sleeping delay between failures,
// and returns nil as soon as one call succeeds.
func Retry(attempts int, delay time.Duration, fn func() error) error {
	var err error
	for i := 0; i < attempts; i++ {
		err = fn()
		if err == nil {
			return nil
		}
		if i < attempts-1 {
			time.Sleep(delay)
		}
		return err
	}
	return err
}
