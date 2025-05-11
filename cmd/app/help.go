package main

import "fmt"

// ヘルプメッセージを出力する
func runHelp() {
	fmt.Println("This is a tool for launching a web application.")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println()
	fmt.Printf("    %s <command> [arguments]\n", projectName)
	fmt.Println()
	fmt.Println("The commands are:")
	fmt.Println()
	fmt.Println("    server    It launches the web application.")
	fmt.Println("              Please check the configuration file at `config/config.yaml`.")
	fmt.Println("    routes    Displays information about the registered routing table.")
	fmt.Println("    help      This shows the help message")
	fmt.Println("    version   Displays version information.")
	fmt.Println("              Use the `-l` or `--long` option to show detailed information.")
	fmt.Println()
}
