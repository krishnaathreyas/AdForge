import json
import os
import boto3
import requests
import time
import uuid
from huggingface_hub import InferenceClient
from threading import Thread
from decimal import Decimal

# Initialize AWS clients
s3 = boto3.client("s3")
ssm = boto3.client("ssm")
dynamodb = boto3.resource("dynamodb")


def get_secret(param_name):
    """
    Retrieves a secret API key securely from AWS Systems Manager Parameter Store.

    Args:
        param_name (str): The name of the parameter to retrieve.

    Returns:
        str: The decrypted secret value.
    """
    try:
        response = ssm.get_parameter(Name=param_name, WithDecryption=True)
        return response["Parameter"]["Value"]
    except Exception as e:
        print(f"Error retrieving secret {param_name}: {e}")
        raise


def generate_ad_blueprint(product_data, user_context, api_key):
    """
    Acts as an AI Creative Director, using an LLM to generate a complete ad blueprint.

    Args:
        product_data (dict): Information about the Samsung product.
        user_context (str): The creative brief provided by the retailer.
        api_key (str): openrouter api key

    Returns:
        dict: A JSON object containing the 'acts' (visual prompts) and the 'voiceover_script'.
    """
    print("Generating ad blueprint and casting voice from LLM...")

    # This is your curated library of voice actors using the IDs you provided.
    voice_options = {
        "professional_male_voice_1": "wlmwDR77ptH6bKHZui0l",
        "professional_female_voice_1": "wlmwDR77ptH6bKHZui0l",
        "professional_female_voice_2": "2zRM7PkgwBPiau2jvVXc", 
    }

    # --- START OF CHANGE ---
    prompt = f"""
    You are an expert but cautious creative director for a Samsung ad. The total ad length will be 26 seconds, with the final 2 seconds being a silent branding outro.
    Your primary goal is to generate a blueprint with visual prompts that are safe and will not be flagged by downstream AI content filters.

    Your task is to generate a complete creative blueprint as a single, valid JSON object.
    The blueprint must have three keys:
    1. "acts": An array of 3 vivid, visual prompts for a text-to-video AI model. 
       ## IMPORTANT CONSTRAINT ##
       These prompts must be carefully written to avoid content policy violations. 
       - Use neutral, descriptive language.
       - AVOID words related to impact, drama, or conflict (e.g., "shot", "dramatic", "tension", "hit").
       - INSTEAD, use safer synonyms (e.g., "a view of", "a scene showing", "an exciting moment", "connecting with the ball").
       - Focus on the product, scenery, and positive emotions.
    2. "voiceover_script": A cohesive voiceover script, that is timed to last approximately 22-23 seconds, ensuring it ends naturally before the final branding shot.
    3. "voice_id": Based on the user's context, select the SINGLE MOST appropriate voice for the ad's tone from the 'Available Voice IDs' and return its corresponding unique ID string (the value), not its descriptive name (the key).

    Product Name: {product_data.get('productName')}
    User Context: {user_context}
    Available Voice IDs: {json.dumps(voice_options)}

    Your output MUST be a single, valid JSON object. Do not add any explanation.
    """
    # --- END OF CHANGE ---

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://ad-forge-hackathon",
        "X-Title": "Samsung Ad-Forge",
    }

    payload = {
        "model": "google/gemini-flash-1.5",
        "messages": [{"role": "user", "content": prompt}],
        "response_format": {"type": "json_object"},  # Ask for JSON output
    }

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload
    )

    if response.status_code != 200:
        print(f"Error from LLM API: {response.text}")
    response.raise_for_status()

    # Parse the JSON string from the response
    blueprint_str = response.json()["choices"][0]["message"]["content"]
    return json.loads(blueprint_str)


def generate_voiceover(script, voice_id, api_key, bucket_name):
    """
    Generates a voiceover using the ElevenLabs API and uploads it to S3.

    Args:
        script (str): The text script for the voiceover.
        voice_id (str): selected voice_id from elevenlabs
        api_key (str): The ElevenLabs API key.
        bucket_name (str): The S3 bucket to upload the generated audio to.

    Returns:
        str: A presigned URL to the generated audio file in S3.
    """

    print(f"Generating voiceover with selected Voice ID: {voice_id}...")

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"  # Use the selected voice_id
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": api_key,
    }
    payload = {
        "text": script,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.5},
    }

    response = requests.post(url, json=payload, headers=headers)
    response.raise_for_status()

    audio_key = f"audio/{uuid.uuid4()}.mp3"
    s3.put_object(
        Bucket=bucket_name,
        Key=audio_key,
        Body=response.content,
        ContentType="audio/mpeg",
    )

    # Generate a presigned URL for public access (valid for 10 minutes)
    audio_url = s3.generate_presigned_url(
        "get_object", Params={"Bucket": bucket_name, "Key": audio_key}, ExpiresIn=600
    )
    return audio_url


