"""
Visitor Counter Lambda
Increments a shared counter in DynamoDB and returns the new value.
"""

import json
import logging
import os
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

# ─────────────────────────────────────────────────────────────
# Logging — CloudWatch picks this up automatically
# ─────────────────────────────────────────────────────────────
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ─────────────────────────────────────────────────────────────
# Config from environment variables (set by Terraform)
# ─────────────────────────────────────────────────────────────
TABLE_NAME = os.environ["TABLE_NAME"]
COUNTER_KEY = os.environ.get("COUNTER_KEY", "visitor_count")

# boto3 client — created once per Lambda container (reused across invocations)
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def _response(status_code: int, body: dict) -> dict:
    """Standard API Gateway response with CORS headers."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps(body),
    }


def _decimal_default(obj):
    """DynamoDB returns Decimal — JSON doesn't know how to serialize it."""
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")


def lambda_handler(event, context):
    """
    Entry point. Triggered by API Gateway (HTTP API, GET /count).
    """
    logger.info("Received event: %s", json.dumps(event))

    # Handle CORS preflight
    if event.get("requestContext", {}).get("http", {}).get("method") == "OPTIONS":
        return _response(200, {"message": "CORS preflight OK"})

    try:
        # Atomic increment — ADD is safe under concurrent writes
        result = table.update_item(
            Key={"id": COUNTER_KEY},
            UpdateExpression="ADD #c :inc",
            ExpressionAttributeNames={"#c": "count"},
            ExpressionAttributeValues={":inc": 1},
            ReturnValues="UPDATED_NEW",
        )

        new_count = int(result["Attributes"]["count"])
        logger.info("Counter incremented to %d", new_count)

        return _response(200, {"count": new_count})

    except ClientError as e:
        logger.exception("DynamoDB error: %s", e)
        return _response(500, {"error": "Failed to update counter"})
    except KeyError as e:
        logger.exception("Missing key in response: %s", e)
        return _response(500, {"error": "Unexpected response from DynamoDB"})
    except Exception as e:
        logger.exception("Unhandled error: %s", e)
        return _response(500, {"error": "Internal server error"})