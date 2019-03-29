package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

func main() {
	http.ListenAndServe(":24001", http.HandlerFunc(upload))
}

func upload(w http.ResponseWriter, req *http.Request) {
	fmt.Printf("begin upload\n")

	path := req.Header.Get("Camera-File")

	f, err := os.Create(filepath.Join("tmp", path))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	defer f.Close()

	io.Copy(f, req.Body)

	fmt.Printf("uploaded: %s\n", path)
}
