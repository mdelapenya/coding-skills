package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/example/userservice/handlers"
	_ "github.com/mattn/go-sqlite3"
)

func main() {
	db, err := sql.Open("sqlite3", "./userservice.db")
	if err != nil {
		log.Fatalf("open db: %v", err)
	}
	defer db.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v2/users/{id}", handlers.GetUser(db))
	mux.HandleFunc("GET /api/v2/users", handlers.ListUsers(db))

	log.Println("user service listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
