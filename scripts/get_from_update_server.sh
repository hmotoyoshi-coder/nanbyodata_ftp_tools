#!/bin/bash
# bash get_from_update_server.sh -c configs/copy_file_list.csv -a

tmp_directory=tmp
output_directory=../download

mkdir -p $tmp_directory

source ./scripts/get_from_api_functions.sh

# オプション指定がない場合はhelp_messageを返す
if [ $# -eq 0 ]; then
  echo "[ERROR] オプションが必要です"
  help_message
  exit 1
fi

# オプション、引数解析
while getopts ":haf:c:t:" OPT
do
  case $OPT in
    a) OPT_FLAG_a=1;;
    f) OPT_FLAG_f=1;OPT_VALUE_f=$OPTARG ;;
    h) help_message
       exit 0;;
    c) OPT_FLAG_c=1;OPT_VALUE_c=$OPTARG ;;
    # 既存のディレクトリにデータを入れる場合
    t) OPT_FLAG_t=1;OPT_VALUE_t=$OPTARG ;;
	:) echo  "[ERROR] Option argument is undefined."
       exit 1;;
    \?) echo "[ERROR] Undefined options."
        exit 1;;
  esac
done

if [[ -z "${OPT_FLAG_c}"  || (-z "${OPT_FLAG_a}" && -z "${OPT_FLAG_f}" )]]; then
  echo "[ERROR]: オプション -c は必須です。"
  echo "         オプション -a or -f は必須です。"
  echo "Usage: bash $0 -c -a <config_file_path> <option> <argument>"
  exit 1
fi

# getopts分の引数値移動
shift $(($OPTIND - 1))

config_file_path=$OPT_VALUE_c
target_directory=$OPT_VALUE_t

echo "pass"

# 特定のデータを指定して取得
if [[ -n "${OPT_FLAG_f}" ]]; then
    file_name=${OPT_VALUE_f}
    file_path=`duckdb -c "COPY (SELECT file_path FROM '${config_file_path}' where file_name_with_suffix == '${file_name}') to '/dev/stdout' (header false);"`
    # TODO: 修正変更
    # 本番環境
    # scp "case@${file_path}" ${tmp_directory}/

    # ローカル検証
    if ! cp "${file_path}" "${tmp_directory}/"; then
        echo "[ERROR] ${file_path} のコピー失敗" >> "${tmp_directory}/error.log"
    else
        qa_check "${tmp_directory}/${file_name}" "nando"
    fi
fi

# 全データ取得
if [[ -n "${OPT_FLAG_a}" ]]; then
    while IFS=, read -r file_name_with_suffix file_path; do
        # ヘッダーを省く
        if [ "$file_name_with_suffix" = "file_name_with_suffix" ]; then
            continue
        fi
        echo ${file_name_with_suffix}
        # TODO: 修正変更
        # 本番環境
        # scp "case@${file_path}" ${tmp_directory}/
        
        # ローカル検証
        if ! cp "${file_path}" "${tmp_directory}/"; then
            echo "[ERROR] ${file_path} のコピー失敗" >> "${tmp_directory}/error.log"
        else
            qa_check "${tmp_directory}/${file_name_with_suffix}" "nando"
        fi
    done < $config_file_path
fi

# target directoryに値があるとき、target directoryに古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
if [[ -n "${target_directory}" ]]; then
    if [[ "${target_directory}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        target=${target_directory}
        check_target=${target_directory}
        for file in ${tmp_directory}/*; do
            file=$(basename "$file")
            cp_file
        done
    else
        echo "[ERROR] target directory name is not date format."
        exit 1
    fi
# target directoryに値がないとき、新しくlatestのリンクを作成し、古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
else
    if [ -L "${output_directory}/latest" ]; then
        old_file=$(readlink "${output_directory}/latest" | sed 's|./||g')
        check_target="${output_directory}/${old_file}"
    else
        check_target=""
    fi
    echo $check_target

    new_date=$(date +"%Y-%m-%d")
    mkdir -p "${output_directory}/${new_date}"
    target="${output_directory}/${new_date}"

    for file in ${tmp_directory}/*; do
        file=$(basename "$file")
        cp_file
    done
    (
        cd "${output_directory}"
        ln -sfn "./${new_date}" latest
    )
fi

# error.logを日付フォルダへ統合
if [ -f "${tmp_directory}/error.log" ]; then
    cat "${tmp_directory}/error.log" >> "${target}/error.log"
fi

rm -rf ${tmp_directory}
