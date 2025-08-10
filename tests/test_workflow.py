"""
Test module for AWS Step Functions Orchestrator
"""


from src.lambda1.handler import lambda_handler as lambda_handler1
from src.lambda2.handler import lambda_handler as lambda_handler2
from src.lambda3.handler import lambda_handler as lambda_handler3


def test_lambda1():
    """
    Test Lambda 1
    """
    event = {
        "data": {
            "message": "Hello",
            "timestamp": "2023-01-01T00:00:00Z",
            "secrets_available": {
                "openai": True,
                "google_drive": True
            }
        }
    }
    context = {}
    response = lambda_handler1(event, context)

    assert response["statusCode"] == 200
    assert "data" in response
    assert response["data"]["message"] == "Hello"
    assert response["data"]["secrets_available"] == {
        "openai": False,
        "google_drive": False
    }


def test_lambda2():
    """
    Test Lambda 2
    """
    event = {
        "data": {
            "message": "World",
            "timestamp": "2023-01-01T00:00:00Z",
            "secrets_available": {
                "openai": True,
                "google_drive": True
            }
        }
    }
    context = {}
    response = lambda_handler2(event, context)

    assert response["statusCode"] == 200
    assert "data" in response
    assert response["data"]["message"] == "World"
    assert response["data"]["secrets_available"] == {
        "openai": False,
        "google_drive": False
    }


def test_lambda3():
    """
    Test Lambda 3
    """
    event = {
        "data": {
            "message": ":)",
            "timestamp": "2023-01-01T00:00:00Z",
            "secrets_available": {
                "openai": True,
                "google_drive": True
            }
        }
    }
    context = {}
    response = lambda_handler3(event, context)

    assert response["statusCode"] == 200
    assert "data" in response
    assert response["data"]["message"] == ":)"
    assert response["data"]["secrets_available"] == {
        "openai": False,
        "google_drive": False
    }
