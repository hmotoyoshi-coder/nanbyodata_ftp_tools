#!/bin/bash
# bash get_from_api.sh -c configs/api_list.csv -a

source ./scripts/get_from_api_functions.sh

tmp_directory=tmp
target_directory="/work/data"
config_file_path="/work/configs/api_list.csv"
date_num=${DATE_NUM}

mkdir -p $tmp_directory

# 全データの取得
get_all

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
    cd "${output_directory}"
    ln -sfn "./${new_date}" latest
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