package users

import (
	"context"
	"fmt"

	"github.com/example/userdb/internal/db"
)

// User represents a user record.
type User struct {
	ID    string
	Name  string
	Email string
}

// LookupUser retrieves a user by ID from the database.
func LookupUser(ctx context.Context, conn *db.Conn, id string) (*User, error) {
	row := conn.QueryRowContext(ctx,
		"SELECT id, name, email FROM users WHERE id = $1", id)
	var u User
	if err := row.Scan(&u.ID, &u.Name, &u.Email); err != nil {
		return nil, fmt.Errorf("lookup user %q: %w", id, err)
	}
	return &u, nil
}
