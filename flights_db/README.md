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

1. Staging airports

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_airports') }}" --limit 10
```

2. Staging airlines

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_airlines') }}" --limit 10
```

3. Staging flights

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_flights') }}" --limit 10
```

4. Staging wather

```
dbt show --profiles-dir . --inline "select * from {{ ref('stg_weather') }}" --limit 10
```

5. Dim airline

```
dbt show --profiles-dir . --inline "select * from {{ ref('dim_airline') }}" --limit 10
```

6. Dim airport

```
dbt show --profiles-dir . --inline "select * from {{ ref('dim_airport') }}" --limit 10
```

7. Dim aircraft

```
dbt show --profiles-dir . --inline "select * from {{ ref('dim_aircraft') }}" --limit 10
```

8. Dim date

```
dbt show --profiles-dir . --inline "select * from {{ ref('dim_date') }}" --limit 10
```

8. Dim time

```
dbt show --profiles-dir . --inline "select * from {{ ref('dim_time') }}" --limit 10
```

9. Dim weather lookup

```
dbt show --profiles-dir . --inline "select * from {{ ref('dim_weather_lookup') }}" --limit 10
```

11. Fact flights

```
dbt show --profiles-dir . --inline "select * from {{ ref('dim_weather_lookup') }}" --limit 10
```
