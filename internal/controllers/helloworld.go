package controllers

import (
	"fmt"

	"github.com/gin-gonic/gin"
)

func HelloWorld(ctx *gin.Context) {
	fmt.Fprintf(ctx.Writer, "Hello World")
}
