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
    Lambda 3: Print ":)" and return final result
    """
    try:
        logger.info("Lambda 3 started - Smiley Lambda")
        logger.info(f"Received event: {json.dumps(event, default=str)}")
        
        # Get data from previous lambda
        previous_data = event.get('data', {})
        combined_message = previous_data.get('combined_message', '')
        
        # Demonstrate secret retrieval
        openai_api_key = get_secret('OPENAI_API_KEY')
        google_drive_folder_id = get_secret('GOOGLE_DRIVE_FOLDER_ID')
        
        # Log that we have the secrets (without revealing values)
        logger.info(f"OpenAI API Key retrieved: {'Yes' if openai_api_key else 'No'}")
        logger.info(f"Google Drive Folder ID retrieved: {'Yes' if google_drive_folder_id else 'No'}")
        
        # Print smiley message
        message = ":)"
        final_message = f"{combined_message} {message}" if combined_message else message
        print(message)
        logger.info(f"Message: {message}")
        logger.info(f"Final combined message: {final_message}")
        
        # Collect execution history from all lambdas
        execution_history = []
        if 'previous_lambda_data' in previous_data:
            prev_lambda_data = previous_data['previous_lambda_data']
            execution_history.append({
                "lambda": "lambda1",
                "message": prev_lambda_data.get('message', ''),
                "timestamp": prev_lambda_data.get('timestamp', ''),
                "secrets_available": prev_lambda_data.get('secrets_available', {})
            })
        
        execution_history.append({
            "lambda": "lambda2",
            "message": previous_data.get('message', ''),
            "timestamp": previous_data.get('timestamp', ''),
            "secrets_available": previous_data.get('secrets_available', {})
        })
        
        execution_history.append({
            "lambda": "lambda3",
            "message": message,
            "timestamp": context.aws_request_id if hasattr(context, 'aws_request_id') else "local-dev",
            "secrets_available": {
                "openai": bool(openai_api_key),
                "google_drive": bool(google_drive_folder_id)
            }
        })
        
        # Prepare final result
        final_result = {
            "final_message": final_message,
            "execution_summary": {
                "total_lambdas": 3,
                "execution_chain": ["lambda1", "lambda2", "lambda3"],
                "messages": ["Hello", "World", ":)"],
                "combined_result": final_message
            },
            "execution_history": execution_history,
            "lambda_name": "lambda3",
            "workflow_completed": True,
            "timestamp": context.aws_request_id if hasattr(context, 'aws_request_id') else "local-dev"
        }
        
        logger.info("Lambda 3 completed successfully - Workflow finished")
        logger.info(f"Final result: {final_message}")
        
        return {
            "statusCode": 200,
            "body": json.dumps(final_result),
            "data": final_result
        }
        
    except Exception as e:
        logger.error(f"Error in Lambda 3: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e),
                "lambda_name": "lambda3",
                "workflow_completed": False
            })
        }