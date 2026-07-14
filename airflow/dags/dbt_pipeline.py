from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

default_args = {
    "owner": "junayd",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="dbt_healthcare_pipeline",
    description="Builds and tests the healthcare warehouse",
    default_args=default_args,
    start_date=datetime(2026, 1, 1),
    schedule="0 6 * * *",
    catchup=False,
    tags=["dbt", "snowflake"],
) as dag:

    load_raw = BashOperator(
        task_id="load_raw",
        bash_command="pip install snowflake-connector-python pandas python-dotenv && cd /opt/ingestion && python load_raw.py",
    )

    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command="cd /opt/dbt && dbt deps",
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command="cd /opt/dbt && dbt build --target dev",
    )

    load_raw >> dbt_deps >> dbt_build