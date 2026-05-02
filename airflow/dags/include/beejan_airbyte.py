import requests
import json
from airflow.sdk import Variable
from airflow.providers.slack.hooks.slack_webhook import SlackWebhookHook
import time

CLIENT_ID = Variable.get("BEEJANRIDE_CLIENT_ID")
CLIENT_SECRET = Variable.get("BEEJANRIDE_CLIENT_SECRET")
CONNECTION_ID = Variable.get("BEEJANRIDE_CONNECTION_ID")
AIRBYTE_API = "htps://api.airbyte.com"
SLACK_CONNECTION_ID = "slack_webhook"

def send_slack_message(message):
    hook = SlackWebhookHook(slack_webhook_conn_id=SLACK_CONNECTION_ID)
    hook.send(text=message)

def slack_failure_callback(context):
    message = (
        "Airflow task failed! \n"
        f"DAG:{context['dag'].dag_id}\n"
        f"Task:{context['task_instance'].task_id}\n"
        f"Error:{context['exception']}"
    )
    send_slack_message(message)

def slack_success_callback(context):
    message = (
        "BeejanRide Pipeline Succeeded!\n"
        f"DAG:{context['dag'].dag_id}\n"
        f"Execution Time:{context['execution_date']}\n"
        "Airbyte sync, dbt run and dbt tests all Green"
    )
    send_slack_message(message)
#Get token
def trigger_airbyte_sync(**context):

    # Get Bearer Token
    token_response = requests.post(
        "https://api.airbyte.com/v1/applications/token",
        json={
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "grant-type": "client_credentials"
        }
    )
    token = token_response.json()["access_token"]
    print("Token retrieved successfully")

    # Trigger Sync
    sync_response = requests.post(
        "https://api.airbyte.com/v1/jobs",
        json={
            "connectionId": CONNECTION_ID,
            "jobType": "sync"
        },
        headers={
            "authorization": f"Bearer {token}",
            "content-type": "application/json",
            "accept": "application/json"
        }
    )

    job_id = sync_response.json()["jobId"]
    print(f"Sync triggered. Job ID: {job_id}")

    # Push to XCom
    context["ti"].xcom_push(key="job_id", value=job_id)
    context["ti"].xcom_push(key="token", value=token)


#Poll for sync completion
def wait_for_sync(**context):

    job_id = context["ti"].xcom_pull(task_ids="trigger_airbyte_sync", key="job_id")
    token = context["ti"].xcom_pull(task_ids="trigger_airbyte_sync", key="token")

    while True:
        status_response = requests.get(
            f"https://api.airbyte.com/v1/jobs/{job_id}",
            headers={
                "authorization": f"Bearer {token}",
                "accept": "application/json"
            }
        )

        status = status_response.json()["status"]
        print(f"Sync status: {status}")

        if status == "succeeded":
            print("Sync completed successfully!")
            # push status to XCom for branch operator
            context["ti"].xcom_push(key="sync_status", value="succeeded")
            break
        elif status in ["failed", "cancelled"]:
            # push status to XCom for branch operator
            context["ti"].xcom_push(key="sync_status", value="failed")
            raise Exception(f"Airbyte sync failed with status: {status}")

        time.sleep(30)


#Branch
def check_sync_status(**context):

    sync_status = context["ti"].xcom_pull(
        task_ids="wait_for_airbyte_sync",
        key="sync_status"
    )

    if sync_status == "succeeded":
        print("Sync succeeded — proceeding to dbt")
        return "staging.run_staging"       
    else:
        print("Sync failed — skipping dbt")
        return "sync_failed"    
