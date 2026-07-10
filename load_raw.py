import os
from pathlib import Path

import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
from dotenv import load_dotenv

load_dotenv()

csv_dir = os.getenv("CSV_DIR")
if not csv_dir:
    raise ValueError("CSV_DIR is not set")
CSV_DIR = Path(csv_dir)


def get_connection():
        account=os.getenv("SNOWFLAKE_ACCOUNT")
        user=os.getenv("SNOWFLAKE_USER")
        private_key_file = os.getenv("SNOWFLAKE_PRIVATE_KEY_PATH")

        if not account:
            raise ValueError("SNOWFLAKE_ACCOUNT must be set")
        if not user:
            raise ValueError("SNOWFLAKE_USER must be set")
        if not private_key_file:
            raise ValueError("SNOWFLAKE_PRIVATE_KEY_PATH must be set")


        return snowflake.connector.connect(
            account=account,
            user=user,
            private_key_file=private_key_file,
            warehouse="elt_wh",
            database="healthcare",
            schema="raw",
    )

def load_csv(connection, csv_path):
    df = pd.read_csv(csv_path, dtype=str)
    table_name = csv_path.stem.upper()
    write_pandas(connection, df, table_name, auto_create_table=True, overwrite=True)
    print(f"{table_name}: {len(df)} rows loaded")

def main():
    connection = get_connection()
    for csv_path in sorted(CSV_DIR.glob("*.csv")):
        load_csv(connection, csv_path)
    connection.close()

if __name__ == "__main__":
    main()