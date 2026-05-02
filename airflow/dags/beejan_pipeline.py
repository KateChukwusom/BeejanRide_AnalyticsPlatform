from airflow.sdk import Variable, DAG, TaskGroup
from airflow.providers.standard.operators.python import PythonOperator, BranchPythonOperator
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.task.trigger_rule import TriggerRule
import pendulum
from datetime import datetime
from include.beejan_airbyte import slack_failure_callback
from include.beejan_airbyte import trigger_airbyte_sync
from include.beejan_airbyte import wait_for_sync
from include.beejan_airbyte import check_sync_status
from include.beejan_airbyte import slack_success_callback

# DBT_INFO 
DBT_VENV = "/usr/local/airflow/dbt-venv/bin/dbt"
DBT_FLAGS = (
    "--profiles-dir /usr/local/airflow "
    "--profile beejanride "
    "--project-dir /opt/airflow/dags/dbt/BeejanRide_AnalyticsPlatform/dbt-beejanride "
)

default_args = {
    "owner": "BeejanRide",
    "retries": 2,                                    
    "retry_delay": pendulum.duration(minutes=2),     
    "max_retry_delay": pendulum.duration(minutes=10), 
    "on_failure_callback": slack_failure_callback,   
}

with DAG(
    dag_id="Beejanride_pipeline",
    description="Orchestrates the BeejanRide ELT pipeline — Airbyte ingestion, dbt transformation and testing",
    schedule="@daily",
    start_date=datetime(2026,1,1),
    default_args=default_args,
    catchup=True,
    tags=["airbyte", "dbt", "bigquery"],
    on_failure_callback=slack_failure_callback
) as dag:

    # Trigger Airbyte Sync
    trigger_sync = PythonOperator(
        task_id="trigger_airbyte_sync",
        python_callable=trigger_airbyte_sync,
    )

    # Wait for Sync to Complete
    wait_sync = PythonOperator(
        task_id="wait_for_airbyte_sync",
        python_callable=wait_for_sync,
    )

    # Branch Based on Sync Status
    branch = BranchPythonOperator(
        task_id="check_sync_status",
        python_callable=check_sync_status,
        trigger_rule=TriggerRule.ALL_DONE,
    )

    with TaskGroup(group_id="staging") as tg_staging:
        staging = BashOperator(
            task_id="run_staging",
            bash_command=f"{DBT_VENV} run {DBT_FLAGS} --select models/staging --full-refresh"
        )
        test_staging = BashOperator(
            task_id="test_staging",
            bash_command=f"{DBT_VENV} test {DBT_FLAGS} --select models/staging"
        )
        staging >> test_staging

    # Intermediate
    with TaskGroup(group_id="intermediate") as tg_intermediate:
        intermediate = BashOperator(
            task_id="run_intermediate",
            bash_command=f"{DBT_VENV} run {DBT_FLAGS} --select models/intermediate --full-refresh"
        )
        test_intermediate = BashOperator(
            task_id="test_intermediate",
            bash_command=f"{DBT_VENV} test {DBT_FLAGS} --select models/intermediate"
        )
        intermediate >> test_intermediate

    # Marts models
    with TaskGroup(group_id="marts") as tg_marts:
        run_marts = BashOperator(
            task_id="run_marts",
            bash_command=f"{DBT_VENV} run {DBT_FLAGS} --select models/marts --full-refresh",
        )
        test_marts = BashOperator(
            task_id="test_marts",
            bash_command=f"{DBT_VENV} test {DBT_FLAGS} --select models/marts",
        )
        run_marts >> test_marts

    # Sync Failed
    sync_failed = EmptyOperator(
        task_id="sync_failed",
        trigger_rule=TriggerRule.ONE_FAILED,
    )

    # Pipeline End (success alert)
    pipeline_end = EmptyOperator(
        task_id="pipeline_end",
        trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS,
        on_success_callback=slack_success_callback,
    )

    # Pipeline Order
    trigger_sync >> wait_sync >> branch
    branch >> tg_staging >> tg_intermediate >> tg_marts >> pipeline_end
    branch >> sync_failed >> pipeline_end