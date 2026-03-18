#!/bin/bash
# bash get_from_api.sh

source ./scripts/get_from_api_functions.sh

tmp_directory=tmp
# 本番
target_directory="/work/data"
config_file_path="/work/configs/api_list.csv"
# 検証
# target_directory="../test_data" 
# config_file_path="../configs/api_list.csv"
date_num=${DATE_NUM:-$(date +%Y-%m-%d)}

mkdir -p "${tmp_directory}"

# 全データの取得
get_all

# target directoryに値がないとき、新しくlatestのリンクを作成し、古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
old_file=$(ls "${target_directory}" 2>/dev/null | grep -v latest | grep -v "${date_num}" | sort | tail -n 1)
check_target="${target_directory}/${old_file}"

echo "${check_target}との差分を確認"

target="${target_directory}/${date_num}"
mkdir -p "${target}"

for file in "${tmp_directory}"/*; do
    [ -f "$file" ] || continue
    file=$(basename "$file")
    cp_file
done
(
    cd "${target_directory}"
    ln -sfn "./${date_num}" latest
)

# error.log統合
if [ -f "${tmp_directory}/error.log" ]; then
    cat "${tmp_directory}/error.log" >> "${target}/error.log"
fi

rm -rf "${tmp_directory}"
