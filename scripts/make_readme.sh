#!/bin/bash
# Generate RELEASE.txt from downloaded data

target_directory=../download
tmp_directory=tmp
tmp_output_file_path=${tmp_directory}/release_note.csv
config_directory=configs

source ./scripts/make_readme_functions.sh

# tmp作成
mkdir -p "${tmp_directory}"

echo "file,datasource,update" > "${tmp_output_file_path}"

# server系
read_version_from_server

# graph version
create_graph_version_list

# API系
config_file_path="${config_directory}/api_list.csv"
read_version_from_api

# markdown生成
output_file_path="${tmp_output_file_path%.csv}.txt"

printf '# Release Note\n\n' > "${output_file_path}"

duckdb -markdown -c \
"SELECT * FROM read_csv('${tmp_output_file_path}', header=true)" \
>> "${output_file_path}"

# RELEASE.txt配置
latest_dir=$(readlink "${target_directory}/latest")
latest_path="${target_directory}/${latest_dir#./}"
release_target="${latest_path}/RELEASE.txt"

cp "${output_file_path}" "${release_target}"

# error.log統合
if [ -f "${tmp_directory}/error.log" ]; then
    cat "${tmp_directory}/error.log" >> "${latest_path}/error.log"
fi

rm -rf "${tmp_directory}"

echo "Release note created: ${release_target}"
echo "make_readme.sh completed."