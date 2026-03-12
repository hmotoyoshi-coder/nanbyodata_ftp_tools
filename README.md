# nanbyodata_ftp_tools

## 使用方法

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

* APIからデータを取得する際

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_api.sh
    ```

* 更新サーバーからデータを取得する際

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_update_server.sh
    ```