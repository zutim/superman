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
