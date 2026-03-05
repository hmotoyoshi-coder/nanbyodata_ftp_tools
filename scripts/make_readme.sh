#!/bin/bash
# bash make_readme.sh

target_directory=data
tmp_directory=tmp
tmp_output_file_path=${tmp_directory}/latest_release_note.csv
config_directory=configs

source ./scripts/make_readme_functions.sh


if [ `ls ${target_directory}/latest_release_note.txt > /dev/null; echo $?` -ne 0 ]; then
    old_releasenote_date=`date -r "${target_directory}/latest_release_note.txt" +%Y%m%d`
    mkdir ${target_directory}/release_notes
    cp "${target_directory}/latest_release_note.txt" "${target_directory}/relese_notes/${old_releasenote_date}.txt"
    rm "${target_directory}/latest_release_note.txt"
fi

mkdir ${tmp_directory}
echo "データ名,バージョン/最終取得日,内容,作成者" >> ${tmp_output_file_path}

# nandoの更新日(サーバーから取得)
# file_nameを抽出 > サフィックスを切り捨て > データ名に変換
files=($(cat ${config_directory}/copy_file_list.csv | awk -F ',' '{print $1}' | awk -F '.' '{print $1}' | sort | uniq | tr '\n' ' '))
read_version_from_server

# APIから取得するデータの更新日
config_file_path="${config_directory}/api_list.csv"
read_version_from_api

# 整形
output_file_path=`echo ${tmp_output_file_path} | sed 's/.csv/.txt/g'`
printf '# Release Note\n\n' > ${output_file_path}
duckdb -markdown -c "SELECT * from read_csv('${tmp_output_file_path}')" >> ${output_file_path}

# latestに移行
cp "tmp/latest_release_note.txt" "${target_directory}/latest_release_note.txt"

echo "done"

rm -rf tmp
