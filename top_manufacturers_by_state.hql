DROP TABLE IF EXISTS mapreduce_output;
DROP TABLE IF EXISTS datasource4;
DROP TABLE IF EXISTS state_manufacturer_avg_price;
DROP TABLE IF EXISTS top_3_manufacturers_by_state;
DROP TABLE IF EXISTS results;

-- Create mapreduce_output table
CREATE EXTERNAL TABLE mapreduce_output (
    geo_id INT,
    manufacturer STRING,
    car_count INT,
    total_price DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '${input_dir1}';

-- Create datasource4 table
CREATE EXTERNAL TABLE datasource4 (
    id INT,
    region STRING,
    region_url STRING,
    county STRING,
    state STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '^'
STORED AS TEXTFILE
LOCATION '${input_dir4}';

CREATE TABLE results (
        state STRING,
        manufacturer STRING,
        avg_price DOUBLE
)
ROW FORMAT SERDE
'org.apache.hadoop.hive.serde2.JsonSerDe'
STORED AS TEXTFILE
LOCATION '${output_dir6}';

-- Create state_manufacturer_avg_price table
WITH state_manufacturer_avg_price AS (
        SELECT
        d.state,
        m.manufacturer,
        SUM(m.total_price) / SUM(m.car_count) AS avg_price
        FROM mapreduce_output m
        JOIN datasource4 d ON m.geo_id = d.id
        GROUP BY
        d.state,
        m.manufacturer
),

-- Create final table for top 3 manufacturers per state
top_3_manufacturers_by_state AS (
        SELECT
        state,
        manufacturer,
        avg_price
        FROM (
        SELECT
                state,
                manufacturer,
                avg_price,
                ROW_NUMBER() OVER (PARTITION BY state ORDER BY avg_price DESC) AS rank
        FROM state_manufacturer_avg_price
        ) ranked
        WHERE rank <= 3
)

INSERT OVERWRITE TABLE results
SELECT * FROM top_3_manufacturers_by_state;
