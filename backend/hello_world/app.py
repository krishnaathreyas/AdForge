import json
import os
import boto3
import requests
import time
import uuid
from huggingface_hub import InferenceClient
from threading import Thread

# Initialize AWS clients
s3 = boto3.client('s3')
ssm = boto3.client('ssm')

def get_secret(param_name):
    """Retrieves a secret from AWS Parameter Store."""
    try:
        response = ssm.get_parameter(Name=param_name, WithDecryption=True)
        return response['Parameter']['Value']
    except Exception as e:
        print(f"Error retrieving secret {param_name}: {e}")
        raise

def generate_ad_blueprint(product_data, user_context, api_key):
    """Generates a structured JSON ad blueprint using an LLM."""
    
    prompt = f"""
    You are an expert creative director for a Samsung ad. The total ad length will be 20 seconds. The final 2 seconds will be a silent branding outro.
    Your task is to generate a blueprint for the first 18 seconds.
    The ad should have a 3-act structure. For each act, create a short, vivid, visual prompt suitable for a text-to-video AI model.
    Also, write a single, cohesive voiceover script that spans all three acts and that is timed to last approximately 17-18 seconds, ensuring it ends naturally before the final branding shot.

    Product Name: {product_data.get('productName')}
    User Context: {user_context}

    Your output MUST be a single, valid JSON object with two keys: "acts" (an array of 3 objects, each with a "prompt" key) and "voiceover_script" (a string).
    Example format: {{"acts": [{{"prompt": "..."}}, {{"prompt": "..."}}, {{"prompt": "..."}}], "voiceover_script": "..."}}
    """
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://ad-forge-hackathon", 
        "X-Title": "Samsung Ad-Forge"
    }
    
    payload = {
        "model": "google/gemini-flash-1.5", 
        "messages": [{"role": "user", "content": prompt}],
        "response_format": {"type": "json_object"} # Ask for JSON output
    }
    
    response = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload)
    
    if response.status_code != 200:
        print(f"Error from LLM API: {response.text}")
    response.raise_for_status()
    
    # Parse the JSON string from the response
    blueprint_str = response.json()['choices'][0]['message']['content']
    return json.loads(blueprint_str)


def generate_voiceover(script, api_key, bucket_name):
    """Generates a voiceover, uploads it to S3, and returns the public URL."""
    VOICE_ID = "21m00Tcm4TlvDq8ikWAM" # A default, pleasant voice from ElevenLabs
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"
    headers = {"Accept": "audio/mpeg", "Content-Type": "application/json", "xi-api-key": api_key}
    payload = {"text": script, "model_id": "eleven_multilingual_v2", "voice_settings": {"stability": 0.5, "similarity_boost": 0.5}}
    
    response = requests.post(url, json=payload, headers=headers)
    response.raise_for_status()

    # Upload the audio content to S3
    audio_key = f"audio/{uuid.uuid4()}.mp3"
    s3.put_object(Bucket=bucket_name, Key=audio_key, Body=response.content, ContentType='audio/mpeg')
    
    # Generate a presigned URL for public access (valid for 10 minutes)
    audio_url = s3.generate_presigned_url('get_object', Params={'Bucket': bucket_name, 'Key': audio_key}, ExpiresIn=600)
    return audio_url

def generate_video_clip(prompt, hf_client, results_list, index):
    """Generates a single video clip using the Hugging Face client for Fal.ai."""
    print(f"Starting video generation for prompt {index+1}...")
    try:
        video_bytes = hf_client.text_to_video(
            prompt,
            model="Wan-AI/Wan2.2-T2V-A14B",
        )
        print(f"Finished video generation for prompt {index+1}.")
        results_list[index] = video_bytes
    except Exception as e:
        print(f"Error generating clip {index+1}: {e}")
        results_list[index] = None

