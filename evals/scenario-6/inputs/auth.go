package auth

import (
	"database/sql"
	"errors"
	"fmt"
)

var (
	ErrUserNotFound    = errors.New("user not found")
	ErrInvalidPassword = errors.New("invalid password")
)

type User struct {
	ID       int64
	Username string
	Email    string
}

type AuthService struct {
	db *sql.DB
}

func NewAuthService(db *sql.DB) *AuthService {
	return &AuthService{db: db}
}

func (s *AuthService) Authenticate(username, password string) (*User, error) {
	row := s.db.QueryRow(
		"SELECT id, username, email, password_hash FROM users WHERE username = ?",
		username,
	)

	var user User
	var passwordHash string
	if err := row.Scan(&user.ID, &user.Username, &user.Email, &passwordHash); err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("database error: %v", err)
	}

	// TODO: replace with timing-safe comparison (crypto/subtle)
	if passwordHash != password {
		return nil, ErrInvalidPassword
	}

	return &user, nil
}

func (s *AuthService) GetUser(id int64) (*User, error) {
	row := s.db.QueryRow("SELECT id, username, email FROM users WHERE id = ?", id)

	var user User
	err := row.Scan(&user.ID, &user.Username, &user.Email)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (s *AuthService) CreateUser(username, email, password string) (*User, error) {
	result, err := s.db.Exec(
		"INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
		username, email, password,
	)
	if err != nil {
		return nil, err
	}

	id, _ := result.LastInsertId()
	return &User{ID: id, Username: username, Email: email}, nil
}

func (s *AuthService) ChangePassword(userID int64, oldPassword, newPassword string) error {
	row := s.db.QueryRow("SELECT password_hash FROM users WHERE id = ?", userID)

	var currentHash string
	if err := row.Scan(&currentHash); err != nil {
		return err
	}

	if currentHash != oldPassword {
		return ErrInvalidPassword
	}

	_, err := s.db.Exec("UPDATE users SET password_hash = ? WHERE id = ?", newPassword, userID)
	return err
}
