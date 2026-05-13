package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/mdp/qrterminal/v3"
	"github.com/myself/superman/internal/network"
	"github.com/myself/superman/internal/server"
)

func generateToken() string {
	b := make([]byte, 8)
	rand.Read(b)
	return hex.EncodeToString(b)
}

func main() {
	ip, _ := network.GetLocalIP()
	token := generateToken()
	
	wsURL := fmt.Sprintf("ws://%s:8080/ws?token=%s", ip, token)
	
	fmt.Println("Scan this QR code with the Superman Android App:")
	qrterminal.Generate(wsURL, qrterminal.L, os.Stdout)
	fmt.Printf("\nURL: %s\n", wsURL)

	http.HandleFunc("/ws", server.Handler(token))
	
	log.Println("Starting WebSocket server on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