def generate_final_video(clips, voiceover_url, music_url, api_key):
    """Submits the final, multi-track video editing job to Shotstack."""
    print("Assembling final, multi-track video with Shotstack...")
    url = "https://api.shotstack.io/v1/render"
    headers = {"x-api-key": api_key, "Content-Type": "application/json"}

    total_video_length = sum(c.get('length', 0) for c in clips)
    video_track = {"clips": clips}
    voiceover_track = {"clips": [{"asset": {"type": "audio", "src": voiceover_url, "volume": 1}, "start": 0, "length": total_video_length}]}
    music_track = {"clips": [{"asset": {"type": "audio", "src": music_url, "volume": 0.2}, "start": 0, "length": total_video_length}]} # Music at 20% volume

    payload = {
        "timeline": {
            "tracks": [video_track, voiceover_track, music_track]
        },
        "output": {"format": "mp4", "resolution": "hd"}
    }
    
    response = requests.post(url, headers=headers, json=payload)
    if response.status_code != 201:
        print(f"Error from Shotstack API: {response.text}")
    response.raise_for_status()
    render_id = response.json()['response']['id']
    
    render_url = f"https://api.shotstack.io/v1/render/{render_id}"
    for _ in range(36): # Poll for up to 3 minutes
        time.sleep(5)
        status_response = requests.get(render_url, headers=headers)
        status = status_response.json()['response']['status']
        if status == 'done':
            return status_response.json()['response']['url']
        if status == 'failed':
            print(f"Shotstack rendering failed: {status_response.text}")
            raise Exception("Video rendering failed.")
    raise Exception("Video rendering timed out.")

def lambda_handler(event, context):
    try:
        # -- 1. SETUP --
        print("Starting Ad-Forge request...")
        body = json.loads(event.get('body', '{}'))
        sku = body.get('sku')
        user_context = body.get('context', 'a general promotional ad')

        if not sku: return {"statusCode": 400, "body": json.dumps({"message": "Error: 'sku' is required."})}

        # bucket_name = os.environ.get('PRODUCT_DB_BUCKET')

        bucket_name = "ad-forge-database-amg-2025"
        openrouter_key = get_secret(os.environ.get('OPENROUTER_API_KEY_PARAM'))
        hf_token = get_secret(os.environ.get('HF_TOKEN_PARAM'))
        elevenlabs_key = get_secret(os.environ.get('ELEVENLABS_API_KEY_PARAM'))
        shotstack_key = get_secret(os.environ.get('SHOTSTACK_API_KEY_PARAM'))

        hf_client = InferenceClient(provider="fal-ai", token=hf_token)

        # -- 2. GET DATA & BLUEPRINT --
        db_object = s3.get_object(Bucket=bucket_name, Key='product_db.json')
        product_database = json.loads(db_object['Body'].read().decode('utf-8'))
        product_data = product_database.get(sku)
        if not product_data: return {"statusCode": 404, "body": json.dumps({"message": f"Product SKU '{sku}' not found."})}
        
        print("Generating ad blueprint...")
        ad_blueprint = generate_ad_blueprint(product_data, user_context, openrouter_key)
        
        # -- 3. GENERATE ALL ASSETS IN PARALLEL --
        print("Generating voiceover and video clips in parallel...")
        threads = []
        video_clip_bytes = [None] * 3
        
        for i, act in enumerate(ad_blueprint['acts']):
            thread = Thread(target=generate_video_clip, args=(act['prompt'], hf_client, video_clip_bytes, i))
            threads.append(thread)
            thread.start()

        voiceover_url = generate_voiceover(ad_blueprint['voiceover_script'], elevenlabs_key, bucket_name)
        
        for thread in threads:
            thread.join()

        if None in video_clip_bytes:
            raise Exception("One or more video clips failed to generate.")
        
        # --- 4. UPLOAD GENERATED CLIPS & GET URLS ---
        print("Uploading generated clips to S3...")
        video_clip_urls = []
        for video_bytes in video_clip_bytes:
            clip_key = f"generated_clips/{uuid.uuid4()}.mp4"
            s3.put_object(Bucket=bucket_name, Key=clip_key, Body=video_bytes, ContentType='video/mp4')
            clip_url = s3.generate_presigned_url('get_object', Params={'Bucket': bucket_name, 'Key': clip_key}, ExpiresIn=600)
            video_clip_urls.append(clip_url)

        # -- 5. ASSEMBLE THE FINAL VIDEO --
        print("Assembling final video with Shotstack...")
        s3_uri = product_data['product_shot_url']
        template_bucket = s3_uri.split('/')[2]
        template_key = '/'.join(s3_uri.split('/')[3:])
        product_shot_url = s3.generate_presigned_url('get_object', Params={'Bucket': template_bucket, 'Key': template_key}, ExpiresIn=600)

        samsung_logo_key = "curated_clips/samsung_name.mp4" # Assuming it's in this folder
        samsung_logo_url = s3.generate_presigned_url('get_object', Params={'Bucket': bucket_name, 'Key': samsung_logo_key}, ExpiresIn=600)

        music_key = "music/background_music.mp3"
        music_url = s3.generate_presigned_url('get_object', Params={'Bucket': bucket_name, 'Key': music_key}, ExpiresIn=600)


        # Create the timeline for Shotstack
        timeline_clips = [
            {"asset": {"type": "video", "src": video_clip_urls[0]}, "start": 0, "length": 5},
            {"asset": {"type": "video", "src": product_shot_url, "volume": 0}, "start": 5, "length": 3},
            {"asset": {"type": "video", "src": video_clip_urls[1]}, "start": 8, "length": 5},
            {"asset": {"type": "video", "src": video_clip_urls[2]}, "start": 13, "length": 5},
            {"asset": {"type": "video", "src": samsung_logo_url}, "start": 18, "length": 2},
        ]
        
        final_video_url = generate_final_video(timeline_clips, voiceover_url, music_url, shotstack_key)

        print("Successfully generated final video.")
        return {"statusCode": 200, "body": json.dumps({"finalVideoUrl": final_video_url})}

    except Exception as e:
        print(f"A critical error occurred: {e}")
        return {"statusCode": 500, "body": json.dumps({"message": "Internal Server Error"})} 
    
