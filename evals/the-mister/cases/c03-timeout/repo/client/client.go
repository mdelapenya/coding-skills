package client

import (
	"net/http"
	"time"

	"example.com/c03-timeout/config"
)

// New builds the HTTP client and the retry delay from configuration.
func New(c config.Config) (*http.Client, time.Duration) {
	return &http.Client{}, time.Duration(c.RetryDelayMS) * time.Millisecond
}