def generate_video_clip(prompt, hf_client_video, results_list, index):
    """
    Generates a single video clip using the Hugging Face client for Fal.ai.

    Args:
        prompt (str): The text prompt for the video generation.
        hf_client (InferenceClient): The initialized Hugging Face client.
        results_list (list): A list to store the output video bytes.
        index (int): The index in the list to store the result.
    """
    print(f"Starting video generation for prompt {index+1}...")
    try:
        video_bytes = hf_client_video.text_to_video(
            prompt,
            model="Wan-AI/Wan2.2-T2V-A14B",
        )
        print(f"Finished video generation for prompt {index+1}.")
        results_list[index] = video_bytes
    except Exception as e:
        # --- THIS IS THE NEW DEBUGGING LOGIC ---
        print(f"--- DETAILED ERROR CAUGHT for clip {index+1} ---")
        print(f"PROMPT: {prompt}")
        print(f"EXCEPTION TYPE: {type(e).__name__}")
        print(f"FULL ERROR: {e}")
        print(f"-------------------------------------------")
        results_list[index] = None
        print(f"Error generating clip {index+1}: {e}")
        results_list[index] = None


def generate_final_video(clips, voiceover_url, music_url, api_key):
    """
    Assembles all generated and curated assets into a final video using the Shotstack API.

    Args:
        clips (list): A list of presigned URLs to the AI-generated video clips.
        voiceover_url (str): A presigned URL to the AI-generated voiceover.
        music_url (str): A presigned URL to the background music track.
        api_key (str): The Shotstack API key.

    Returns:
        str: The URL of the final, rendered video ad.
    """
    print("Assembling final, multi-track video with Shotstack...")
    url = "https://api.shotstack.io/v1/render"
    headers = {"x-api-key": api_key, "Content-Type": "application/json"}

    total_video_length = sum(c.get("length", 0) for c in clips)
    video_track = {"clips": clips}
    voiceover_track = {
        "clips": [
            {
                "asset": {"type": "audio", "src": voiceover_url, "volume": 1},
                "start": 0,
                "length": total_video_length - 2,
            }
        ]
    }
    music_track = {
        "clips": [
            {
                "asset": {"type": "audio", "src": music_url, "volume": 0.2},
                "start": 0,
                "length": total_video_length - 2,
            }
        ]
    }  # Music at 20% volume

    payload = {
        "timeline": {"tracks": [video_track, voiceover_track, music_track]},
        "output": {"format": "mp4", "resolution": "hd"},
    }

    response = requests.post(url, headers=headers, json=payload)
    if response.status_code != 201:
        print(f"Error from Shotstack API: {response.text}")
    response.raise_for_status()
    render_id = response.json()["response"]["id"]

    render_url = f"https://api.shotstack.io/v1/render/{render_id}"
    for _ in range(36):  # Poll for up to 3 minutes
        time.sleep(5)
        status_response = requests.get(render_url, headers=headers)
        status = status_response.json()["response"]["status"]
        if status == "done":
            return status_response.json()["response"]["url"]
        if status == "failed":
            print(f"Shotstack rendering failed: {status_response.text}")
            raise Exception("Video rendering failed.")
    raise Exception("Video rendering timed out.")


