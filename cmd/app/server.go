package main

import (
	"app/internal/routes"

	"github.com/gin-gonic/gin"
)

// Webサーバを起動する
func runServer() error {
	r := gin.Default()
	routes.SetupRoutes(r)
	return r.Run(":3000")
}
