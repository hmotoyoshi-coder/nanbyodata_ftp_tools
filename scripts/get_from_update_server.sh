#!/bin/bash
# bash get_from_update_server.sh -c configs/api_list.csv -a

source ./scripts/get_from_api_functions.sh

tmp_directory=tmp
target_directory="/work/data"
config_file_path="/work/configs/copy_file_list_local.csv"
date_num=${DATE_NUM}

mkdir -p $tmp_directory

# 全データ取得
while IFS=, read -r file_name_with_suffix file_path; do
    # ヘッダーを省く
    if [ ${file_name_with_suffix} == 'file_name_with_suffix' ]; then
        continue
    fi
    # 開発用
    # cp ${file_path} ${tmp_directory}
    scp -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_DOMAIN}:${file_path} ${tmp_directory}
    if [ $? -ne 0 ]; then
        echo "[ERROR] ${file_path} のコピー失敗"
    fi
done < ${config_file_path}


# target directoryに値がないとき、新しくlatestのリンクを作成し、古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
old_file=`ls --time=ctime "${target_directory}" | grep -v latest | grep -v ${date_num} | sort | tail -n 1`
check_target="${target_directory}/${old_file}"

echo "${check_target}との差分を確認"

target="${target_directory}/${date_num}"
mkdir -p ${target}

for file in `ls ${tmp_directory}`; do
    cp_file
done
(
    cd "${target_directory}"
    ln -sfn "./${date_num}" latest
)

# # hashチェック
# for file in `ls ${path}/tmp`; do

#     if [ `ls ${output_directory}/ | grep -q ${file}; echo $?` -eq 1 ]; then
#         echo "${file}はコピーされていません"
#         continue
#     fi

#     hash=`shasum -a 256 ${path}/tmp/${file} | awk '{print $1}'`

#     if [ `echo "${hash} *${output_directory}/${file}" | shasum -a 256 -c -s; echo $?` -eq 1 ]; then
#         echo "${file}は正しくコピーされませんでした"
#         continue
#     fi
# done

rm -rf ${tmp_directory}
