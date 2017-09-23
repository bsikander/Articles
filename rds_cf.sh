#!/bin/bash

echo 'NOTE: This script assumes that aws cli is configured already. To configure use "aws configure" command'

echo "Reading config file!"
source rds_cf.config

if [ -z "$S3_BUCKET" ]; then
  echo "[ERROR] S3 bucket not provided!"
  exit 1
fi

if [[ "$S3_BUCKET" =~ "s3://" ]]; then
  echo ""
else
  echo "[ERROR] S3 bucket should be of format s3://<bucket name>"
  exit 1
fi

function createStack() {
  aws s3 cp $3.json $1 --quiet
  S3_DB_JSON_FILE_URL=$(aws s3 presign $1/$3.json)

  SHORT_DB_NAME=$(echo $3 | cut -c1-3)
  DB_INSTANCE_ID=$SHORT_DB_NAME$RANDOM

  aws cloudformation \
    --region $AWS_REGION \
    create-stack \
      --stack-name $2 \
      --template-url $S3_DB_JSON_FILE_URL \
      --parameters ParameterKey=DBNameParameter,ParameterValue=$4 \
                   ParameterKey=MasterUsernameParameter,ParameterValue=$5 \
                   ParameterKey=MasterPasswordParameter,ParameterValue=$6 \
                   ParameterKey=DBInstanceIdentifierParameter,ParameterValue=$DB_INSTANCE_ID \
                   ParameterKey=TagCreatedByParameter,ParameterValue=$7 \
                   ParameterKey=TagPurposeParameter,ParameterValue=$8 \
                   ParameterKey=TagApplicationIDParameter,ParameterValue=$9 \
                   ParameterKey=TagUsageParameter,ParameterValue=${10}
}

PS3="
Select your choice: "
options=("Create RDS DB using CF" "List All Stacks" "Delete Stack" "Import Dump File" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Create RDS DB using CF")
          echo "Possible DB names -> postgres, mysql, oracle-ee, mariadb"
          read -p 'DB type: ' DB_TYPE
          if [ $DB_TYPE == "mysql" ] || [ $DB_TYPE == "postgres" ] || [ $DB_TYPE == "oracle-ee" ] || [ $DB_TYPE == "mariadb" ]; then

            read -p 'DB NAME: (alphanumeric characters AND less than 9 characters): ' DB_NAME
            read -p 'CloudFormation Stack name: ' STACK_NAME

            if [ $DB_TYPE == "mysql" ]; then
              read -p 'Username: (Donot use "mysql", it is a reserved word) ' USERNAME
            else
              read -p 'Username: ' USERNAME
            fi

            read -sp 'Password: (Should be 8 characters long) ' PASSWORD
            printf "\n"

            read -p 'Tag: CreatedBy => ' CREATED_BY
            read -p 'Tag: Purpose => ' PURPOSE
            read -p 'Tag: ApplicationID => ' APPLICATION_ID
            read -p 'Tag: Usage => ' USAGE

            printf "\n"
            createStack $S3_BUCKET $STACK_NAME $DB_TYPE $DB_NAME $USERNAME $PASSWORD $CREATED_BY $PURPOSE $APPLICATION_ID $USAGE

            printf "\n"
          else
            echo "Wrong DB name. Possible options are postgres, mysql, oracle-ee, mariadb"
          fi
          ;;
        "List All Stacks")
          aws --region $AWS_REGION cloudformation list-stacks
          printf "\n"
          ;;
        "Delete Stack")
          read -p 'Stack name: ' STACK_NAME
          printf "\n"
          aws --region $AWS_REGION cloudformation delete-stack --stack-name $STACK_NAME
          echo "Deletion of $STACK_NAME in progress!"

          printf "\n"
          ;;
        "Import Dump File")
          echo "Possible DB names -> postgres"
          read -p 'DB type: ' DB_TYPE
          if [ $DB_TYPE == "postgres" ]; then
            read -p 'RDS Instance URL: ' RDS_INSTANCE_URL
            read -p 'Backup DB Name: ' BACKUP_DB_NAME
            read -p 'Username: ' USER
            read -p 'Dump File Absolute Path: ' DUMP_FILE

            NOW=$(date +"%Y%m%d-%I%M")
            # https://www.postgresql.org/docs/9.6/static/app-pgrestore.html
            $POSTGRES_BIN_DIRECTORY/pg_restore \
              -h $RDS_INSTANCE_URL \
              -p $POSTGRES_DEFAULT_PORT \
              -U $USER \
              -d $BACKUP_DB_NAME \
              -W \
              -v $DUMP_FILE
          else
            echo "Wrong DB name. Possible options are postgres"
          fi
        ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
