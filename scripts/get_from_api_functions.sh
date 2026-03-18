get_data () {
    local api=$api_uri
    local output=$file_name
    local tmp_file="${tmp_directory}/${output}"

    echo "${file_name} data file make to ${tmp_file} ...."

    # APIに接続可能かどうかを確認
    if [ "$(curl -o /dev/null -w '%{http_code}' -s "${api}")" -ne 200 ]; then
        echo "[ERROR] can not access to ${api}" >> "${tmp_directory}/error.log"
        return 1
    fi

    echo "download ${output} data from ${api}"
    curl -L -sS "${api}" > "${tmp_file}.json"

    # HTMLエラー検出
    if grep -q "<html" "${tmp_file}.json"; then
        echo "[ERROR] API returned HTML (server error) ${api}" >> "${tmp_directory}/error.log"
        mkdir -p "${tmp_directory}/error_data"
        mv "${tmp_file}.json" "${tmp_directory}/error_data/"
        return 1
    fi

    # 取得したJSONがテーブルとして認識可能かどうかを確認
    # 計算量を軽くするため、一行のみ検証
    if ! duckdb -c "SELECT * FROM read_json_auto('${tmp_file}.json') LIMIT 1" >/dev/null 2>&1; then
        echo "[ERROR] data which download from ${api} can not change to table." >> "${tmp_directory}/error.log"
        mkdir -p "${tmp_directory}/error_data"
        mv "${tmp_file}.json" "${tmp_directory}/error_data/"
        return 1
    fi

    echo "download data change to text file"
    duckdb -c "
        COPY(
            SELECT * FROM read_json_auto('${tmp_file}.json', format='array')
        ) to '${tmp_file}.txt' (HEADER, DELIMITER '\t');
    "

    qa_check "${tmp_file}.txt" "api"

    return 0
}

get_all () {
    declare -A api_map
    local config_file_path=${config_file_path}

    while IFS=, read -r output_file api_url graph; do
        # 空行スキップ
        if [ -z "$output_file" ]; then
            continue
        fi
        # ヘッダーを省く
        if [ "$output_file" = "output_file" ]; then
            continue
        fi
        api_map["$api_url"]="$output_file"
    done < "${config_file_path}"

    for api_url in "${!api_map[@]}"; do
        local api_uri=${api_url}
        local file_name="${api_map[$api_url]}"

        # データを取得できなかった場合、次のデータの取得に移行する
        get_data
    done
}

cp_file () {
    local target=${target}
    local check_target=${check_target}

    # 前のディレクトリに更新しようとしているファイルが含まれているか確認
    if [ -f "${check_target}/${file}" ]; then
        local hash=$(sha256sum "${tmp_directory}/${file}" | awk '{print $1}')
        # すでにftpにファイルが置いてある→hashが一致する場合は上書きしない
        if ! echo "${hash}  ${check_target}/${file}" | sha256sum -c --status; then
            cp "${tmp_directory}/${file}" "${target}/${file}"
            echo "update ${target}/${file}"
        else
            cp -p "${check_target}/${file}" "${target}/${file}"
            echo "${target}/${file} is not change from ${check_target}/${file}"
        fi
    else
        cp "${tmp_directory}/${file}" "${target}/${file}"
        echo "update ${target}/${file}"
    fi
}

qa_check () {
    local file_path="$1"
    local data_type="$2"
    local log_file="${tmp_directory}/error.log"

    # ファイル存在チェック
    if [ ! -f "$file_path" ]; then
        echo "[QA_ERROR] file not found: $file_path" >> "$log_file"
        return 1
    fi

    # 空ファイルチェック
    if [ ! -s "$file_path" ]; then
        echo "[QA_ERROR] file is empty: $file_path" >> "$log_file"
        return 1
    fi

    # apiデータの場合のみレコード数確認
    if [ "$data_type" = "api" ]; then
        local base="${file_path%.txt}"
        local json_file="${base}.json"

        if [ -f "$json_file" ]; then
            json_count=$(duckdb -csv -c "SELECT COUNT(*) FROM read_json_auto('${json_file}', format='array');" 2>/dev/null | tail -n 1)
            tsv_count=$(($(wc -l < "$file_path") - 1))

            if [ "$json_count" != "$tsv_count" ]; then
                echo "[QA_ERROR] record mismatch: $file_path json=${json_count} tsv=${tsv_count}" >> "$log_file"
            fi
        fi
    fi
}
