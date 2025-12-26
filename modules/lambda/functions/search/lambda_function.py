import json
import os

import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource("dynamodb")

TABLE_NAME = os.environ.get("TABLE_NAME")
if not TABLE_NAME:
    # Fallback for older deployments (NOT recommended, but better than hard fail)
    TABLE_NAME = os.environ.get("table_name", "imagetable")

table = dynamodb.Table(TABLE_NAME)


def _cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "GET,OPTIONS",
    }


def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    # Handle CORS preflight
    if event.get("httpMethod") == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": _cors_headers(),
            "body": ""
        }

    try:
        params = event.get("queryStringParameters") or {}
        raw_tag = (params.get("tag") or "").strip()

        # If no tag => treat as "Gallery" (return all images)
        if not raw_tag:
            print("No tag provided -> returning full gallery (scan).")
            resp = table.scan()
            items = resp.get("Items", [])
        else:
            tag = raw_tag.lower()
            print(f"Searching for tag: {tag}")

            # Simple approach: scan + filter on Labels list
            # (fine for demo / small datasets).
            resp = table.scan(
                FilterExpression=Attr("Labels").contains(raw_tag)
            )
            items = resp.get("Items", [])

        # Normalize items into the shape expected by the frontend
        results = []
        for item in items:
            image_id = item.get("ImageID") or item.get("image_id") or item.get("ObjectKey")
            labels = item.get("Labels") or item.get("labels") or []
            image_url = (
                item.get("ImageUrl")
                or item.get("image_url")
                or ""
            )
            object_key = item.get("ObjectKey") or item.get("object_key") or image_id

            results.append(
                {
                    "image_id": image_id,
                    "labels": labels,
                    "image_url": image_url,
                    "object_key": object_key,
                }
            )

        return {
            "statusCode": 200,
            "headers": _cors_headers(),
            "body": json.dumps({"results": results}),
        }

    except Exception as e:
        print("ERROR:", str(e))
        return {
            "statusCode": 500,
            "headers": _cors_headers(),
            "body": json.dumps({"error": str(e)}),
        }