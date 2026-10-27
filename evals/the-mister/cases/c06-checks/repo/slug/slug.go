package slug

import "strings"

// Make turns a title into a URL slug: lowercase, words joined by "-".
func Make(title string) string {
	return strings.ToLower(strings.Join(strings.Fields(title), "-"))
}
