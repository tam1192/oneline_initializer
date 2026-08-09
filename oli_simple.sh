#!/bin/sh

exports="PATH"

# exportを追加する
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

# 該当変数の継承を排除する
remove_include() {
	# -e オプションの引数を構築
	sed_cmd="sed"

	# 引数がない場合は終了
	if [ $# -eq 0 ]; then
		cat
		return 0
	fi

	for var in "$@"; do
		# 行頭のスペース（任意）＋「変数名=」の形にマッチさせ、"export 変数名=" に置換
		sed_cmd="$sed_cmd -e 's/^$var=\"\$$var./$var=\"/'"
	done

	# 組み立てたコマンドを実行
	eval "$sed_cmd"
}

# 変数代入の行 (KEY=VALUE) を抽出する
find_assignments() {
	# シェル文法に準拠: イコールの左側に空白を許可しない (例: KEY=VALUE, KEY="V V" はOK / K = V はNG)
	grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*='
}

# 行頭および行末のインデント（空白・タブ）をトリムする
trim() {
	sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}


# 引数 <var> <sep> ...
merge_vars() {
	# awk_macros
	# key valueに分離するコード
	kv_sep="{key = \$1;\$1 = \"\";val = \$0;sub(/^ /, \"\", val);}"
	next_key='current_key=key; printf("%s=\"$%s",key,key);'
	line_last='printf("\"\n");'
    add_rule='' # 追加ルール

    while [ $# -ge 2 ]; do
        k=$1
        s=$2
        shift 2

        add_rule="
            $add_rule
            key == \"$k\" {
                printf(\"$s%s\", val);
                next;
            }
        "
    done

	awk -F '=' "
        $kv_sep
        NR == 1 { $next_key }
        current_key != key {
            $line_last
            $next_key
        }
        $add_rule
        {
            printf(\" %s\", val);
            next;
        }
        END { $line_last }
    "
}

find_assignments | trim | sort | uniq | merge_vars "PATH" ":" | remove_include "b" | add_export $exports
