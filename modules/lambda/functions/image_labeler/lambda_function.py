import boto3
import json
import os
import re

rekognition = boto3.client("rekognition")
dynamodb = boto3.client("dynamodb")

TABLE_NAME = os.environ.get("TABLE_NAME")


def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    if not TABLE_NAME:
        raise RuntimeError("TABLE_NAME environment variable is not set")

    try:
        # ---- 0. Read S3 event ----
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        image_key = record["s3"]["object"]["key"]

        print(f"Processing object: s3://{bucket}/{image_key}")

        # Containers for all metadata
        general_labels = []       # generic Rekognition labels (lowercase strings)
        brand_tags = set()        # detected brands/logos
        person_detected = False   # from detect_faces
        ocr_words = []            # individual tokens from OCR (lowercased, cleaned)
        ocr_chunks = []           # raw OCR chunks/lines (lowercased) for regex
        tech_tools = set()        # devops/cloud tool names from OCR
        patient_name = None
        disease = None

        # --- Known tech / DevOps keywords (extend as needed) ---
        tech_keywords = {
            "prometheus", "grafana", "ansible", "jenkins", "docker",
            "kubernetes", "k8s", "helm", "terraform",
            "aws", "gcp", "azure", "lambda", "s3", "ec2", "rds",
            "vpc", "alb", "nlb", "eks", "gke", "aks",
            "mongodb", "mysql", "postgres", "redis", "elastic",
            "cicd", "monitoring", "observability", "ingress", "namespace"
        }

        # --- Known brands / companies / cloud vendors (lowercase) ---
        brand_keywords = {
            "nike", "starbucks", "coca cola", "coca-cola", "mcdonalds",
            "aws", "amazon web services", "amazon",
            "google", "gcp", "microsoft", "azure",
            "facebook", "meta", "twitter", "x",
            "apple", "ibm", "oracle", "tesla",
            "adidas", "puma", "pepsi", "netflix"
        }

        # =====================================================================
        # 1) General object + brand/logo detection via detect_labels
        # =====================================================================
        try:
            label_resp = rekognition.detect_labels(
                Image={"S3Object": {"Bucket": bucket, "Name": image_key}},
                MaxLabels=25,
                MinConfidence=70
            )
            raw_labels = label_resp.get("Labels", [])

            for lbl in raw_labels:
                name_lc = lbl.get("Name", "").lower()
                if not name_lc:
                    continue
                general_labels.append(name_lc)

                # Brand/logo detection by matching known brand keywords
                for brand in brand_keywords:
                    # brand keyword appears in the label name, e.g. "nike logo", "amazon web services"
                    if brand in name_lc:
                        brand_tags.add(brand)
        except Exception as e_labels:
            print("detect_labels failed:", str(e_labels))

        print("General labels:", general_labels)
        print("Brand tags from labels:", list(brand_tags))

        # =====================================================================
        # 2) Human / face detection
        # =====================================================================
        try:
            face_resp = rekognition.detect_faces(
                Image={"S3Object": {"Bucket": bucket, "Name": image_key}},
                Attributes=["DEFAULT"]
            )
            if face_resp.get("FaceDetails"):
                person_detected = True
                print(f"Faces detected: {len(face_resp['FaceDetails'])}")
        except Exception as e_faces:
            print("detect_faces failed:", str(e_faces))

        # =====================================================================
        # 3) Text / OCR detection
        # =====================================================================
        try:
            text_resp = rekognition.detect_text(
                Image={"S3Object": {"Bucket": bucket, "Name": image_key}}
            )

            for det in text_resp.get("TextDetections", []):
                detected = det.get("DetectedText", "")
                dtype = det.get("Type")
                if not detected:
                    continue

                detected_lc = detected.lower()

                # Keep full chunks/lines for regex-based parsing
                if dtype in ["WORD", "LINE"]:
                    cleaned_chunk = re.sub(r"[^a-z0-9+.\- ]", "", detected_lc)
                    if cleaned_chunk and len(cleaned_chunk) > 1:
                        ocr_chunks.append(cleaned_chunk)

                        # Split into word-level tokens for tech keyword detection
                        for token in cleaned_chunk.split():
                            if len(token) > 1:
                                ocr_words.append(token.strip())

        except Exception as e_text:
            print("detect_text failed:", str(e_text))

        print("OCR chunks:", ocr_chunks)
        print("OCR words:", ocr_words)

        # =====================================================================
        # 4) Smart analysis on OCR text (medical fields + tech tools)
        # =====================================================================
        full_text = " ".join(ocr_chunks)  # preserve spacing for regex
        print("Full OCR text for regex:", full_text)

        # ---- Medical patterns (case-insensitive) ----
        try:
            # Patient name
            name_match = re.search(
                r"(patient|patient name|name|pt)[:\-\s]+([a-zA-Z ]{2,50})",
                full_text,
                re.IGNORECASE,
            )
            if name_match:
                patient_name = name_match.group(2).strip().lower()

            # Disease / diagnosis / problem
            disease_match = re.search(
                r"(disease|diagnosis|problem|issue)[:\-\s]+([a-zA-Z ]{2,50})",
                full_text,
                re.IGNORECASE,
            )
            if disease_match:
                disease = disease_match.group(2).strip().lower()
        except Exception as e_regex:
            print("Medical regex parsing failed:", str(e_regex))

        print("Extracted patient_name:", patient_name)
        print("Extracted disease:", disease)

        # ---- DevOps / tech tools from OCR ----
        for w in ocr_words:
            if w in tech_keywords:
                tech_tools.add(w)

        print("Detected tech tools:", list(tech_tools))

        # =====================================================================
        # 5) Build final label set (normalized, deduped, lowercase)
        # =====================================================================
        labels_set = set()

        # from Rekognition labels
        labels_set.update(general_labels)

        # from OCR tokens
        labels_set.update(ocr_words)

        # from brand detection
        labels_set.update(brand_tags)

        # from tech tool detection
        labels_set.update(tech_tools)

        # human presence
        if person_detected:
            labels_set.add("person_detected")

        # medical tags
        if patient_name:
            labels_set.add(f"patient:{patient_name}")
        if disease:
            labels_set.add(f"disease:{disease}")

        # dedup + sort for stable output
        labels_list = sorted(labels_set)
        print("Final labels list:", labels_list)

        # =====================================================================
        # 6) Smart Top Label selection (priority: disease > brand > tech > generic)
        # =====================================================================
        top_label = "unknown"

        if disease:
            top_label = f"disease:{disease}"
        elif brand_tags:
            top_label = sorted(brand_tags)[0]
        elif tech_tools:
            top_label = sorted(tech_tools)[0]
        elif general_labels:
            # Rekognition's most confident label is first in the response
            top_label = general_labels[0]
        elif ocr_words:
            top_label = ocr_words[0]

        print("Selected top label:", top_label)

        # =====================================================================
        # 7) Build image URL (assuming bucket is public or presigned elsewhere)
        # =====================================================================
        image_url = f"https://{bucket}.s3.amazonaws.com/{image_key}"

        # =====================================================================
        # 8) Persist to DynamoDB (schema unchanged)
        # =====================================================================
        item = {
            "ImageID": {"S": image_key},
            "Label": {"S": top_label},
            "Labels": {"L": [{"S": l} for l in labels_list]},
            "ImageUrl": {"S": image_url},
            "ObjectKey": {"S": image_key},
        }

        print(f"Putting item into DynamoDB table {TABLE_NAME}: {item}")
        dynamodb.put_item(TableName=TABLE_NAME, Item=item)

        return {
            "statusCode": 200,
            "body": json.dumps("Success: Universal image metadata stored.")
        }

    except Exception as e:
        # Catch-all so Lambda never crashes the invocation
        print("ERROR:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error: {str(e)}")
        }