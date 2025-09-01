import json
import os
import boto3
from decimal import Decimal


# Custom JSON encoder to handle DynamoDB's Decimal type
class DecimalEncoder(json.JSONEncoder):
    """
    Custom JSON encoder to handle the Decimal type returned by DynamoDB,
    which is not serializable by the default json library.
    """

    def default(self, obj):
        if isinstance(obj, Decimal):
            # Convert Decimal to int if it's a whole number, otherwise to float
            if obj % 1 == 0:
                return int(obj)
            else:
                return float(obj)
        # Let the base class default method raise the TypeError
        return super(DecimalEncoder, self).default(obj)


# Initialize AWS clients
dynamodb = boto3.resource("dynamodb")
JOBS_TABLE_NAME = os.environ.get("JOBS_TABLE_NAME")


def lambda_handler(event, context):
    """
    Retrieves the status and result of a specific ad generation job from DynamoDB.

    This function is called by the client in a polling loop. It fetches the
    job item using the 'jobId' provided in the URL path.

    Args:
        event (dict): API Gateway Lambda Proxy Input Format.
                      'pathParameters' is expected to contain the 'jobId'.
        context (object): Lambda Context runtime methods and attributes.

    Returns:
        dict: An API Gateway Lambda Proxy Output Format object containing the
              full job item from DynamoDB (e.g., status, finalVideoUrl).
    """
    try:
        print("StatusFunction started...")
        job_id = event["pathParameters"]["jobId"]
        print(f"Fetching status for Job ID: {job_id}")

        table = dynamodb.Table(JOBS_TABLE_NAME)
        response = table.get_item(Key={"jobId": job_id})
        item = response.get("Item", {})

        if not item:
            return {
                "statusCode": 404,
                "body": json.dumps({"message": "Job not found."}),
            }

        # Return the full job item using our custom encoder
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            # Use cls=DecimalEncoder to handle the conversion
            "body": json.dumps(item, cls=DecimalEncoder),
        }

    except Exception as e:
        print(f"A critical error occurred: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal Server Error"}),
        }
