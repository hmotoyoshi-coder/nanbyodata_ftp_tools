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
    ssh-add <path_to_private_key>
    ssh-agent
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
    REMOTE_PORT=

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
        * `output`: Output filename (without extension).
        * `api`: The API endpoint used for retrieval.
        * `version`: The version identifier.

        ```csv
        output,api,version
        genes,https://localhost/api/get_genes,'Fetched via API'
        ```

    * **copy_file_list.csv**
        * `file_name_with_suffix`: Filename including extension.
        * `file_path`: Source file path for copying.

        ```csv
        file_name_with_suffix,file_path
        nando.rdf,temp/nando/nando.rdf
        ```

    * **graph_source.csv**
        * `graph`: NanbyoData API graph name.
        * `version_source`: Path to the source data for the graph.
        * `format`: Regex pattern to extract the version string.

        ```csv
        graph,version_source,format
        https://localhost/example,temp/example/example.owl,<owl:versionIRI rdf:resource="http://example/releases/([0-9]{4}-[0-9]{2}-[0-9]{2})/example.owl"/>
        ```

### 3. Running the Tools

* **To fetch data from the API:**
    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_api.sh
    ```

* **To fetch data from the update server:**
    ```bash
    docker compose run --rm -it dlfile_cp scripts/get_from_update_server.sh
    ```

## Notes
* **Error Logs:** If an error occurs, logs will be generated within the output destination directory.