""" def lambda_handler(event, context):
    try:
        print("--- RUNNING IN ASSEMBLY-ONLY TEST MODE ---")
        
        # -- 1. SETUP --
        body = json.loads(event.get('body', '{}'))
        sku = body.get('sku')
        
        # bucket_name = os.environ.get('PRODUCT_DB_BUCKET')

        bucket_name = "ad-forge-database-amg-2025"
        elevenlabs_key = get_secret(os.environ.get('ELEVENLABS_API_KEY_PARAM'))
        shotstack_key = get_secret(os.environ.get('SHOTSTACK_API_KEY_PARAM'))

        # -- 2. HARDCODE THE ASSETS --
        # This is a placeholder script. The real one is in the generated audio.
        voiceover_script_for_test = "This is a test of the final video assembly."
        
        # !!! IMPORTANT: REPLACE THESE WITH THE S3 URIs YOU COPIED !!!
        generated_clip_uris = [
            "s3://ad-forge-database-amg-2025/generated_clips/24283203-cd2b-40ea-ab6c-01d70c0fc1ef.mp4",
            "s3://ad-forge-database-amg-2025/generated_clips/275eabe7-5349-4a5f-9653-691e4945cfc7.mp4",
            "s3://ad-forge-database-amg-2025/generated_clips/efff85fe-e1f8-422f-8afb-e4330b91db21.mp4"
        ]

        # -- 3. GENERATE VOICEOVER (Still cheap to run) --
        print("Generating voiceover...")
        voiceover_url = generate_voiceover(voiceover_script_for_test, elevenlabs_key, bucket_name)
        
        # -- 4. GET PRESIGNED URLS for all assets --
        print("Generating presigned URLs...")
        video_clip_urls = []
        for s3_uri in generated_clip_uris:
            bucket = s3_uri.split('/')[2]
            key = '/'.join(s3_uri.split('/')[3:])
            video_clip_urls.append(s3.generate_presigned_url('get_object', Params={'Bucket': bucket, 'Key': key}, ExpiresIn=600))
        
        # Get the curated product shot URL
        db_object = s3.get_object(Bucket=bucket_name, Key='product_db.json')
        product_database = json.loads(db_object['Body'].read().decode('utf-8'))
        product_data = product_database.get(sku)
        s3_uri = product_data['product_shot_url']
        template_bucket = s3_uri.split('/')[2]
        template_key = '/'.join(s3_uri.split('/')[3:])
        product_shot_url = s3.generate_presigned_url('get_object', Params={'Bucket': template_bucket, 'Key': template_key}, ExpiresIn=600)
        
        # -- 5. ASSEMBLE THE FINAL VIDEO --
        print("Assembling final video with Shotstack...")
        timeline_clips = [
            {"asset": {"type": "video", "src": video_clip_urls[0]}, "start": 0, "length": 5},
            {"asset": {"type": "video", "src": product_shot_url}, "start": 5, "length": 3},
            {"asset": {"type": "video", "src": video_clip_urls[1]}, "start": 8, "length": 5},
            {"asset": {"type": "video", "src": video_clip_urls[2]}, "start": 13, "length": 5},
        ]
        
        final_video_url = generate_final_video(timeline_clips, voiceover_url, shotstack_key)

        print("Successfully generated final video.")
        return {"statusCode": 200, "body": json.dumps({"finalVideoUrl": final_video_url})}

    except Exception as e:
        print(f"A critical error occurred: {e}")
        return {"statusCode": 500, "body": json.dumps({"message": "Internal Server Error"})} """

