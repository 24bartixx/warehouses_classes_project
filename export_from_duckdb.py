import os
import duckdb

# --- CONFIGURATION ---
DB_PATH = "flights_db/dev.duckdb"
TARGET_SCHEMA = "main_warehouse"
OUTPUT_DIR = "./extracted_csv"

def export_warehouse_to_csv():
    # Ensure the output directory exists
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"Created output directory: {OUTPUT_DIR}")

    print(f"Connecting to DuckDB database at: {DB_PATH}")
    
    # We connect in read_only=True mode. 
    # This prevents write-locks if you run this script concurrently with dbt tasks.
    conn = duckdb.connect(database=DB_PATH, read_only=True)

    try:
        # Step 1: Query the information schema to find all tables and views in the 'warehouse' schema
        metadata_query = f"""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = '{TARGET_SCHEMA}'
        """
        tables = conn.execute(metadata_query).fetchall()

        if not tables:
            print(f"No tables or views found in schema: '{TARGET_SCHEMA}'")
            return

        print(f"Found {len(tables)} tables/views in schema '{TARGET_SCHEMA}'. Starting export...")

        # Step 2: Loop through every table and dump it directly into a CSV file
        for row in tables:
            table_name = row[0]
            output_file_path = os.path.join(OUTPUT_DIR, f"{table_name}.csv")
            
            print(f"Exporting: {TARGET_SCHEMA}.{table_name} -> {output_file_path}")
            
            # Using DuckDB's native high-performance COPY engine
            export_query = f"""
                COPY {TARGET_SCHEMA}.{table_name} 
                TO '{output_file_path}' 
                (FORMAT CSV, HEADER TRUE);
            """
            conn.execute(export_query)
            
        print("\n[SUCCESS] All warehouse models have been successfully exported to CSV!")

    except Exception as e:
        print(f"[ERROR] An unexpected error occurred: {e}")
        
    finally:
        # Always close the connection
        conn.close()
        print("Database connection closed.")

if __name__ == "__main__":
    export_warehouse_to_csv()