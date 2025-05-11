package main

import (
	"fmt"
	"os"
)

// エントリポイント
func main() {
	err := execSubCommand()
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}

// 指定されたサブコマンドを実行する
func execSubCommand() error {
	args := os.Args[1:]
	if len(args) == 0 {
		// サブコマンドが渡されていない場合はエラーとして扱う
		runHelp()
		return fmt.Errorf("%s: no subcommand provided. see '%s help' for usage.", projectName, projectName)
	}

	var subCmd = args[0]
	args = args[1:]
	switch subCmd {
	// Webサーバを起動する
	case "server":
		if len(args) != 0 {
			return fmt.Errorf("%s server: no arguments are required.", projectName)
		}
		runServer()
	// 登録済みのルーティングテーブルの情報を表示する
	case "routes":
		if len(args) != 0 {
			return fmt.Errorf("%s routes: no arguments are required.", projectName)
		}
		runRoutes()
	// ヘルプメッセージを表示する
	case "help":
		if len(args) != 0 {
			return fmt.Errorf("%s help: no arguments are required.", projectName)
		}
		runHelp()
	// バージョン情報を表示する
	case "version":
		// オプションを解析する
		parseMap, err := DefOptions{{
			Name:  OptionVersion,
			Alias: []string{"-l", "--long"},
		}}.Parse(args)
		if err != nil {
			return err
		}
		runVersion(parseMap)
	default:
		return fmt.Errorf("%s %s: unknown command", projectName, subCmd)
	}
	return nil
}
