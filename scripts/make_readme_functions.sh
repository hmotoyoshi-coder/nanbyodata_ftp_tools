read_version_from_server () {
    local files=${files[@]}
    local target_directory=${target_directory}
    local output=${tmp_output_file_path}
    local update_date=''

    for file in ${files[@]}; do

        # headerはスキップ
        if [ "${file}" = "file_name_with_suffix" ]; then
            continue
        fi

        # データソースは同じで拡張子だけが違うファイルから適当に1つ選んで更新日を入れているので、どれくらい精密にするか要検討
        file_name=`ls ${target_directory} | grep ${file} | sed -n 1p`
        update_date=`date -r "${target_directory}/${file_name}" +%Y/%m/%d`
        echo "${file},${update_date},,'ライフサイエンス統合データベースセンター'" >> ${output}
    done
}

read_version_from_api () {
    local config_file_path=${config_file_path}
    local target_directory=${target_directory}
    local output=${tmp_output_file_path}
    local update_date=''

    while IFS=, read -r file_name api version; do

	# ヘッダー行をスキップ
    	if [ "$file_name" = "output" ]; then
            continue
    	fi

        # latestディレクトリを参照
        latest_dir="${target_directory}/latest"

        if [ -f "${latest_dir}/${file_name}.json" ]; then
            update_date=$(date -r "${latest_dir}/${file_name}.json" +%Y/%m/%d)
        elif [ -f "${latest_dir}/${file_name}.txt" ]; then
            update_date=$(date -r "${latest_dir}/${file_name}.txt" +%Y/%m/%d)
        else
            update_date=""
        fi

        echo "${file_name},${update_date},,${version}" >> "${output}"

            # TODO: 間にAPIからバージョン取得する処理が必要
            # TODO: versionをとるAPIじゃなくてソースのURLを受け取る処理が必要？

    done < ${config_file_path}
}
