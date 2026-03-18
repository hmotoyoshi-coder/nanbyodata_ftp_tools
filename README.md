# nanbyodata_ftp_tools

## Overview
* **Data Versioning & Deployment:** A set of scripts to place versioned data onto the NanbyoData FTP server.
* **API Integration:** Fetches data by calling NanbyoData SPARQL APIs.

## Prerequisites
* **Docker** / **Docker Compose**
* **ssh-agent**

## Usage

### 1. Environment Setup

#### SSH Agent Configuration
Since some tools require SSH access from within the container via host settings, you must configure `ssh-agent`. Run the following commands on your **host machine**:

    ```sh
    eval "$(ssh-agent -s)"
    ssh-add <path_to_private_key>
    ```

#### .env Configuration
Create a .env file in the root directory and define the following variables:

    ```config
    # Configuration Files
    API_LIST=
    COPY_FILE_LIST=

    # Destination Directory
    TARGET_DIRECTORY=

    # Remote Server Settings
    REMOTE_HOST=
    REMOTE_USER=
    REMOTE_USER_GROUP=
    REMOTE_PORT=
    SFTP_PW=

    UID=
    GID=

    # Update date
    DATE_NUM=
    ```

### 2. Configuration Files

1.  **Initialize Configs:** Copy the templates to the `configs/` directory.
    ```bash
    cp templates/* configs/
    ```

2.  **Edit CSV Settings:**

    * **api_list.csv**
        * `output_file`: Output filename (without extension).
        * `api_url`: The API endpoint used for retrieval.
        * `graph`: Reference graph.

        ```csv
        output_file,api_url,graph
        genes,http://localhost/api/get_genes,http://localhost/genes
        ```

    * **file_list.csv**
        * `output_file`: Filename including extension.
        * `file_path`: Source file path for copying.
        * `graph`: Reference graph.

        ```csv
        output_file,file_path,graph
        nando.rdf,temp/nando/nando.rdf,http://localhost/nando
        ```

    * **graph_source.csv**
        * `graph`: NanbyoData API graph name.
        * `version_source`: Path to the source data for the graph.
        * `datasource`: Data source for the graph.
        * `version_format`: Where version written on.

        ```csv
        graph,version_source,datasource,version_format
        https://localhost/example,temp/example/example.owl,Example DB,owl:versionIRI
        ```

### 3. Build the image

```bash
docker compose build dlfile_cp --build-arg UID=${UID} --build-arg GID=${GID} --build-arg REMOTE_USER=${REMOTE_USER} --build-arg REMOTE_USER_GROUP=${REMOTE_USER_GROUP}
```

### 4. Running the Tools

* **To fetch data from the API:**

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_api.sh
    ```

* **To fetch data from the update server:**

    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_update_server.sh
    ```

* **To create release memo:**

    ```bash
    docker compose run --rm lfile_cp scripts/make_readme.sh
    ```

## Notes
* **Error Logs:** If an error occurs, logs will be generated within the output destination directory.