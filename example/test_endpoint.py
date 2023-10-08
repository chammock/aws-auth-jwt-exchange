import requests
from aws_requests_auth.boto_utils import BotoAWSRequestsAuth

host = "aws-auth-jwt-exchange.chammock.cloud"

auth = BotoAWSRequestsAuth(aws_host=host,
                           aws_region='us-east-1',
                           aws_service='execute-api')

response = requests.post(f'https://{host}', auth=auth)
print(response.text)
