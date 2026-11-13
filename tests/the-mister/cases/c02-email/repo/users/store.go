package users

import (
	"errors"
	"strings"
)

// User is a registered account.
type User struct {
	ID    int
	Email string
}

// Store keeps users in memory.
type Store struct {
	byID map[int]*User
	next int
}

// NewStore returns an empty store.
func NewStore() *Store { return &Store{byID: map[int]*User{}} }

// ErrInvalidEmail is returned for an address without "@".
var ErrInvalidEmail = errors.New("invalid email")

// Create registers a user.
func (s *Store) Create(email string) (*User, error) {
	if !strings.Contains(email, "@") {
		return nil, ErrInvalidEmail
	}
	s.next++
	u := &User{ID: s.next, Email: email}
	s.byID[u.ID] = u
	return u, nil
}
