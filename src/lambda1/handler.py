import json
import os
import logging
import boto3
from typing import Dict, Any
from dotenv import load_dotenv

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Load environment variables for local development
if os.getenv('LOCAL_DEVELOPMENT', 'false').lower() == 'true':
    load_dotenv()

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')

def get_secret(secret_name: str) -> str:
    """
    Retrieve secret from AWS Secrets Manager or environment variable for local development
    """
    try:
        # Try to get from environment first (for local development)
        if os.getenv('LOCAL_DEVELOPMENT', 'false').lower() == 'true':
            return os.getenv(secret_name, '')
        
        # Get from AWS Secrets Manager for production
        response = secrets_client.get_secret_value(SecretId=secret_name)
        return response['SecretString']
    except Exception as e:
        logger.error(f"Error retrieving secret {secret_name}: {str(e)}")
        return ''

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda 1: Print "Hello" and pass data to next lambda
    """
    try:
        logger.info("Lambda 1 started - Hello Lambda")
        logger.info(f"Received event: {json.dumps(event, default=str)}")
        
        # Demonstrate secret retrieval
        openai_api_key = get_secret('OPENAI_API_KEY')
        google_drive_folder_id = get_secret('GOOGLE_DRIVE_FOLDER_ID')
        
        # Log that we have the secrets (without revealing values)
        logger.info(f"OpenAI API Key retrieved: {'Yes' if openai_api_key else 'No'}")
        logger.info(f"Google Drive Folder ID retrieved: {'Yes' if google_drive_folder_id else 'No'}")
        
        # Print Hello message
        message = "Hello"
        print(message)
        logger.info(f"Message: {message}")
        
        # Prepare data to pass to next lambda
        output_data = {
            "message": message,
            "timestamp": context.aws_request_id if hasattr(context, 'aws_request_id') else "local-dev",
            "lambda_name": "lambda1",
            "input_data": event,
            "secrets_available": {
                "openai": bool(openai_api_key),
                "google_drive": bool(google_drive_folder_id)
            },
            "next_lambda": "lambda2"
        }
        
        logger.info("Lambda 1 completed successfully")
        return {
            "statusCode": 200,
            "body": json.dumps(output_data),
            "data": output_data
        }
        
    except Exception as e:
        logger.error(f"Error in Lambda 1: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e),
                "lambda_name": "lambda1"
            })
        }