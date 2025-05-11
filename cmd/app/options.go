package main

import "fmt"

// オプションを定義する
type DefOption struct {
	Name      string   // オプション名 (--long の場合なら、 "long" など)
	Alias     []string // 実際の引数 ("-l", "--long"など)
	HasValue  bool     // 値が必要か否か
	Required  bool     // オプションが必須か否か
	Requires  []string // 指定されたら同時に必要なオプション (-v など)
	Conflicts []string // 同時指定禁止のオプション (-p など)
}

// 複数オプションの定義情報を管理する
type DefOptions []*DefOption

// オプションのパースを実施し、オプション情報を返却する
func (defOptions DefOptions) Parse(args []string) (map[string]string, error) {
	// オプションを解析する
	parseMap, err := defOptions.parseOptions(args)
	if err != nil {
		return nil, err
	}

	// 解析後、オプションの依存関係を確認する
	err = defOptions.dependOptions(parseMap)
	if err != nil {
		return nil, err
	}

	return parseMap, nil
}

// オプションのパース
func (defOptions DefOptions) parseOptions(args []string) (map[string]string, error) {
	var aliases = make(map[string]*DefOption)
	// aliasから論理名を逆引きするマップを作成
	for _, defOption := range defOptions {
		for _, v := range defOption.Alias {
			// -l: "-l,--long" のようなキー:値で管理する
			aliases[v] = defOption
		}
	}

	var optMap = make(map[string]string)
	// 引数で渡されてきたオプションが、サブコマンドのオプションとして使用できるか確認する
	for i := 0; i < len(args); i++ {
		arg := args[i]
		// 使用できないオプションが含まれている場合はエラーとして扱う
		if _, ok := aliases[arg]; !ok {
			return nil, fmt.Errorf("'%s' unknowon option", arg)
		}
		// 同じオプションが指定されていないかチェックする
		keyName := aliases[arg].Name
		if _, ok := optMap[keyName]; ok {
			return nil, fmt.Errorf("option '%s' specified multiple times", keyName)
		}
		// 値が必須の場合
		if aliases[arg].HasValue {
			if i+1 >= len(args) {
				return nil, fmt.Errorf("option '%s' requires a value", keyName)
			}
			optMap[keyName] = args[i+1]
			i++
		} else {
			optMap[keyName] = ""
		}
	}

	// パース後に、必須入力用のオプションが指定されているか確認する
	for _, alias := range aliases {
		if alias.Required {
			if _, ok := optMap[alias.Name]; !ok {
				return nil, fmt.Errorf("option '%s' required", alias.Name)
			}
		}
	}

	return optMap, nil
}

// オプションの依存関係を確認する
func (defOptions DefOptions) dependOptions(parseMap map[string]string) error {
	// 逆引き用のDefOptionsを作成する
	var defMap = make(map[string]*DefOption)
	for _, defOption := range defOptions {
		defMap[defOption.Name] = defOption
	}

	// "option名: optionデータ" となっている、オプション情報の依存関係をチェックする
	for option := range parseMap {
		// option名に該当する、DefOptionsの情報を取得する
		defOption := defMap[option]
		// optionの依存関係にある、必須オプションが指定されているか確認する
		for _, req := range defOption.Requires {
			if _, ok := parseMap[req]; !ok {
				return fmt.Errorf("option '%s' requires '%s'", option, req)
			}
		}
		//　optionの依存関係にある、オプションが指定されていないか確認する
		for _, conflict := range defOption.Conflicts {
			if _, ok := parseMap[conflict]; ok {
				return fmt.Errorf("option '%s' cannot be used with '%s'", option, conflict)
			}
		}
	}
	return nil
}
