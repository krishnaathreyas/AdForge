# Status Function

This microservice acts as the fast API endpoint (`GET /status/{jobId}`) that allows the client to poll for the result of a generation job. It retrieves and returns the current job status from the DynamoDB table.
