package config

import "testing"

func TestDefaults(t *testing.T) {
	t.Setenv("APP_RETRY_DELAY_MS", "")
	if got := Load().RetryDelayMS; got != 200 {
		t.Fatalf("RetryDelayMS = %d", got)
	}
}
