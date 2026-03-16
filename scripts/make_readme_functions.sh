#!/bin/bash

create_graph_version_list () {

    # 本番
    # local config_file="${config_directory}/graph_source.csv"
    # 検証
    local config_file="${config_directory}/graph_source_local.csv"
    local output_file="${tmp_directory}/graph_version.tsv"

    mkdir -p "${tmp_directory}"

    echo -e "graph\tdatabase\tversion" > "${output_file}"

    awk -F',' 'NR>1 {print $1 "|" $2 "|" $3 "|" $4}' "$config_file" | \
    while IFS="|" read -r api version_source database format
    do
        api=$(echo "$api" | tr -d '\r')
        version_source=$(echo "$version_source" | tr -d '\r')
        database=$(echo "$database" | tr -d '\r')
        format=$(echo "$format" | tr -d '\r')

        version="APIで取得"

        if [[ "$format" != "API" && -n "$version_source" && -f "$version_source" ]]; then

            line=$(grep -E "$format" "$version_source" | head -n 1)

            date=$(echo "$line" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" | head -n 1)

            if [ -n "$date" ]; then
                version=$(echo "$date" | sed 's/-/\//g')
            fi
        fi

        echo -e "${api}\t${database}\t${version}" >> "${output_file}"

    done
}

read_version_from_server () {
    local output="${tmp_output_file_path}"
    local config_file="${copy_file_list_path}"

    while IFS=, read -r file_name file_path
    do
        file_name=$(echo "$file_name" | tr -d '\r')
        file_path=$(echo "$file_path" | tr -d '\r')

        if [ "$file_name" = "file_name_with_suffix" ]; then
            continue
        fi

        version="APIで取得"
        datasource="Nanbyo Disease Ontology"

        if [[ -f "$file_path" && ( "$file_name" == *.ttl || "$file_name" == *.rdf ) ]]; then
            line=$(grep -E "versionIRI|versionInfo" "$file_path" | head -n 1)
            date=$(echo "$line" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}" | head -n 1)

            if [ -n "$date" ]; then
                version=$(echo "$date" | sed 's/-/\//g')
            fi
        fi

        echo "${file_name},${datasource},${version}" >> "${output}"

    done < "${config_file}"
}

read_version_from_api () {
    local config_file_path="${config_file_path}"
    local output="${tmp_output_file_path}"
    local graph_version_file="${tmp_directory}/graph_version.tsv"

    while IFS=, read -r file_name api from; do

	# ヘッダー行をスキップ
    	if [ "$file_name" = "output" ]; then
            continue
    	fi

        IFS='|' read -ra sources <<< "$from"

        for src in "${sources[@]}"; do

            row=$(awk -F'\t' -v graph="$src" '$1==graph{print;exit}' "$graph_version_file")

            database=$(echo "$row" | awk -F'\t' '{print $2}')

            version=$(echo "$row" | awk -F'\t' '{print $3}')

            if [ -z "$version" ]; then
                version="APIで取得"
            fi

            echo "${file_name}.txt,${database},${version}" >> "${output}"

        done

    done < "${config_file_path}"
}
