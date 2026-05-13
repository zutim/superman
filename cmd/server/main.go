package main

import (
	"log"
	"net/http"
	"github.com/myself/superman/internal/server"
)

func main() {
	token := "secret123" // Hardcoded for now
	http.HandleFunc("/ws", server.Handler(token))
	
	log.Println("Starting server on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
