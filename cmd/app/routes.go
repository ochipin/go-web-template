package main

import (
	"app/internal/routes"
	"app/internal/routes/engine"
	"io"

	"github.com/gin-gonic/gin"
)

// 登録済みのルーティングテーブルの情報を表示する
func runRoutes() {
	// ginのデバッグメッセージは、エンドポイント一覧を表示する際には不要なので/dev/nullに捨てる
	gin.DefaultWriter = io.Discard
	gin.DefaultErrorWriter = io.Discard
	// エンドポイント一覧を表示するために、ルーティングテーブルに登録する
	routes.SetupRoutes(gin.New())
	// ルーティングテーブル情報を表示する
	engine.RoutesTables()
}
