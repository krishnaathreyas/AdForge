// This imports Bixby's library for making HTTP requests.
import http from 'http';

export default function createAdForgeAd(product, marketingContext) {
  // --- 1. Prepare the Data ---

  // Map the Bixby product concepts to the SKUs your backend understands.
  const productSKUMap = {
    'GalaxyS24Ultra': 'PROD-S24ULTRA',
    'NeoQLED8KTV': 'PROD-QN900D-TV',
    'BespokeAIWasher': 'PROD-WW12T504DAB'
  };

  const sku = productSKUMap[product.name.toString()]; // Use .toString() for safety.

  // Create the JSON payload to send to your API.
  const requestPayload = {
    sku: sku,
    user_context: marketingContext.context,
    language: marketingContext.language || 'English'
  };

  // --- 2. Call Your Backend API ---

  // IMPORTANT: Replace this with your actual AWS API Gateway URL.
  const url = 'https://7i5316q6o2.execute-api.ap-south-1.amazonaws.com/Prod/forge';

  const options = {
    format: 'json',       // We are sending and expecting JSON.
    returnHeaders: false  // We only need the response body.
  };

  try {
    // Make the POST request to your backend.
    // The http.postUrl library handles converting the payload to JSON for you.
    const response = http.postUrl(url, requestPayload, options);
    
    // --- 3. Return a Success Result to Bixby ---
    
    // The 'response' will contain whatever your API returns (e.g., { "jobId": "..." }).
    const jobId = response.jobId || 'N/A'; // Safely access the jobId.

    return {
      success: true,
      message: `Successfully started Ad-Forge job ${jobId} for the ${product.name}`,
      product: product,
      context: marketingContext
    };

  } catch (error) {
    // --- 4. Return an Error Result to Bixby ---

    return {
      success: false,
      message: `Failed to create advertisement: ${error.message}`,
      product: product,
      context: marketingContext
    };
  }
};