# Samsung Ad-Forge #
--- 
### Submission for the Samsung PRISM Generative AI Hackathon 2025 - Theme 2: Content Creation ##

#### Team Name: Temperature=0.0 ###

#### Demo Video: https://www.youtube.com ###

---

## 1. The Vision 
Samsung Ad-Forge is a B2B generative AI platform that empowers Samsung's vast network of third-party retailers to create professional, hyper-local, and brand-safe video advertisements in seconds. Our platform transforms every retail promoter into a local marketing expert, closing the critical "last-mile" marketing gap and driving sales where they matter most.

## 2. Key Features
* **AI Creative Director:** Leverages a powerful LLM to analyze a retailer's simple business goal and generate a complete, multi-scene creative blueprint for a 15-second ad.
* **On-the-Fly Video Generation:** Utilizes a state-of-the-art text-to-video model to generate unique, cinematic visuals for the ad's core narrative.
* **Brand-Safe Hybrid Model:** Intelligently fuses AI-generated scenes with curated, brand-perfect product shots to ensure 100% brand compliance.
* **Dynamic AI Voiceover & Music:** Generates a unique voiceover and a fitting background music track for every ad, creating a fully autonomous creative pipeline.
* **Professional Asynchronous Architecture:** Built on a robust, scalable, serverless backend that handles long-running generative tasks efficiently, providing a seamless user experience.

## 3. System Architecture

![Ad-Forge System Architecture](/frontend/assets/architecture.png)

Our system is built on a modern, asynchronous, serverless architecture using AWS. The workflow is orchestrated by three distinct microservices:

* A **`/forge** endpoint to rapidly accept and queue new ad generation jobs.

* A long-running worker function that executes the entire multi-stage generative AI pipeline.

* A **`/status endpoint** for the client to poll for the final, completed video URL.

## 4. Tech Stack
* **Frontend:** Flutter
* **Backend:** AWS Lambda (Python), API Gateway, DynamoDB, S3
* **AI Services:**
  * **LLM (Blueprint):** OpenRouter (Google Gemini Flash)
  * **Text-to-Video:** Hugging Face Inference Client (Fal.ai provider)
  * **Text-to-Speech:** ElevenLabs
  * **Video Assembly:** Shotstack
  
## 5. How to Run the Project

#### Prerequisites
* **AWS CLI & SAM CLI**
* **Docker**
* **Flutter SDK**
* **An AWS account with configured credentials**
* **API keys for the services listed above, stored in AWS Systems Manager Parameter Store.**

#### Backend Deployment
```Bash
# Navigate to the backend directory
cd backend/
# Build the serverless application
sam build
# Deploy the stack to your AWS account
sam deploy --guided
```

#### Frontend Setup
``` Bash
# Navigate to the frontend directory
cd flutter-app/
# Install dependencies
flutter pub get
# Run the app
flutter run
```

