import json
import os
import boto3
import requests
import time
import uuid

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

def generate_script(product_data, user_context, api_key):
    # ... (This function is the same as in Step 4, no changes needed)
    feature_list = ", ".join(product_data.get('keyFeatures', []))
    prompt = (
        f"You are a professional advertising copywriter for Samsung. "
        f"Your task is to generate a short, punchy, 15-second video ad script. "
        f"Product Name: {product_data.get('productName')}. "
        f"Key Features to highlight: {feature_list}. "
        f"The ad's theme is: {user_context}."
    )
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json", "HTTP-Referer": "https://ad-forge-hackathon", "X-Title": "Samsung Ad-Forge"}
    payload = {"model": "google/gemini-flash-1.5", "messages": [{"role": "user", "content": prompt}], "max_tokens": 200}
    response = requests.post("https://openrouter.ai/api/v1/chat/completions", headers=headers, json=payload)
    if response.status_code != 200:
        print(f"Error from API: {response.text}")
    response.raise_for_status()
    return response.json()['choices'][0]['message']['content'].strip()

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


def generate_video(script, audio_url, template_url, api_key):
    """Submits a video editing job to Shotstack and returns the final video URL."""
    url = "https://api.shotstack.io/v1/render"
    headers = {"x-api-key": api_key, "Content-Type": "application/json"}
    
    payload = {
        "timeline": {
            "tracks": [
                {"clips": [{"asset": {"type": "video", "src": template_url}, "start": 0, "length": 15}]},
                {"clips": [{"asset": {"type": "audio", "src": audio_url}, "start": 0, "length": 15}]},
                {"clips": [{"asset": {"type": "title", "text": script, "style": "subtitle"}, "start": 1, "length": 13}]}
            ]
        },
        "output": {"format": "mp4", "resolution": "hd"}
    }

    response = requests.post(url, headers=headers, json=payload)
    
    # Better error logging
    if response.status_code != 201: # Shotstack returns 201 on success
        print(f"Error from Shotstack API: {response.text}")
    
    response.raise_for_status()
    render_id = response.json()['response']['id']
    
    render_url = f"https://api.shotstack.io/v1/render/{render_id}"
    for _ in range(24): # Poll for up to 120 seconds
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
        # bucket_name = os.environ.get('PRODUCT_DB_BUCKET')
        bucket_name = "ad-forge-database-amg-2025"
        params = event.get('queryStringParameters', {})
        sku = params.get('sku')
        user_context = params.get('context', 'a general promotional ad')

        if not sku: return {"statusCode": 400, "body": json.dumps({"message": "Error: 'sku' is required."})}

        db_object = s3.get_object(Bucket=bucket_name, Key='product_db.json')
        product_database = json.loads(db_object['Body'].read().decode('utf-8'))
        product_data = product_database.get(sku)

        if not product_data: return {"statusCode": 404, "body": json.dumps({"message": f"Product SKU '{sku}' not found."})}
        
        # --- The Orchestration ---
        openrouter_key = get_secret(os.environ.get('OPENAI_API_KEY_PARAM'))
        elevenlabs_key = get_secret(os.environ.get('ELEVENLABS_API_KEY_PARAM'))
        shotstack_key = get_secret(os.environ.get('SHOTSTACK_API_KEY_PARAM'))

        ad_script = generate_script(product_data, user_context, openrouter_key)
        
        voiceover_url = generate_voiceover(ad_script, elevenlabs_key, bucket_name)
        
        # --- NEW LOGIC HERE ---
        # Parse the S3 URI for the template video
        s3_uri = product_data['brandTemplates']['monsoon_sale']
        template_bucket = s3_uri.split('/')[2]
        template_key = '/'.join(s3_uri.split('/')[3:])
        
        # Generate a presigned URL for the video template
        template_video_url = s3.generate_presigned_url(
            'get_object', 
            Params={'Bucket': template_bucket, 'Key': template_key}, 
            ExpiresIn=600 # URL is valid for 10 minutes
        )
        
        final_video_url = generate_video(ad_script, voiceover_url, template_video_url, shotstack_key)

        return {"statusCode": 200, "body": json.dumps({"finalVideoUrl": final_video_url})}

    except Exception as e:
        print(f"An error occurred: {e}")
        return {"statusCode": 500, "body": json.dumps({"message": "Internal Server Error"})}
