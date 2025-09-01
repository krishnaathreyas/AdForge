# Worker Function

This is the heavy-lifting engine of the platform. It is a long-running, asynchronous function that executes the entire multi-stage generative AI pipeline: generating the creative blueprint, creating video clips, synthesizing a voiceover, and assembling the final video ad. It updates the job status in DynamoDB upon completion or failure.
