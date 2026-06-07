Welcome to your new dbt project!

### Using the starter project

Try running the following commands:

- dbt run
- dbt test

### Resources:

- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

# Print seeded data

```
..\myenv\Scripts\python.exe -c "import duckdb; con=duckdb.connect('dev.duckdb'); print(con.sql('select * from airlines limit 10').fetchall())"

..\myenv\Scripts\python.exe -c "import duckdb; con=duckdb.connect('dev.duckdb'); print(con.sql('select * from airports limit 10').fetchall())"
```

# Run dbt

```
dbt run --profiles-dir .
```

# Preview

### Staging

1. Staging airports

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_airport') }}" --limit 10
dbt show --profiles-dir . --inline "select count(*) from {{ ref('stg_airport') }}"
```

2. Staging bts airports

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_bts_airport_map') }}" --limit 10
dbt show --profiles-dir . --inline "select count(*) from {{ ref('stg_bts_airport_map') }}"
```

3. Staging airlines

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_airline') }}" --limit 10
dbt show --profiles-dir . --inline "select count(*) from {{ ref('stg_airline') }}"
```

4. Staging flights

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_flight') }}" --limit 10
dbt show --profiles-dir . --inline "select count(*) from {{ ref('stg_flight') }}"
```

5. Staging weather

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_weather') }}" --limit 10
dbt show --profiles-dir . --inline "select count(*) from {{ ref('stg_weather') }}"
```

### Intermediate layer

1. Staging flights

```
dbt show --profiles-dir . --inline "select * from {{ ref('int_flight') }}" --limit 10
dbt show --profiles-dir . --inline "select count(*) from {{ ref('int_flight') }}"
```

2. Weather lookup

```
dbt show --profiles-dir . --inline "select * from {{ ref('int_weather_lookup') }}" --limit 10
dbt show --profiles-dir . --inline "select count(*) from {{ ref('int_weather_lookup') }}"

# Dimensions

1. Dim airline

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_airline') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_airline') }}"

```
2. Dim airport

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_airport') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_airport') }}"

```

3. Dim aircraft

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_aircraft') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_aircraft') }}"

```

4. Dim date

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_date') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_date') }}"

```

5. Dim time

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_time') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_time') }}"

```

6. Dim weather lookup

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_weather_lookup') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_weather_lookup') }}"

```

7. Dim flight status

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_flight_status') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_flight_status') }}"

```

11. Fact flights

```

dbt show --profiles-dir . --inline "select _ from {{ ref('fact_flight') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('fact_flight') }}"

```

# Counts
```

SELECT
(SELECT COUNT(_) FROM main_warehouse.dim_airline) AS total_airlines,
(SELECT COUNT(_) FROM main_warehouse.dim_aircraft) AS total_aircrafts,
(SELECT COUNT(_) FROM main_warehouse.dim_airport) AS total_airports,
(SELECT COUNT(_) FROM main_warehouse.dim_date) AS total_dates,
(SELECT COUNT(_) FROM main_warehouse.dim_time) AS total_times,
(SELECT COUNT(_) FROM main_warehouse.dim_weather_lookup) AS total_weathers,
(SELECT COUNT(\*) FROM main_warehouse.fact_flight) AS total_flights;

```

```
