package handlers_test

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/example/userservice/handlers"
	_ "github.com/mattn/go-sqlite3"
)

func setupTestDB(t *testing.T) *sql.DB {
	t.Helper()
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	_, err = db.Exec(`CREATE TABLE users (
		id INTEGER PRIMARY KEY,
		name TEXT NOT NULL,
		email TEXT NOT NULL,
		created_at TEXT NOT NULL
	)`)
	if err != nil {
		t.Fatalf("create table: %v", err)
	}
	_, err = db.Exec(`INSERT INTO users VALUES (1, 'Alice', 'alice@example.com', '2024-01-15T09:00:00Z')`)
	if err != nil {
		t.Fatalf("seed: %v", err)
	}
	return db
}

func TestGetUser_Found(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	req := httptest.NewRequest("GET", "/api/v2/users/1", nil)
	req.SetPathValue("id", "1")
	rr := httptest.NewRecorder()

	handlers.GetUser(db)(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rr.Code, rr.Body.String())
	}
	var u handlers.User
	if err := json.NewDecoder(rr.Body).Decode(&u); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if u.Name != "Alice" {
		t.Errorf("expected Alice, got %q", u.Name)
	}
}

func TestGetUser_NotFound(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	req := httptest.NewRequest("GET", "/api/v2/users/999", nil)
	req.SetPathValue("id", "999")
	rr := httptest.NewRecorder()

	handlers.GetUser(db)(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rr.Code)
	}
}

func TestGetUser_BadID(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	req := httptest.NewRequest("GET", "/api/v2/users/abc", nil)
	req.SetPathValue("id", "abc")
	rr := httptest.NewRecorder()

	handlers.GetUser(db)(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rr.Code)
	}
}
