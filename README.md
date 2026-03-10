# nanbyodata_ftp_tools

## 使用方法

* 一部ツールはコンテナ内からホストの設定を経由してsshする必要があるため、ssh-agentの設定が必要
* ホストで以下のコマンドを実行し、対象の値を`SSH_AUTH_SOCK`に追加する

    ```sh
    eval "$(ssh-agent -s)"
    ssh-add <秘密鍵のパス>
    ```

* その他以下の設定値を`.env`に追加

    ```config
    # 設定ファイル
    API_LIST
    COPY_FILE_LIST

    # コピー先のファイル
    TARGET_DIRECTORY

    # 接続先のサーバーの設定
    REMOTE_HOST
    REMOTE_USER
    REMOTE_PORT

    # 上述
    SSH_AUTH_SOCK
    ```

* configの設定
    * 設定例
        * api_list.csv
            * nanbyodataのAPIから取得するデータ一覧を定義

            ```csv
            output,api,source
            japan_curated_gene,https://dev-nanbyodata.dbcls.jp/sparqlist/api/test_get_japan_curated_gene_list,
            riken_brc_cell,https://dev-nanbyodata.dbcls.jp/sparqlist/api/test_get_riken_brc_cell_list,
            ```

        * copy_file_list.csv
            * nando.ttlなど更新環境サーバーから取得するデータ一覧を定義

            ```csv
            file_name_with_suffix,file_path
            nando.rdf,/opt/services/case/data/nanbyodata_updater/data/NANDO/latest/nando.rdf
            nando.ttl,/opt/services/case/data/nanbyodata_updater/data/NANDO/latest/nando.ttl
            ```

        * graph_source.csv
            * データ管理者が管理
            * APIで取得する場合のグラフのバージョンを取得する際に必要
            * グラフ名、グラフのバージョンのソース、バージョン記載行のフォーマット(正規表現でバージョンを取得)

            ```csv
            graph,version_source,format
            https://nanbyodata.jp/rdf/ontology/hp,/opt/services/case/virtuoso/data/nanbyodata/ontologies/hp/latest/hp.owl,<owl:versionIRI rdf:resource="http://purl.obolibrary.org/obo/hp/releases/([0-9]{4}-[0-9]{2}-[0-9]{2})/hp.owl"/>
            https://nanbyodata.jp/rdf/medgen,/opt/services/case/virtuoso/data/medgen_rdf/latest/metadata.yaml,issued: ([0-9]{4}-[0-9]{2}-[0-9]{2})
            ```

* APIからデータを取得する際

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_api.sh
    ```

* 更新サーバーからデータを取得する際

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_update_server.sh
    ```