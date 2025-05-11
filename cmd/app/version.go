package main

import (
	"fmt"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

// オプションの名前
const OptionVersion = "-l,--long"

// -ldflags から渡されてくる値。詳細はMakefileを参照すること。
var (
	tagName     = "v0.0"    // git tag. バージョン番号に使用する。
	branchName  = "none"    // git branch
	commitID    = "none"    // コミットハッシュ値
	commitDate  = "unknown" // コミット日付
	commitCount = "0"       // 総コミット回数
	treeState   = "unknown" // 未コミットか否かをclean / dirtyで表示する
	buildDate   = "unknown" // ビルド日付
	copyright   = "unknown" // コピーライト
	goVersion   = "unknown" // コンパイラバージョン
	buildUser   = "unknown" // ビルドユーザ
	platform    = "unknown" // プラットフォーム (linux/amd64など)
	projectName = "unknown" // プロジェクト名 (.envに記載)
	osName      = "unknown" // os-release情報
	osVersion   = "0"       // os-release情報
)

// 短いバージョン情報を表示する
func version() {
	fmt.Printf("%s version %s %s", projectName, tagName, platform)
}

// 長いバージョン情報を表示する
func longVersion() {
	fmt.Printf("%s %s-%s:%s (%s: %s) [%s] - built by %s\n", projectName, tagName, commitID, commitCount, branchName, commitDate, treeState, buildDate)
	fmt.Printf("Build: %s %s, %s %s, %s\n", goVersion, platform, cases.Title(language.Und).String(osName), osVersion, buildUser)
	fmt.Printf("License: %s\n", copyright)
}

// バージョン情報を表示する
func runVersion(option map[string]string) {
	if _, ok := option[OptionVersion]; ok {
		longVersion()
	} else {
		version()
	}
}
