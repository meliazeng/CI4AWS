#!/usr/bin/env bash
echo -n "Enter ToolsAccount > "
read ToolsAccount
echo -n "Enter ToolsAccount ProfileName for AWS Cli operations> "
read ToolsAccountProfile
echo -n "Enter Test Account > "
read TestAccount
echo -n "Enter TestAccount ProfileName for AWS Cli operations> "
read TestAccountProfile
echo -n "Enter Prod Account > "
read ProdAccount
echo -n "Enter ProdAccount ProfileName for AWS Cli operations> "
read ProdAccountProfile
echo -n "Enter Github access Token> "
read GithubToken

aws cloudformation deploy --stack-name pre-reqs --template-file ToolsAcct/pre-reqs.yaml --parameter-overrides TestAccount=$TestAccount ProductionAccount=$ProdAccount --profile $ToolsAccountProfile --
echo -n "Enter S3 Bucket created from above > "
read S3Bucket

echo -n "Enter CMK ARN created from above > "
read CMKArn

echo -n "Executing in TEST Account"
aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role --template-file TestAccount/toolsacct-codepipeline-cloudformation-deployer.yaml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ToolsAccount=$ToolsAccount CMKARN=$CMKArn  S3Bucket=$S3Bucket --profile $TestAccountProfile

echo -n "Executing in PROD Account"
aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role --template-file TestAccount/toolsacct-codepipeline-cloudformation-deployer.yaml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ToolsAccount=$ToolsAccount CMKARN=$CMKArn  S3Bucket=$S3Bucket --profile $ProdAccountProfile


echo -n "Creating Pipeline in Tools Account"
aws cloudformation deploy --stack-name profound-pipeline --template-file ToolsAcct/code-pipeline.yaml --parameter-overrides GithubToken=$GithubToken S3CIBucket=bucket4ci TestAccount=$TestAccount ProductionAccount=$ProdAccount CMKARN=$CMKArn S3Bucket=$S3Bucket --capabilities CAPABILITY_NAMED_IAM --profile $ToolsAccountProfile

echo -n "Adding Permissions to the CMK"
aws cloudformation deploy --stack-name pre-reqs --template-file ToolsAcct/pre-reqs.yaml --parameter-overrides CodeBuildCondition=true --profile $ToolsAccountProfile

echo -n "Executing in TEST Account for S3 policy"
aws cloudformation deploy --stack-name toolsacct-S3-policy --template-file TestAccount/apply-s3-policy-after-pipeline-role.yaml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ToolsAccount=$ToolsAccount S3BucketWebsite=bucketwebsite123 --profile $TestAccountProfile

echo -n "Executing in PROD Account for S3 policy"
aws cloudformation deploy --stack-name toolsacct-S3-policy --template-file TestAccount/apply-s3-policy-after-pipeline-role.yaml --capabilities CAPABILITY_NAMED_IAM --parameter-overrides ToolsAccount=$ToolsAccount S3BucketWebsite=bucketwebsite321 --profile $ProdAccountProfile

echo -n "Adding Permissions to the Cross Accounts"
aws cloudformation deploy --stack-name profound-pipeline --template-file ToolsAcct/code-pipeline.yaml --parameter-overrides CrossAccountCondition=true --capabilities CAPABILITY_NAMED_IAM --profile $ToolsAccountProfile