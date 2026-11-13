package users

import "errors"

// ErrNotFound is returned for an unknown user.
var ErrNotFound = errors.New("not found")

// UpdateEmail changes a user's address.
func (s *Store) UpdateEmail(id int, email string) error {
	u, ok := s.byID[id]
	if !ok {
		return ErrNotFound
	}
	u.Email = email
	return nil
}

// FindByEmail returns the user with that address.
func (s *Store) FindByEmail(email string) (*User, error) {
	for _, u := range s.byID {
		if u.Email == email {
			return u, nil
		}
	}
	return nil, ErrNotFound
}
