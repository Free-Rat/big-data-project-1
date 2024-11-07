DROP TABLE IF EXISTS mapreduce_output;
DROP TABLE IF EXISTS datasource4;
DROP TABLE IF EXISTS state_manufacturer_avg_price;
DROP TABLE IF EXISTS top_3_manufacturers_by_state;

-- Create mapreduce_output table
CREATE TABLE mapreduce_output (
    geo_id INT,
    manufacturer STRING,
    car_count INT,
    total_price DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';

-- Create datasource4 table
CREATE TABLE datasource4 (
    id INT,
    region STRING,
    region_url STRING,
    county STRING,
    state STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '^';

-- Load data into mapreduce_output table
LOAD DATA INPATH '/user/lawicki02/output/part-*' INTO TABLE mapreduce_output;

-- Load data into datasource4 table
LOAD DATA INPATH '/user/lawicki02/input/datasource4/*' INTO TABLE datasource4;

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

-- Export result to HDFS in JSON format
INSERT OVERWRITE DIRECTORY 'hdfs://user/lawicki02'
STORED AS JSONFILE
SELECT * FROM top_3_manufacturers_by_state;
