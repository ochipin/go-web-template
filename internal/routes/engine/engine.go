package engine

import (
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"

	"github.com/gin-gonic/gin"
)

// gin.Engine を拡張する
type Engine struct {
	*gin.Engine
}

// 共通のミドルウェアやパスを持つルートをまとめるために使用する.
// 例: 認可ミドルウェアを使うルートを1つにまとめる
func (r *Engine) Group(relativePath string, handlers ...gin.HandlerFunc) *RouterGroup {
	return &RouterGroup{
		r.Engine.Group(relativePath, handlers...),
	}
}

// "GET" メソッドに対するルートを定義する
func (r *Engine) GET(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.Engine, "GET", relativePath, handlers...)
}

// "POST" メソッドに対するルートを定義する
func (r *Engine) POST(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.Engine, "POST", relativePath, handlers...)
}

// "PUT" メソッドに対するルートを定義する
func (r *Engine) PUT(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.Engine, "PUT", relativePath, handlers...)
}

// "PATCH" メソッドに対するルートを定義する
func (r *Engine) PATCH(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.Engine, "PATCH", relativePath, handlers...)
}

// "DELETE" メソッドに対するルートを定義する
func (r *Engine) DELETE(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.Engine, "DELETE", relativePath, handlers...)
}

// "OPTIONS" メソッドに対するルートを定義する
func (r *Engine) OPTIONS(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.Engine, "OPTIONS", relativePath, handlers...)
}

// "HEAD" メソッドに対するルートを定義する
func (r *Engine) HEAD(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.Engine, "HEAD", relativePath, handlers...)
}

// gin.RouterGroupを拡張する
type RouterGroup struct {
	*gin.RouterGroup
}

// 共通のミドルウェアやパスを持つルートをまとめるために使用する.
// 例: 認可ミドルウェアを使うルートを1つにまとめる
func (r *RouterGroup) Group(relativePath string, handlers ...gin.HandlerFunc) *RouterGroup {
	return &RouterGroup{
		r.RouterGroup.Group(relativePath, handlers...),
	}
}

// "GET" メソッドに対するルートを定義する
func (r *RouterGroup) GET(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.RouterGroup, "GET", relativePath, handlers...)
}

// "POST" メソッドに対するルートを定義する
func (r *RouterGroup) POST(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.RouterGroup, "POST", relativePath, handlers...)
}

// "PUT" メソッドに対するルートを定義する
func (r *RouterGroup) PUT(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.RouterGroup, "PUT", relativePath, handlers...)
}

// "PATCH" メソッドに対するルートを定義する
func (r *RouterGroup) PATCH(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.RouterGroup, "PATCH", relativePath, handlers...)
}

// "DELETE" メソッドに対するルートを定義する
func (r *RouterGroup) DELETE(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.RouterGroup, "DELETE", relativePath, handlers...)
}

// "OPTIONS" メソッドに対するルートを定義する
func (r *RouterGroup) OPTIONS(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.RouterGroup, "OPTIONS", relativePath, handlers...)
}

// "HEAD" メソッドに対するルートを定義する
func (r *RouterGroup) HEAD(relativePath string, handlers ...gin.HandlerFunc) {
	registerWithTrace(r.RouterGroup, "HEAD", relativePath, handlers...)
}

// 登録されたルーティングテーブルのメタ情報を管理する
type RouteMeta struct {
	Method  string
	Path    string
	Handler string
	File    string
	Line    int
}

// 登録されたルーティングテーブル情報を保持する
var routeMetaList []RouteMeta

// 関数を登録する
func registerWithTrace(r gin.IRoutes, method, path string, handlers ...gin.HandlerFunc) {
	var funcName string
	var fileName string
	var lineNum int

	for _, handler := range handlers {
		// 関数情報を取得する
		pc := reflect.ValueOf(handler).Pointer()
		fn := runtime.FuncForPC(pc)

		if fn != nil {
			fileName, lineNum = fn.FileLine(pc)
			funcName = fn.Name()
		} else {
			fileName = "unknown"
			lineNum = 0
			funcName = "unknown"
		}
		// 関数情報を登録する
		routeMetaList = append(routeMetaList, RouteMeta{
			Method:  method,
			Path:    path,
			Handler: filepath.Base(funcName),
			File:    filepath.Base(fileName),
			Line:    lineNum,
		})
	}

	switch method {
	case "GET":
		r.GET(path, handlers...)
	case "POST":
		r.POST(path, handlers...)
	case "PUT":
		r.PUT(path, handlers...)
	case "PATCH":
		r.PATCH(path, handlers...)
	case "DELETE":
		r.DELETE(path, handlers...)
	case "OPTIONS":
		r.OPTIONS(path, handlers...)
	case "HEAD":
		r.HEAD(path, handlers...)
	}
}

// `routes` コマンド実行時に呼び出され、ルーティングテーブルの情報を表示する.
func RoutesTables() {
	// エンドポイント一覧を表示する
	fmt.Printf("%-9s%-32s%s\n", "METHOD", "PATH", "ACTION")
	for _, route := range routeMetaList {
		fmt.Printf("%-9s%-32s%s(%s:%d)\n", route.Method, route.Path, route.Handler, route.File, route.Line)
	}
}
