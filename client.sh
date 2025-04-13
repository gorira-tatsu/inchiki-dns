#!/bin/bash
# このスクリプトは、署名付き JSON データ（data, signature）を入力として、
# 署名検証が成功した場合に hosts 情報を /etc/hosts に反映します。

set -e

# 使い方の確認
if [ $# -ne 1 ]; then
  echo "Usage: $0 <signature_json_file>"
  exit 1
fi

JSON_FILE="$1"
DECRYPT_KEY="/Users/tatsujin/code/inchiki-dns/testkey"   # RSA の秘密鍵ファイル（復号用）

# 必要なコマンドのチェック
for cmd in jq openssl base64; do
  command -v $cmd >/dev/null 2>&1 || { echo "$cmd is required but not installed. Exiting." >&2; exit 1; }
done

# JSON ファイルから data と signature の項目を抽出
DATA=$(jq -r '.data' "$JSON_FILE")
SIGNATURE=$(jq -r '.signature' "$JSON_FILE")

# 一時ファイルの作成
SIGNATURE_BIN=$(mktemp)
DECRYPTED_DIGEST=$(mktemp)
COMPUTED_DIGEST=$(mktemp)
TEMP_HOSTS=$(mktemp)

# 署名部分（base64）をデコードしてバイナリ化
echo "$SIGNATURE" | base64 -d > "$SIGNATURE_BIN"

# RSA OAEP により署名を復号（RSA 署名とみなす※注意：通常は秘密鍵で署名、公開鍵で検証しますが、
# ここでは提供されたコードと同様に、公開鍵で暗号化して秘密鍵で復号している前提です）
openssl pkeyutl -decrypt -inkey "$DECRYPT_KEY" -pkeyopt rsa_padding_mode:oaep -in "$SIGNATURE_BIN" -out "$DECRYPTED_DIGEST"

# data の SHA256 ダイジェストをバイナリ形式で計算
printf "%s" "$DATA" | openssl dgst -sha256 -binary -out "$COMPUTED_DIGEST"

# ダイジェストの比較
if cmp -s "$DECRYPTED_DIGEST" "$COMPUTED_DIGEST"; then
    echo "署名検証に成功しました。"
else
    echo "署名検証に失敗しました。" >&2
    rm "$SIGNATURE_BIN" "$DECRYPTED_DIGEST" "$COMPUTED_DIGEST" "$TEMP_HOSTS"
    exit 1
fi

# data は JSON 文字列としてエンコードされた hosts 情報となっているので、これをパースして
# /etc/hosts に書き込むためのエントリを生成する。
# 例として、下記の形式で hosts ファイルに追記します：
#   <ip> <hostname1> <hostname2> ...
echo "$DATA" | jq -c '.[]' | while read -r entry; do
    ip=$(echo "$entry" | jq -r '.ip')
    hostnames=$(echo "$entry" | jq -r '.hosts | join(" ")')
    echo "$ip $hostnames" >> "$TEMP_HOSTS"
done

# hosts ファイルのバックアップ（必要に応じて）
echo "現在の /etc/hosts を /etc/hosts.bak にバックアップします。"
# sudo cp /etc/hosts /etc/hosts.bak

# /etc/hosts に新たなエントリを追記（必要に応じて、既存エントリの置換等の処理に変更してください）
echo "署名付きの hosts エントリを /etc/hosts に追記します。"
sudo bash -c "cat '$TEMP_HOSTS' >> /Users/tatsujin/code/inchiki-dns/host"

echo "hosts ファイルの更新が完了しました。"

# 一時ファイルの削除
# rm "$SIGNATURE_BIN" "$DECRYPTED_DIGEST" "$COMPUTED_DIGEST" "$TEMP_HOSTS"