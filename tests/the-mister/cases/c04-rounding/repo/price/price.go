package price

// Apply returns the price in cents after a percentage discount.
func Apply(cents int, percent int) int {
	return cents * (100 - percent) / 100
}