def lambda_handler(event, context):
    """
    The main handler for the long-running worker function.

    This function is triggered asynchronously by the ForgeFunction. It fetches job
    details from DynamoDB, runs the full generative AI pipeline, and updates
    DynamoDB with the final result or an error message.
    """

    job_id = ""
    try:
        # 1. Get Job ID from the trigger event
        job_id = event["jobId"]
        print(f"Worker started for Job ID: {job_id}")

        # 2. Setup: Get table name and API keys
        jobs_table_name = os.environ.get("JOBS_TABLE_NAME")
        table = dynamodb.Table(jobs_table_name)

        hf_token = get_secret(os.environ.get("HF_TOKEN_PARAM"))
        elevenlabs_key = get_secret(os.environ.get("ELEVENLABS_API_KEY_PARAM"))
        shotstack_key = get_secret(os.environ.get("SHOTSTACK_API_KEY_PARAM"))
        openrouter_key = get_secret(
            os.environ.get("OPENROUTER_API_KEY_PARAM")
        )  # Assuming you use this for the blueprint

        # 3. Fetch Job Details from DynamoDB
        response = table.get_item(Key={"jobId": job_id})
        item = response.get("Item")
        if not item:
            raise Exception(f"Job {job_id} not found in DynamoDB.")

        request_body = item.get("requestBody", {})
        sku = request_body.get("sku")
        user_context = request_body.get("user_context")

        bucket_name = "ad-forge-database-amg-2025"

        # -- 2. GET DATA & BLUEPRINT --
        db_object = s3.get_object(Bucket=bucket_name, Key="product_db.json")
        product_database = json.loads(db_object["Body"].read().decode("utf-8"))
        product_data = product_database.get(sku)

        if not product_data:
            return {
                "statusCode": 404,
                "body": json.dumps({"message": f"Product SKU '{sku}' not found."}),
            }

        print("Generating ad blueprint...")
        hf_client = InferenceClient(token=openrouter_key)
        ad_blueprint = generate_ad_blueprint(product_data, user_context, openrouter_key)
        hf_client_video = InferenceClient(provider="replicate", token=hf_token, timeout=120)

        # -- 3. GENERATE ALL ASSETS IN PARALLEL --
        print("Generating voiceover and video clips in parallel...")
        threads = []
        video_clip_bytes = [None] * 3

        for i, act in enumerate(ad_blueprint["acts"]):
            if isinstance(act, dict):
                prompt = act.get('prompt', '')
            else:
                prompt = str(act)

            thread = Thread(
                target=generate_video_clip,
                args=(prompt, hf_client_video, video_clip_bytes, i),
            )
            threads.append(thread)
            thread.start()

        voiceover_url = generate_voiceover(
            ad_blueprint["voiceover_script"],
            ad_blueprint["voice_id"],
            elevenlabs_key,
            bucket_name,
        )

        for thread in threads:
            thread.join()

        if None in video_clip_bytes:
            raise Exception("One or more video clips failed to generate.")

        # --- 4. UPLOAD GENERATED CLIPS & GET URLS ---
        print("Uploading generated clips to S3...")
        video_clip_urls = []
        for video_bytes in video_clip_bytes:
            clip_key = f"generated_clips/{uuid.uuid4()}.mp4"
            s3.put_object(
                Bucket=bucket_name,
                Key=clip_key,
                Body=video_bytes,
                ContentType="video/mp4",
            )
            clip_url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": bucket_name, "Key": clip_key},
                ExpiresIn=600,
            )
            video_clip_urls.append(clip_url)

        # -- 5. ASSEMBLE THE FINAL VIDEO --
        print("Assembling final video with Shotstack...")
        product_shot_urls=[]
        for s3_uri in product_data['product_shot_url']:
            bucket = s3_uri.split('/')[2]
            key = '/'.join(s3_uri.split('/')[3:])
            product_shot_urls.append(s3.generate_presigned_url('get_object', Params={'Bucket': bucket, 'Key': key}, ExpiresIn=600))

        samsung_logo_key = (
            "curated_clips/samsung_name.mp4"  # Assuming it's in this folder
        )
        samsung_logo_url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket_name, "Key": samsung_logo_key},
            ExpiresIn=600,
        )

        music_key = "music/background_music.mp3"
        music_url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket_name, "Key": music_key},
            ExpiresIn=600,
        )

        # Create the timeline for Shotstack
        timeline_clips = [
            {
                "asset": {"type": "video", "src": video_clip_urls[0]},
                "start": 0,
                "length": 5,
            },
            {
                "asset": {"type": "video", "src": product_shot_urls[0], "volume": 0},
                "start": 5,
                "length": 4,
            },
            {
                "asset": {"type": "video", "src": video_clip_urls[1]},
                "start": 9,
                "length": 5,
            },
            {
                "asset": {"type": "video", "src": product_shot_urls[1], "volume": 0},
                "start": 14,
                "length": 5,
            },
            {
                "asset": {"type": "video", "src": video_clip_urls[2]},
                "start": 19,
                "length": 5,
            },
            {
                "asset": {"type": "video", "src": samsung_logo_url},
                "start": 24,
                "length": 2,
            },
        ]

        final_video_url = generate_final_video(
            timeline_clips, voiceover_url, music_url, shotstack_key
        )

        # 5. Update Job Status in DynamoDB with the final result
        print(f"Pipeline complete. Updating job {job_id} to COMPLETE.")
        table.update_item(
            Key={"jobId": job_id},
            UpdateExpression="SET #s = :status, finalVideoUrl = :url, updatedAt = :time",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={
                ":status": "COMPLETE",
                ":url": final_video_url,
                ":time": int(time.time()),
            },
        )

    except Exception as e:
        print(f"Worker failed for Job ID {job_id}. Error: {e}")
        # Update job status to FAILED in DynamoDB
        jobs_table_name = os.environ.get("JOBS_TABLE_NAME")
        table = dynamodb.Table(jobs_table_name)
        table.update_item(
            Key={"jobId": event.get("jobId", "unknown")},
            UpdateExpression="SET #s = :status, errorMessage = :error",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":status": "FAILED", ":error": str(e)},
        )
