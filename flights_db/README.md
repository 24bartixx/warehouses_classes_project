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

7. Dim airport

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_airport') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_airport') }}"

```

8. Dim aircraft

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_aircraft') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_aircraft') }}"

```

8. Dim date

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_date') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_date') }}"

```

8. Dim time

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_time') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_time') }}"

```

9. Dim weather lookup

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_weather_lookup') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_weather_lookup') }}"

```

10. Dim flight status

```

dbt show --profiles-dir . --inline "select _ from {{ ref('dim_flight_status') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('dim_flight_status') }}"

```

11. Fact flights

```

dbt show --profiles-dir . --inline "select _ from {{ ref('fact_flight') }}" --limit 10
dbt show --profiles-dir . --inline "select count(_) from {{ ref('fact_flight') }}"

```

```
