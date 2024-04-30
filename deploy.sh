#!/bin/bash

role_name="urltomarkdown-lambda-role"
function_name="urltomarkdown"

# Create role that will be given to lambda
output=$(aws iam create-role --role-name $role_name --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}')

role_arn=$(echo $output | jq -r '.Role' | jq -r '.Arn')

# Attach basic execution policy to role
aws iam attach-role-policy --role-name $role_name --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

# Zip the lambda code. Make sure to include node_modules, package.json, package-lock.json
zip -r urltomarkdown.zip .

# Create the function
aws lambda create-function --function-name $function_name \
--runtime nodejs20.x --handler index.handler \
--role $role_arn \
--zip-file fileb://urltomarkdown.zip \
--region us-east-1

# Create a test body
payload='{"queryStringParameters":{"url":"https://playgrounds.network"},"requestContext":{"identity":{"sourceIp":"207.253.217.242"}}}'

# Base64 encode the body
base64_payload=$(echo -n $payload | base64)

# Test the function. Make sure your AWS credentials are stored in the client terminal.
aws lambda invoke --function-name $function_name --payload "$base64_payload" --region us-east-1 outfile
