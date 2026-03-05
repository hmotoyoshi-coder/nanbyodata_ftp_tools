#!/bin/bash
# bash get_from_api.sh -c configs/api_list.csv -a

path=`pwd`
tmp_directory=tmp
output_directory=data

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

# 特定のデータを指定して取得
if [[ -n "${OPT_FLAG_f}" ]]; then
    file_name=${OPT_VALUE_f}
    api_uri=`duckdb -c "COPY (SELECT api FROM '${config_file_path}' where output == '${file_name}') to '/dev/stdout' (header false);"`
    get_data
fi

# 全データ取得
if [[ -n "${OPT_FLAG_a}" ]]; then
    get_all
fi

# target directoryに値があるとき、target directoryに古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
if [[ -n "${target_directory}" ]]; then
    if [[ "${target_directory}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        target=${target_directory}
        check_target=${target_directory}
        for file in `ls ${tmp_directory}`; do
            cp_file
        done
    else
        echo "[ERROR] target directory name is not date format."
        exit 1
    fi
# target directoryに値がないとき、新しくlatestのリンクを作成し、古いファイルと新しいファイルの差分がない場合新しいファイルを作成する
else
    old_file=`readlink "${output_directory}/latest" | sed 's|./||g'`
    check_target="${output_directory}/${old_file}"
    echo $check_target

    new_date=$(date +"%Y-%m-%d")
    mkdir -p "${output_directory}/${new_date}"
    target="${output_directory}/${new_date}"

    for file in `ls ${tmp_directory}`; do
        cp_file
    done

    (
        cd "${output_directory}"
        ln -sfn "./${new_date}" latest
    )
fi

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