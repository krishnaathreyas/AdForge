# Samsung Ad-Forge: Backend Service

This directory contains the complete source code and infrastructure-as-code definitions for the Samsung Ad-Forge serverless backend.

**Team Name:** `[Your Team Name]`

---
## 1. Architecture Overview

The backend is built on a professional, asynchronous, and highly scalable serverless architecture using AWS. This design correctly handles long-running generative AI tasks (which can take several minutes) without timing out, providing a robust and seamless experience for the client application.

The workflow is orchestrated by three distinct microservices (AWS Lambda functions):
1.  A **`/forge` endpoint** to rapidly accept and queue new ad generation jobs.
2.  A long-running **worker function** that executes the entire multi-stage generative AI pipeline in the background.
3.  A **`/status` endpoint** for the client to poll for the final, completed video URL.

This architecture demonstrates a mature understanding of building real-world, event-driven systems.

## 2. Directory Structure

* **`/forge_function`**: Contains the code for the fast, asynchronous API endpoint that starts a job.
* **`/worker_function`**: Contains the heavy-lifting engine of the platform, including all logic for the multi-stage generative AI pipeline.
* **`/status_function`**: Contains the code for the fast API endpoint that allows the client to poll for a job's result.
* **`template.yaml`**: The master AWS SAM template that defines all our infrastructure: the three Lambda functions, the API Gateway, the DynamoDB table, and all necessary IAM permissions.

## 3. Tech Stack

* **Infrastructure:** AWS Serverless Application Model (SAM)
* **Compute:** AWS Lambda (Python 3.11)
* **API:** AWS API Gateway
* **Database:** AWS DynamoDB (for job tracking)
* **Storage:** AWS S3 (for storing generated and curated assets)
* **Secrets Management:** AWS Systems Manager Parameter Store
* **AI Services:**
    * **Creative Direction (LLM):** OpenRouter (using Google Gemini Flash)
    * **Voiceover Generation:** ElevenLabs
    * **Video Assembly:** Shotstack
    * **(Optional) Video Scene Generation:** Hugging Face client via Fal.ai or Replicate

## 4. Deployment

### Prerequisites
* AWS CLI & SAM CLI
* Docker
* An AWS account with configured credentials.
* All required API keys (OpenRouter, Hugging Face/Replicate, ElevenLabs, Shotstack) must be stored in AWS Systems Manager Parameter Store with the correct names as defined in `template.yaml`.

### Instructions
To deploy the entire backend stack to your AWS account, run the following commands from this `backend` directory:

```bash
# Build the application dependencies and source code for all three functions
sam build

# Deploy the stack to the cloud, following the guided prompts
sam deploy --guided

