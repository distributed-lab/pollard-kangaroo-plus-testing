package main

import (
	"encoding/json"
	"fmt"
	"github.com/go-chi/chi"
	"github.com/go-chi/cors"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
)

func getTableHandler(w http.ResponseWriter, r *http.Request) {
	fileName := r.URL.Query().Get("file_name")
	if fileName == "" {
		fileName = "output.json"
	}

	file, err := os.Open(fileName)
	if err != nil {
		http.Error(w, "Could not open file", http.StatusInternalServerError)
		return
	}
	defer file.Close()

	fileInfo, err := file.Stat()
	if err != nil {
		http.Error(w, "Could not get file info", http.StatusInternalServerError)
		return
	}
	fileSize := fileInfo.Size()

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("Content-Disposition", "attachment; filename="+fileInfo.Name())
	w.Header().Set("Content-Length", strconv.FormatInt(fileSize, 10))

	w.WriteHeader(http.StatusOK)

	_, err = io.Copy(w, file)
	if err != nil {
		http.Error(w, "Error sending file", http.StatusInternalServerError)
		return
	}
}


func uploadTableHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST requests are allowed", http.StatusMethodNotAllowed)
		return
	}

	var data map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	jsonData, err := json.MarshalIndent(data, "", "    ")
	if err != nil {
		http.Error(w, "Error marshaling JSON", http.StatusInternalServerError)
		return
	}

	err = ioutil.WriteFile(data["file_name"].(string), jsonData, 0644)
	if err != nil {
		http.Error(w, "Error writing to file", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("JSON received and written"))
}

type RequestData struct {
	Filename string `json:"filename"`
	Text     string `json:"text"`
}

func writelogHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is allowed", http.StatusMethodNotAllowed)
		return
	}

	var data RequestData
	err := json.NewDecoder(r.Body).Decode(&data)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	file, err := os.OpenFile(fmt.Sprintf("logs/%s", data.Filename), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to open file: %v", err), http.StatusInternalServerError)
		return
	}
	defer file.Close()

	_, err = file.WriteString(data.Text + "\n")
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to write to file: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func startHttpListener(port uint, r *chi.Mux) {
	fmt.Printf("Server is listening on port %d...\n", port)

	err := http.ListenAndServe(fmt.Sprintf(":%d", port), r)
	if err != nil {
		fmt.Println("Error starting the server:", err)
	}
}

func Run(port uint) {
	r := chi.NewRouter()

	corsMiddleware := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST"},
		AllowedHeaders:   []string{"Content-Type", "Authorization"},
		AllowCredentials: false,
		MaxAge:           300,
	})

	r.Use(corsMiddleware.Handler)

	r.Route("/", func(r chi.Router) {
		r.Get("/table", getTableHandler)
		r.Post("/upload", uploadTableHandler)
		r.Post("/log", writelogHandler)
	})

	startHttpListener(port, r)
}

func main() {
	Run(3001)
}
