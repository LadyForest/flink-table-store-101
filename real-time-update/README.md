# Real-time update Demo

## Get Started
- Start service
    ```bash
    docker-compose up -d
    ```
    The started container will import the lineitem.tbl with default scale factor (1) into `tpch_s1`.`lineitem`. 
    Use `docker logs -f ${container-id}` to track the import progress.

- Preview data
    ```bash
    docker exec -it ${container-id} bash
    ```
    This command will let you enter into the container. From within
    ```bash
    mysql -umysqluser -pmysqlpw
    ```
    execute
    ```sql
    USE tpch_s1;
    SHOW tables;
    SELECT * FROM lineitem LIMIT 10;
    ```

- Generate updates
    - upsert
        ```bash
        docker exec -i ${container-id} /bin/bash -c "export STAGE=update && export UPDATE_TYPE=upsert && export FILE_NAME=lineitem.tbl.u1 && transaction-commit.sh
        ```
    - delete
        ```bash
        docker exec -i ${container-id} /bin/bash -c "export STAGE=update && export UPDATE_TYPE=delete && export FILE_NAME=delete.1 && transaction-commit.sh
        ```    
    This will affect 10% rows of `lineitem`

- Stop and cleanup
    ```bash
    docker-compose down && docker rmi ${image} && docker volume prune
    ```