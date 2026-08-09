#!/bin/sh

awk_begin='BEGIN {
    FS = "=";
'
awk_sep_rules=""

# -------------------------------------------------------------------
# 引数解析: oli <var> [-i|-e|-c] [-s sep] ... [--] [file...]
# -------------------------------------------------------------------
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help)
		echo "Usage: oli <var> [-i|-e|-c] [-s sep] ... [--] [file...]"
		exit 0
		;;
	--)
		shift
		break
		;;
	-*)
		# 引数の先頭がいきなりハイフンの場合は解析終了（ファイル名指定へ）
		break
		;;
	*)
		# 1. まず変数名を取得
		var="$1"
		shift

		# デフォルト値のリセット
		is_export=0
		is_inherit=0
		is_combine=0
		sep_val=" "
		[ "$var" = "PATH" ] && sep_val=":" # PATHのデフォルト

		# 2. この変数に続くハイフン付きオプションをすべて消費するループ
		while [ $# -gt 0 ]; do
			case "$1" in
			--)
				shift
				break 2 # -- が来たら完全終了
				;;
			-*)
				opts="${1#-}"
				shift

				# 1文字ずつ取り出して処理 (例: -cs -> 'c', 's')
				while [ -n "$opts" ]; do
					opt="${opts%"${opts#?}"}"
					opts="${opts#?}"

					case "$opt" in
					i) is_inherit=1 ;;
					e) is_export=1 ;;
					c) is_combine=1 ;;
					s)
						if [ -n "$opts" ]; then
							sep_val="$opts"
							opts=""
						else
							sep_val="$1"
							shift
						fi
						;;
					*)
						echo "エラー: 不明なオプション -$opt" >&2
						exit 1
						;;
					esac
				done
				;;
			*)
				# 次の変数名または引数が来たのでオプション消費ループを抜ける
				break
				;;
			esac
		done

		# 3. 組み合わせ結果から prefix / suffix を確定
		prefix_val="${var}='"
		suffix_val="'"

		# PATH はデフォルトで export 付与
		[ "$var" = "PATH" ] && is_export=1

		# -i (継承) と -c (合成) の判定
		if [ $is_inherit -eq 1 ]; then
			prefix_val="${var}='\$${var}${sep_val}"
		elif [ $is_combine -eq 1 ]; then
			suffix_val="${sep_val}\$${var}'"
		fi

		# export の付与
		if [ $is_export -eq 1 ]; then
			prefix_val="export ${prefix_val}"
		fi

		# 4. その場で AWK 用コードに直書き追加
		awk_begin="${awk_begin}    prefix[\"${var}\"] = \"${prefix_val}\";
    suffix[\"${var}\"] = \"${suffix_val}\";
"

		# 区切り文字がスペース以外の場合のみオーバーライド規則を追加（改行を直接入れる）
		if [ "$sep_val" != " " ]; then
			awk_sep_rules="${awk_sep_rules}\$1 == \"${var}\" { sep = \"${sep_val}\" }
"
		fi
		;;
	esac
done

awk_begin="${awk_begin}}
"

# -------------------------------------------------------------------
# MAIN & END ブロックの組み立て
# -------------------------------------------------------------------
skip_comments='/^\s*#/'
skip_blank='/^\s*$/'

awk_main_1="
# コメント・空行はスキップ
${skip_comments} || ${skip_blank} { next }

# 毎行のデフォルト区切り文字
{ sep = \" \" }
"

awk_main_2="
{
    vn = \$1;
    vv = \$0; sub(/^[^=]*=/, \"\", vv);
    values[vn] = (values[vn] == \"\") ? vv : values[vn] sep vv;
}
"

awk_end='
END {
    for (k in values) {
        if (values[k] != "") {
            p = (k in prefix) ? prefix[k] : k "=\x27";
            s = (k in suffix) ? suffix[k] : "\x27";

            print p values[k] s;
        }
    }
}
'

# -------------------------------------------------------------------
# 5. ガッチャンコして実行
# -------------------------------------------------------------------
awk_script="${awk_begin}${awk_main_1}${awk_sep_rules}${awk_main_2}${awk_end}"

awk "$awk_script" "$@"
