import base64
import datetime
import json
import time
import boto3
import os
import base64
from uuid import uuid4 as uuid

KMS_KEY_ALIAS = os.environ['KMS_KEY_ALIAS']
KID = os.environ['KID']
ISSUER = os.environ['ISSUER']

# Remap incoming identity keys (keys) to new key names (values)
IDENTITY_REMAP_CONFIG = {
    "sourceIp": "sourceIp",
    "userArn": "userArn",
    "user":   "user",
    "accessKey": "accessKey",
    "accountId": "principalAccountId",
    "principalOrgId": "principalOrgId",
    # "user": "principalId"
    # "userArn": "principalArn"
}

session = boto3.session.Session()
client = session.client('kms')


def _jwt_kms_assemtric_encryption(jwt_head, jwt_payload):
    jwt_payload["iat"] = round(time.time())
    jwt_payload["exp"] = round(
        (datetime.datetime.now() + datetime.timedelta(hours=1)).timestamp())
    jwt_payload["nbf"] = jwt_payload["iat"]-1
    token_components = {
        "header":  base64.urlsafe_b64encode(json.dumps(jwt_head).encode()).decode().rstrip("="),
        "payload": base64.urlsafe_b64encode(json.dumps(jwt_payload).encode()).decode().rstrip("="),
    }
    message = f'{token_components.get("header")}.{token_components.get("payload")}'
    response = client.sign(
        KeyId=KMS_KEY_ALIAS,
        Message=message.encode(),
        MessageType="RAW",
        SigningAlgorithm="RSASSA_PKCS1_V1_5_SHA_256"
    )
    token_components["signature"] = base64.urlsafe_b64encode(
        response["Signature"]).decode().rstrip("=")
    return f'{token_components.get("header")}.{token_components.get("payload")}.{token_components["signature"]}'


def get_identity(event):
    identity = event['requestContext']['identity']
    identity_remapped = {}
    for k, v in identity.items():
        new_key = IDENTITY_REMAP_CONFIG.get(k)
        if not new_key:
            continue
        identity_remapped[new_key] = v
    identity_remapped['principalArn'] = remap_principal_arn(
        identity_remapped.get('userArn', ''))
    identity_remapped['principalId'] = remap_princiapl_id(
        identity_remapped.get('user', ''))
    return identity_remapped


def remap_princiapl_id(user):
    return user.split(':', 1)[0]


def remap_principal_arn(user_arn):
    user_arn_split = user_arn.split(':', 6)
    if len(user_arn_split) != 6:
        return ''
    elif user_arn_split[2] == 'sts':
        user_arn_split[2] = 'iam'
        role_split = user_arn_split[5].split('/')
        role_split[0] = 'role'
        del role_split[-1]
        user_arn_split[5] = '/'.join(role_split)
        return ':'.join(user_arn_split)
    elif user_arn_split[2] == 'iam':
        return 'IAM'
    else:
        return ''


def parse_body(event):
    body = event.get('body')
    if event.get('isBase64Encoded'):
        body = base64.b64decode(body)
    if not body:
        body = '{}'
    return json.loads(body)


def get_sub(identity, body):
    sub = None
    if body.get('sub'):
        sub = identity.get(body.get('sub'))
    if not sub:
        sub = identity.get("userArn")
    return sub


def lambda_handler(event, context):
    identity = get_identity(event)
    body = parse_body(event)

    aud = body.get('aud', 'aws-auth-jwt-exchange')
    sub = get_sub(identity, body)
    header = {
        "alg": "RS256",
        "typ": "JWT",
        "kid": KID
    }

    payload = {
        "iss": ISSUER,
        "sub": sub,
        "aud": aud,
        "jti": str(uuid()),
        "act": identity
        # iat, exp, nbf added during signing
    }
    jwt_encoded = _jwt_kms_assemtric_encryption(header, payload)
    return {
        "statusCode": 200,
        "body":  jwt_encoded
    }


if __name__ == "__main__":
    e = {
        "resource": "/",
        "path": "/",
        "httpMethod": "GET",
        "requestContext": {
            "identity": {
                "accountId": "123456789012",
                "sourceIp": "10.10.10.10",
                "principalOrgId": "o-xyz",
                "accessKey": "ASIAX",
                "userArn": "arn:aws:sts::123456789012:assumed-role/prefix/rolename/sessioname",
                "user":   "AROAX:sessioname",
                "caller": "AROAx:sessioname"
            }
        },
        "body": None,
        "isBase64Encoded": False
    }
    lambda_handler(e, '')
