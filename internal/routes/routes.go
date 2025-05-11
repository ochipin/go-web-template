package routes

import (
	"app/internal/controllers"
	"app/internal/routes/engine"

	"github.com/gin-gonic/gin"
)

// エンドポイントを登録する
func SetupRoutes(ginEngine *gin.Engine) {
	// gin.Engine を拡張する
	r := &engine.Engine{Engine: ginEngine}
	// Hello World を出すだけのルーティングテーブルを追加する
	r.GET("/", controllers.HelloWorld)
}
