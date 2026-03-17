#!/bin/bash
# bash make_readme.sh

# 本番
# target_directory=data
# 検証
target_directory=../test_data

tmp_directory=tmp
tmp_output_file_path=${tmp_directory}/release_note.csv

# 本番
# config_directory=configs
# 検証
config_directory=../configs

source ./scripts/make_readme_functions.sh
# 本番
# copy_file_list_path="${config_directory}/file_list.csv"
# 検証
copy_file_list_path="${config_directory}/file_list.csv"

mkdir -p "${tmp_directory}"
echo "file,datasource,update" > "${tmp_output_file_path}"

create_graph_version_list

# nandoの更新日(サーバーから取得)
read_version_from_server

# APIから取得するデータの更新日
config_file_path="${config_directory}/api_list.csv"
read_version_from_api

# 整形
output_file_path="${tmp_output_file_path%.csv}.txt"
printf '# Release Note\n\n' > "${output_file_path}"
duckdb -markdown -c "SELECT * FROM read_csv('${tmp_output_file_path}', header=true)" >> "${output_file_path}"

# latestに移行
latest_dir=$(readlink "${target_directory}/latest")
latest_path="${target_directory}/${latest_dir#./}"
release_target="${latest_path}/RELEASE.txt"

cp "${output_file_path}" "${release_target}"

echo "done"

rm -rf "${tmp_directory}"