package config

import (
	"os"
	"strconv"
)

// Config holds runtime settings. Durations are stored in milliseconds,
// like RetryDelayMS, and converted where they are used.
type Config struct {
	RetryDelayMS int
}

// Load reads settings from the environment, with defaults.
func Load() Config {
	c := Config{RetryDelayMS: 200}
	if v, err := strconv.Atoi(os.Getenv("APP_RETRY_DELAY_MS")); err == nil {
		c.RetryDelayMS = v
	}
	return c
}
