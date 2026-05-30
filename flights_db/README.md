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
