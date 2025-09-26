import json
import os
import boto3
import uuid
import time

# Initialize AWS clients
dynamodb = boto3.resource("dynamodb")
lambda_client = boto3.client("lambda")

# Get table and function names from environment variables set in template.yaml
JOBS_TABLE_NAME = os.environ.get("JOBS_TABLE_NAME")
WORKER_FUNCTION_NAME = os.environ.get("WORKER_FUNCTION_NAME")


def lambda_handler(event, context):
    """
    Acts as the main API endpoint to start an ad generation job.

    This function is designed to be fast (< 2 seconds). It validates the
    incoming request, creates a new job entry in DynamoDB with a 'PENDING'
    status, and asynchronously invokes the long-running WorkerFunction
    to handle the actual AI pipeline.

    Args:
        event (dict): API Gateway Lambda Proxy Input Format.
                      The request body is expected to contain 'sku' and 'user_context'.
        context (object): Lambda Context runtime methods and attributes.

    Returns:
        dict: An API Gateway Lambda Proxy Output Format object with a 202
              status code and the unique jobId for the client to poll.
    """
    try:
        print("ForgeFunction started...")
        body = json.loads(event.get("body", "{}"))

        # Generate a unique ID for this generation job
        job_id = str(uuid.uuid4())
        print(f"Generated new Job ID: {job_id}")

        # Store the initial job status and request details in DynamoDB
        table = dynamodb.Table(JOBS_TABLE_NAME)
        table.put_item(
            Item={
                "jobId": job_id,
                "status": "PENDING",
                "requestBody": body,
                "createdAt": int(time.time()),
            }
        )
        print(f"Job {job_id} saved to DynamoDB with PENDING status.")

        # Asynchronously invoke the worker Lambda to do the heavy lifting
        # We pass only the jobId as the payload
        lambda_client.invoke(
            FunctionName=WORKER_FUNCTION_NAME,
            InvocationType="Event",  # 'Event' means invoke asynchronously
            Payload=json.dumps({"jobId": job_id}),
        )
        print(f"Successfully invoked worker function for Job ID: {job_id}")

        # Instantly return the jobId to the client
        return {
            "statusCode": 202,  # 202 Accepted: The request is accepted for processing
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"jobId": job_id, "status": "PROCESSING"}),
        }

    except Exception as e:
        print(f"A critical error occurred: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal Server Error"}),
        }
    