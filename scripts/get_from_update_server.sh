#!/bin/bash
# bash get_from_update_server.sh -c configs/api_list.csv -a

source ./scripts/get_from_api_functions.sh

tmp_directory=tmp
# target_directory="/work/data"
target_directory="/home/s.shimizu/DBCLS/test_data" #
# config_file_path="/work/configs/copy_file_list.csv"
config_file_path="../configs/copy_file_list_local.csv"
date_num=${DATE_NUM}

mkdir -p "${tmp_directory}"

# 全データ取得
while IFS=, read -r file_name_with_suffix file_path; do
    # ヘッダーを省く
    if [ "$file_name_with_suffix" = "file_name_with_suffix" ]; then
        continue
    fi
    # 本番
    # scp -P ${REMOTE_PORT} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST}:${file_path} ${tmp_directory}

    # ローカル検証
    if ! cp "${file_path}" "${tmp_directory}/"; then
        echo "[ERROR] ${file_path} のコピー失敗" >> "${tmp_directory}/error.log"
    else
        qa_check "${tmp_directory}/${file_name_with_suffix}" "nando"
    fi
done < ${config_file_path}


# target directoryに値がないとき、新しくlatestのリンクを作成し、古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
old_file=$(ls "${target_directory}" | grep -v latest | grep -v ${date_num} | sort | tail -n 1)
check_target="${target_directory}/${old_file}"

echo "${check_target}との差分を確認"

target="${target_directory}/${date_num}"
mkdir -p ${target}

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

rm -rf ${tmp_directory}
