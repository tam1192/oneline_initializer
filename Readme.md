# oneline_initializer.sh

シェルの変数宣言を1行に集約します。
(分割代入などの処理を減らし、高速化を目指します)

## 特徴

- 簡易的なシェルスクリプト  
  透明性が非常に高いシェルスクリプトを採用します
- 大体のunixで動作する互換性  
  `/bin/sh`互換であれば動作します

## 依存関係

- cat  
  ファイルの読み込みに使用
- sed  
  構文解析に使用

## 使用方法

`Usage: oli <var> [-i|-e|-c] [-s sep] ... [--] [file...]`

### ベストプラクティス

このようなファイルの場合...

```
PATH='/home/x/bin'
PATH='/home/x/.local/java/bin'
LOCAL_VAR='test'
```

`cat file | ./oli.sh PATH -eis :`

```
export PATH='/home/x/bin:/home/x/.local/java/bin:$PATH'
LOCAL_VAR='test'
```
