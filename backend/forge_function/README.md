# Forge Function

This microservice acts as the fast, asynchronous API endpoint (`POST /forge`) to start an ad generation job. It validates the request, creates a job ID, saves the initial state to DynamoDB, and invokes the long-running Worker Function.
