# nanbyodata_ftp_tools

## 概要
* NanbyoDataのFTPサーバーにバージョニングしたデータを配置するスクリプト
* NanbyoDataのsparqlのAPIをたたいて、データを取得する

## 前提

* Docker / Docker Compose

## 使用方法

### 1. 環境変数の設定

* 一部ツールはコンテナ内からホストの設定を経由してsshする必要があるため、ssh-agentの設定が必要
* ホストで以下のコマンドを実行し、対象の値を`SSH_AUTH_SOCK`に追加する

    ```sh
    ssh-add <秘密鍵のパス>
    ssh-agent
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

### 2. configの設定

1. templateをconfigs配下にコピー

    ```bash
    cp templates/* configs/
    ```

2. csvに設定値を追加

* api_list.csv
    * `output`
        * 拡張子なし出力ファイル名
    * `api`
        * 取得に使用するAPI
    * `version`
        * バージョン

        ```
        output,api,version
        genes,https://localhost/api/get_genes,'APIで取得'
        ```

* copy_file_list.csv
    * `file_name_with_suffix`
        * 拡張子ありファイル名
    * `file_path`
        * コピー元のファイルパス

    ```
    file_name_with_suffix,file_path
    nando.rdf,temp/nando/nando.rdf
    ```

* graph_source.csv

    * `graph`
        * NanbyoDataのAPIのグラフ名
    * `version_source`
        * NanbyoDataのグラフのソースとなるデータのパス
    * `format`
        * バージョン記載箇所のフォーマット(正規表現)

    ```
    graph,version_source,format
    https://localhost/example,temp/example/example.owl,<owl:versionIRI rdf:resource="http://example/releases/([0-9]{4}-[0-9]{2}-[0-9]{2})/example.owl"/>
    ```

### 3. ツールの実行

* APIからデータを取得する際

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_api.sh
    ```

* 更新サーバーからデータを取得する際

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_update_server.sh
    ```

## 注意
* 出力先のディレクトリにエラーログがはかれる