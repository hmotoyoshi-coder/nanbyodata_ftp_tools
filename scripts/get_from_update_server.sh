#!/bin/bash
# bash get_from_update_server.sh

source ./scripts/get_from_api_functions.sh

tmp_directory=tmp
# 本番
# target_directory="/work/data"
# 検証
target_directory="../test_data"
# 本番
# config_file_path="/work/configs/file_list.csv"
# 検証
config_file_path="../configs/file_list.csv"
date_num=${DATE_NUM:-$(date +%Y-%m-%d)}

mkdir -p "${tmp_directory}"

# 全データ取得
while IFS=, read -r output_file file_path graph; do
    # ヘッダーを省く
    if [ "$output_file" = "output_file" ]; then
        continue
    fi
    # 本番
    # if ! scp -P "${REMOTE_PORT}" -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}:${file_path}" "${tmp_directory}/${output_file}"; then
    #     echo "[ERROR] ${file_path} のコピー失敗" >> "${tmp_directory}/error.log"
    # else
    #     qa_check "${tmp_directory}/${output_file}" "file"
    # fi

    # ローカル検証
    if ! cp "${file_path}" "${tmp_directory}/"; then
        echo "[ERROR] ${file_path} のコピー失敗" >> "${tmp_directory}/error.log"
    else
        qa_check "${tmp_directory}/${output_file}" "file"
    fi
done < "${config_file_path}"


# target directoryに値がないとき、新しくlatestのリンクを作成し、古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
old_file=$(ls "${target_directory}" | grep -v latest | grep -v "${date_num}" | sort | tail -n 1)
check_target="${target_directory}/${old_file}"

echo "${check_target}との差分を確認"

target="${target_directory}/${date_num}"
mkdir -p "${target}"

for file in ${tmp_directory}/*; do
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
