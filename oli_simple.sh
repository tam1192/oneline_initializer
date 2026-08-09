#!/bin/sh

exports="PATH"

# stdin: text
# $1..: vars
# stdout: text
add_export() {
	# -e オプションの引数を構築
	sed_cmd="sed"

	# 引数がない場合は全てを対象とする
	if [ $# -eq 0 ]; then
		sed_cmd="$sed_cmd -e 's/^/export /'"
	else
		for var in "$@"; do
			# 行頭のスペース（任意）＋「変数名=」の形にマッチさせ、"export 変数名=" に置換
			sed_cmd="$sed_cmd -e 's/^$var=/export $var=/'"
		done
	fi

	# 組み立てたコマンドを実行
	eval "$sed_cmd"
}

# execute
# $1: exports
execute() {
	sort | uniq | add_export "$1"
}

execute $exports
