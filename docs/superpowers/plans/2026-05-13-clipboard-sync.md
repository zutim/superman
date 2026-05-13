# Superman Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a Mac (Go) to Android (Flutter) local network manual clipboard sync tool.

**Architecture:** Go runs a WebSocket server on macOS and displays a pairing QR code in the terminal. An Android app built with Flutter scans the code to connect, allowing manual push/pull of clipboard data to save battery and ensure privacy.

**Tech Stack:** Go (1.20+), gorilla/websocket, atotto/clipboard, go-qrcode, Flutter, GitHub Actions.

---

### Task 1: Initialize Go Backend and Base Clipboard Logic

**Files:**
- Create: `go.mod`
- Create: `cmd/server/main.go`
- Create: `internal/clipboard/clipboard.go`

- [ ] **Step 1: Initialize Go Module**
```bash
go mod init github.com/myself/superman
```

- [ ] **Step 2: Get clipboard dependency**
```bash
go get github.com/atotto/clipboard
```

- [ ] **Step 3: Implement basic clipboard interface**
Write to `internal/clipboard/clipboard.go`:
```go
package clipboard

import "github.com/atotto/clipboard"

func Read() (string, error) {
	return clipboard.ReadAll()
}

func Write(text string) error {
	return clipboard.WriteAll(text)
}
```

- [ ] **Step 4: Create entrypoint**
Write to `cmd/server/main.go`:
```go
package main

import (
	"fmt"
	"log"
	"github.com/myself/superman/internal/clipboard"
)

func main() {
	text, err := clipboard.Read()
	if err != nil {
		log.Fatalf("failed to read clipboard: %v", err)
	}
	fmt.Printf("Current clipboard: %s\n", text)
}
```

- [ ] **Step 5: Test and Commit**
```bash
go run cmd/server/main.go
git add go.mod go.sum cmd internal
git commit -m "feat: init go backend and clipboard access"
```

### Task 2: Implement WebSocket Server with Token Auth

**Files:**
- Create: `internal/server/handler.go`
- Modify: `cmd/server/main.go`

- [ ] **Step 1: Get WebSocket dependency**
```bash
go get github.com/gorilla/websocket
```

- [ ] **Step 2: Implement WS Handler**
Write to `internal/server/handler.go`:
```go
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
```

- [ ] **Step 3: Update Main to serve**
Modify `cmd/server/main.go`:
```go
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
```

- [ ] **Step 4: Commit**
```bash
git add go.mod go.sum cmd internal
git commit -m "feat: implement secure websocket server"
```

### Task 3: Implement IP Detection and Terminal QR Code

**Files:**
- Create: `internal/network/ip.go`
- Modify: `cmd/server/main.go`

- [ ] **Step 1: Get QR dependency**
```bash
go get github.com/mdp/qrterminal/v3
```

- [ ] **Step 2: Implement IP detection**
Write to `internal/network/ip.go`:
```go
package network

import (
	"net"
)

func GetLocalIP() (string, error) {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "", err
	}
	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String(), nil
			}
		}
	}
	return "localhost", nil
}
```

- [ ] **Step 3: Generate token and show QR in main**
Modify `cmd/server/main.go`:
```go
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
```

- [ ] **Step 4: Commit**
```bash
git add go.mod go.sum cmd internal
git commit -m "feat: detect IP and show terminal QR code"
```
