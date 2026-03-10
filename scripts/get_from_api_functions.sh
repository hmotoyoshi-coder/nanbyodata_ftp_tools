help_message () {
    echo "Usage:"
    echo "  bash $0 -c <config_file_path> <option> <argument>"
    echo ""
    echo "  -h, help"
    echo "  -a, csvで定義された全データを作成"
    echo "  -f, 指定したデータファイルのみ作成"
    echo "  -c, 必須. apiと出力ファイル名を定義したcsvのパスを指定"
    echo "  -t, -t or -o の指定必須. 日付指定で出力先ディレクトリを指定"
}

create_latest_dir () {
    # 作業するディレクトリ
    local target_dir=${output_directory}
    # YYYYMMDD形式の日付を取得
    current_date=$(date +"%Y-%m-%d")
    # 新しいディレクトリを作成
    mkdir -p "$target_dir/$current_date"
    # 最新のシンボリックリンクを削除してから新しいリンクを作成
    (
        cd "$target_dir"
        ln -sfn "./$current_date" latest
    )
    echo "Directory $target_dir/$current_date created and latest symlink updated."
}

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
    curl -sS "${api}" > "${tmp_file}.json"

    # 取得したJSONがテーブルとして認識可能かどうかを確認
    # 計算量を軽くするため、一行のみ検証
    if ! duckdb -c "COPY(SELECT * FROM read_json('${tmp_file}.json') LIMIT 1) TO '/dev/null'" >/dev/null 2>&1; then
        echo "[ERROR] data which download from ${api} can not change to table." >> "${tmp_directory}/error.log"
        mkdir -p "${tmp_directory}/error_data"
        mv "${tmp_file}.json" "${tmp_directory}/error_data/"
        return 1
    fi

    echo "download data change to text file"
    duckdb -c "
        COPY(
            SELECT * FROM read_json('${tmp_file}.json')
        ) to '${tmp_file}.txt' (HEADER, DELIMITER '\t');
    "
    return 0
}

get_all () {
    declare -A api_map
    local config_file_path=${config_file_path}
    local tmp_directory=${tmp_directory}

    while IFS=, read -r output api version; do
        # ヘッダーを省く
        if [ "$output" = "output" ]; then
            continue
        fi
        api_map["$api"]="$output"
    done < $config_file_path

    for api in ${!api_map[@]}; do
        local api_uri=${api}
        local file_name=`echo ${api_map[${api}]} | sed 's/[[:space:]]*$//'`
        # local tmp_file="${tmp_directory}/${output}"     # 未使用?

        # データを取得できなかった場合、次のデータの取得に移行する
        get_data
    done
}

cp_file () {
    local target=${target}
    local check_target=${check_target}

    # 前のディレクトリに更新しようとしているファイルが含まれているか確認
    if [ -f "${check_target}/${file}" ]; then
        local hash=`sha256sum ${tmp_directory}/${file} | awk '{print $1}'`
        # すでにftpにファイルが置いてある→hashが一致する場合は上書きしない
        if ! echo "${hash}  ${check_target}/${file}" | sha256sum -c --status; then
            cp ${tmp_directory}/${file} ${target}/${file}
            echo "update ${target}/${file}"
        else
            cp -p ${check_target}/${file} ${target}/${file}
            echo "${target}/${file} is not change from ${check_target}/${file}"
        fi
    else
        cp ${tmp_directory}/${file} ${target}/${file}
        echo "update ${target}/${file}"
    fi
}

# file_check () {
#     if [ `ls ${target}/ | grep -q ${file}; echo $?` -eq 1 ]; then
#         echo "${file}はコピーされていません"
#         continue
#     fi

#     hash=`shasum -a 256 ${path}/tmp/${file} | awk '{print $1}'`

#     if [ `echo "${hash} *${target}/${file}" | shasum -a 256 -c -s; echo $?` -eq 1 ]; then
#         echo "${file}は正しくコピーされませんでした"
#         continue
#     fi
# }