#!/bin/bash

DATA_DIR="$(dirname $0)/../data"

duckdb -c "COPY (
    SELECT replace(City, chr(10), ''), replace(string_split(Jan, chr(10))[1], '−' , '-') as Temp
    FROM read_csv([
        '$DATA_DIR/wikipedia-data/List_of_cities_by_average_temperature_1.csv',
        '$DATA_DIR/wikipedia-data/List_of_cities_by_average_temperature_2.csv',
        '$DATA_DIR/wikipedia-data/List_of_cities_by_average_temperature_3.csv',
        '$DATA_DIR/wikipedia-data/List_of_cities_by_average_temperature_4.csv',
        '$DATA_DIR/wikipedia-data/List_of_cities_by_average_temperature_5.csv',
        '$DATA_DIR/wikipedia-data/List_of_cities_by_average_temperature_6.csv'
    ])
)
 TO '$DATA_DIR/cities.csv' (DELIMITER ',', HEADER false);"

