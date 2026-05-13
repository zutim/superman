package server

import (
	"log"
	"net/http"
	"github.com/gorilla/websocket"
	"github.com/myself/superman/internal/clipboard"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true }, // Allow local clients
}

// Handler returns an http.HandlerFunc that verifies the token
func Handler(expectedToken string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token := r.URL.Query().Get("token")
		if token != expectedToken {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Printf("upgrade failed: %v", err)
			return
		}
		defer conn.Close()

		log.Println("Client connected!")

		for {
			mt, message, err := conn.ReadMessage()
			if err != nil {
				log.Printf("read err: %v", err)
				break
			}
			
			// If client sends data, we put it on mac clipboard
			if len(message) > 0 {
			    clipboard.Write(string(message))
			    log.Printf("Updated Mac clipboard with data from phone")
			}
			
			// Immediately reply with current Mac clipboard content 
			// (this acts as a pull response if message was empty or "PULL")
			current, _ := clipboard.Read()
			err = conn.WriteMessage(mt, []byte(current))
			if err != nil {
				log.Printf("write err: %v", err)
				break
			}
		}
	}
}
