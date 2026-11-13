package users

import "testing"

func TestCreate(t *testing.T) {
	s := NewStore()
	if _, err := s.Create("a@example.com"); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Create("nope"); err != ErrInvalidEmail {
		t.Fatalf("want ErrInvalidEmail, got %v", err)
	}
}
