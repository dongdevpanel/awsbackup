#!/bin/bash

BACKUP_VAULT="neuva-backup-vault"
BACKUP_PLAN_NAME="neuva-backup-plan"

# AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
echo AWS Account: $AWS_ACCOUNT_ID

# TEST, you should change to your region
aws configure set region ap-southeast-1   

# AWS Region
AWS_REGION=$(aws configure get region)
echo Region: $AWS_REGION

# EFS ARN
#FS_ID=$(aws efs describe-file-systems | grep FileSystemId | awk '{print $2}' | cut -d'"' -f 2)
#EFS_ARN=arn:aws:elasticfilesystem:$AWS_REGION:$AWS_ACCOUNT_ID:file-system/$FS_ID
#echo EFS: $EFS_ARN

# DB Instance ARN
#RDS_ARN=$(aws rds describe-db-instances | grep DBInstanceArn | awk '{print $2}' | cut -d'"' -f 2)
#echo RDS: $RDS_ARN

# Servie Role for AWS Backup
SERVICE_ROLE=arn:aws:iam::$AWS_ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole
echo Service Role: $SERVICE_ROLE

# Create Backup Vault
aws backup create-backup-vault --backup-vault-name $BACKUP_VAULT --backup-vault-tags Name=$BACKUP_VAULT
echo Backup Vault: $BACKUP_VAULT

# Create Backup plan
BACKUP_PLAN_ID=$(aws backup create-backup-plan --cli-input-json file://backup.json | grep BackupPlanId | awk '{print $2}' | cut -d'"' -f 2)
echo Backup Plan ID: $BACKUP_PLAN_ID

# Backup Resource Selection: RDS
RDS_ARN=$(aws rds describe-db-instances | grep DBInstanceArn | awk '{print $2}' | cut -d'"' -f 2)
for rds in $RDS_ARN
do
	aws backup create-backup-selection --backup-plan-id $BACKUP_PLAN_ID --backup-selection SelectionName=rds,IamRoleArn=$SERVICE_ROLE,Resources=$rds
done

# Backup Resource Selection: EFS
FS_ID=$(aws efs describe-file-systems | grep FileSystemId | awk '{print $2}' | cut -d'"' -f 2)
for efs in $FS_ID
do
	EFS_ARN=arn:aws:elasticfilesystem:$AWS_REGION:$AWS_ACCOUNT_ID:file-system/$efs
	echo EFS: $efs
	aws backup create-backup-selection --backup-plan-id $BACKUP_PLAN_ID --backup-selection SelectionName=efs,IamRoleArn=$SERVICE_ROLE,Resources=$EFS_ARN
done





