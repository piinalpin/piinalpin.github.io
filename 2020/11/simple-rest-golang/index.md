# Simple REST Application using Go/Golang

### Introduction

Go is a statically typed language, The compiler produces optimized machine code, so CPU-intensive code is significantly more efficient than languages like Python or Ruby, which have byte-code compilers and use virtual machines for execution.

### Prerequisites

Make sure you have installed Golang on your device

### Step to create a simple REST application using Golang

1. Importing packages or modules
Install GorillaMux for it's efficiency and simplicity for learning `go get github.com/gorilla/mux`
```golang
package main

import (
	"encoding/json"
	"log"
	"net/http"

	// Mux package for routing
	"github.com/gorilla/mux"
)
```

2. Setting up our model
On golang, model as known as struct like a class in Java or Python, so create a struct and name it Contact.
```golang
// Create contact Model
type Contact struct {
	Name	string `json:"name"`
	Phone	string `json:"phone"`
	Email	string `json:"email"`
}
```

3. Setting up our utilities
We will create an utilities for headers response and custom message.
```golang
// Common header conforms to the http.HandlerFunc interface, and
// adds the Content-Type: application/json header to each response.
func CommonHeaders(handler http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        handler(w, r)
    }
}

// Ok message
type OkMessage struct {
	Message	string `json:"message"`
}
```

4. Create dummy data for contact model
```golang
// Construct contacts
func constructContacts() []Contact{
	 var contacts []Contact
	// Hardcoded data - @todo: add database
	contacts = append(contacts, Contact{Name: "Maverick", Phone: "98xxx-xxxxx", Email: "person1@mail.com"})
	contacts = append(contacts, Contact{Name: "Enoge", Phone: "96xxx-xxxxx", Email: "person2@mail.com"})
	contacts = append(contacts, Contact{Name: "Martin", Phone: "97xxx-xxxxx", Email: "person3@mail.com"})

	return contacts
}
```

5. Create get all contacts and detail contact function
```golang
// Get all contacts
func getAllContacts(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(constructContacts())
}

func getDetail(w http.ResponseWriter, r *http.Request) {
	// Get params
	params := mux.Vars(r)

	// Looping for through contacts and find one by id
	for _, item := range constructContacts() {
		if item.Name == params["name"] {
			json.NewEncoder(w).Encode(item)
			return
		}
	}

	json.NewEncoder(w).Encode(&Contact{})

}
```

6. Create function to add new contact
```golang
// Create contact
func createContact(w http.ResponseWriter, r *http.Request) {
	var contact Contact
	_ = json.NewDecoder(r.Body).Decode(&contact)
	json.NewEncoder(w).Encode(contact)
}
```

7. Create function to update contact by name
```golang
	// Update contact
func updateContact(w http.ResponseWriter, r *http.Request) {
	// Get params
	params := mux.Vars(r)

	// Looping for through contacts and fine one by id
	for _, item := range constructContacts() {
		if item.Name == params["name"] {
			var contact Contact
			_ = json.NewDecoder(r.Body).Decode(&contact)
			json.NewEncoder(w).Encode(contact)
			return
		}
	}
}
```

8. Create function to delete contact by name
```golang
// Delete contact
func deleteContact(w http.ResponseWriter, r *http.Request) {
	var msg OkMessage
	msg.Message = "ok"

	// TODO: Add handle to filter by id
	json.NewEncoder(w).Encode(msg)
}
```

9. Create main function
Firstly we initialize the router variable as r and the GorillaMux is used by calling mux.NewRouter(). Then we add all the HandleFunc() methods which a basic CRUD application will have. Here, I have used some named-parameters {name}, so that we can access the contact details using the name of the person. And serve on ports 8000.

```golang
func main() {
	
	// Init router
	route := mux.NewRouter()

	route.HandleFunc("/contacts", CommonHeaders(getAllContacts)).Methods("GET")
	route.HandleFunc("/contacts", CommonHeaders(createContact)).Methods("POST")
	route.HandleFunc("/contacts/{name}", CommonHeaders(getDetail)).Methods("GET")
	route.HandleFunc("/contacts/{name}", CommonHeaders(updateContact)).Methods("PUT")
	route.HandleFunc("/contacts/{name}", CommonHeaders(deleteContact)).Methods("DELETE")

	// Start server
	log.Fatal(http.ListenAndServe(":8000", route))

}
```

### Thankyou

[Medium](https://medium.com/swlh/create-rest-api-in-minutes-with-go-golang-c4a2c6279721) - Create REST API in Minutes With Go/Golang

[Github](https://github.com/GowriSankar-JG/REST-API-using-GO) - REST Api using GO