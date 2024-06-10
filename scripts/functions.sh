#!/bin/bash
# Send a notification to the Discord server
send_notification() {
    # Local variables
    local icon="$1"
    local title="$2"
    local description="$3"
    local color="$4"

    # Create a message
    MESSAGE="{\"content\": \"\", \"embeds\":[
        {
            \"title\": \"$icon\u2002\u2002$title\u2002\u2002$icon\",
            \"description\": \"$description\",
            \"color\": $color
        }
    ]}"

    # Send the notification
    curl -X POST -H "Content-type: application/json" -d "$MESSAGE" "$DISCORD_URL"
}


# Start notification
start_notification() {
    # Get the current time
    CURRENT_TIME=$(date +%s)
    START_TIME=$((CURRENT_TIME + 3600))

    # Send the notification
    send_notification "☑️" "**Start CI/CD pipeline**" "Time: *$(date -d "@$START_TIME" +"%T")*\nTriggered by: *$CI_PIPELINE_SOURCE*\nJob: *$CI_JOB_NAME*\n\nJob URL:\n*$CI_JOB_URL*" 255
}

# End notification
end_notification() {
    # Get the current time
    CURRENT_TIME=$(date +%s)
    END_TIME=$((CURRENT_TIME + 3600))

    # Send the notification
    send_notification "☑️" "**End CI/CD pipeline**" "Time: *$(date -d "@$END_TIME" +"%T")*\nJob: *$CI_JOB_NAME*\n\nJob URL:\n*$CI_JOB_URL*" 255
}

# Terraform operations
terraform_operation() {
    # Local variable
    local action="$1"

    # Run Terraform operation -> Send notification accordingly 
    if gitlab-terraform "$action"; then
        send_notification "✅" "**Terraform $action**" "Terraform $action was successful!\nEnvironment: *$CI_ENVIRONMENT_NAME*\nJob: *$CI_JOB_NAME*\n\nJob URL:\n*$CI_JOB_URL*" 65280
    else
        send_notification "⛔" "**Terraform $action**" "Terraform $action has failed!\nEnvironment: *$CI_ENVIRONMENT_NAME*\nJob: *$CI_JOB_NAME*\n\nJob URL:\n*$CI_JOB_URL*" 16711680
        exit 1
    fi
}

# Check if the AWS credentials are valid
check_credentials(){
    # Check -> Credentials empty -> Send notification accordingly 
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_DEFAULT_REGION" ]; then
        send_notification "⛔" "**AWS Credentials**" "AWS Credentials are missing. Please insert your credentials\n\nJob URL:\n*$CI_JOB_URL*" 16711680
        exit 1 # Stop the pipeline
    else
        # Setup a profile with the credentials
        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
        aws configure set default.region $AWS_DEFAULT_REGION
        
        # Check -> Credentials valid -> Send notification accordingly 
        if aws sts get-caller-identity; then
            send_notification "✅" "**AWS Credentials**" "AWS Credentials are valid.  \n\nJob URL:\n*$CI_JOB_URL*" 65280
        else
            send_notification "⛔" "**AWS Credentials**" "AWS Credentials are invalid. Please update your credentials!\n\nJob URL:\n*$CI_JOB_URL*" 16711680
            exit 1 # Stop the pipeline
        fi
    fi
}

### Update the CI variables ###
update_variables(){
    # update variables on Infrastructure reposistory
    # ECR
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ECR_NAME" --form "value=$(jq -r .ecr_name.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ECR_URL" --form "value=$(jq -r .ecr_url.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null

    # ECS
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ECS_NAME_EAST" --form "value=$(jq -r .ecs_name_east.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ECS_NAME_WEST" --form "value=$(jq -r .ecs_name_west.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ECS_SERVICE_NAME_EAST" --form "value=$(jq -r .ecs_service_name_east.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ECS_SERVICE_NAME_WEST" --form "value=$(jq -r .ecs_service_name_west.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null 

    # RDS
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_RDS_ID" --form "value=$(jq -r .rds_id.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_RDS_NAME" --form "value=$(jq -r .rds_name.value outputs.json)" --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_RDS_ENDPOINT" --form "value=$(jq -r .rds_endpoint.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null

    # ALB
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ALB_DNS_NAME_EAST" --form "value=$(jq -r .alb_dns_name_east.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ALB_DNS_NAME_WEST" --form "value=$(jq -r .alb_dns_name_west.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ALB_ID_EAST" --form "value=$(jq -r .alb_arn_east.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/OUTPUT_ALB_ID_WEST" --form "value=$(jq -r .alb_arn_west.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    

    # update variables on Developer reposistory
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_DEVELOPER" "$REPOSITORY_URL_DEVELOPER/variables/DB_HOST" --form "value=$(jq -r .rds_endpoint.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_DEVELOPER" "$REPOSITORY_URL_DEVELOPER/variables/DB_NAME" --form "value=$(jq -r .rds_name.value outputs.json)"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null 
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_DEVELOPER" "$REPOSITORY_URL_DEVELOPER/variables/DB_PASSWD" --form "value=$TF_VAR_rds_password"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_DEVELOPER" "$REPOSITORY_URL_DEVELOPER/variables/DB_USER" --form "value=$TF_VAR_rds_username"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME"  > /dev/null

    # Check if updates were successful
    if [ $? -eq 0 ]; then
        send_notification "✅" "**Update variables**" "Updated the CI variables to the latest values.\n\nJob URL:\n*$CI_JOB_URL*" 65280
    else
        send_notification "⛔" "**Update variables**" "Failed to update the CI variables to the latest values.\n\nJob URL:\n*$CI_JOB_URL*" 16711680   
    fi

}

# Push a docker image to the AWS registry (ECR)
push_docker_image(){
    # Login to the registry
    docker login -u $READ_REGISTRY_USERNAME -p $ACCESS_TOKEN_DEVELOPER $DEVELOPER_REGISTRY

    # Check -> Pull was succesfull
    if docker pull $DEVELOPER_REGISTRY:$IMAGE_TAG; then
        # Login to ECR
        aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $OUTPUT_ECR_URL

        # Tag and push to ECR
        docker tag $DEVELOPER_REGISTRY:$IMAGE_TAG $OUTPUT_ECR_URL:latest
        docker push $OUTPUT_ECR_URL:latest

        # Up the desired count so ECS start working
        # EAST 
        aws ecs update-service --cluster $OUTPUT_ECS_NAME_EAST --service $OUTPUT_ECS_SERVICE_NAME_EAST --desired-count 2

        # WEST
        aws ecs update-service --cluster $OUTPUT_ECS_NAME_WEST --service $OUTPUT_ECS_SERVICE_NAME_WEST --desired-count 2 --region us-west-2

        # Send notificationn
        send_notification "✅" "**Docker Image**" "The latest docker image is pushed to the AWS ECR!" 65280
    else
        # Trigger developer pipeline -> Build a docker image
        curl -X POST  -F token=$TRIGGER_TOKEN -F ref=$BRANCH_DEV $TRIGGER_URL > /dev/null

        # Send notificationn
        send_notification "☑️" "**Docker Image**" "No Dockerfile in the repository, but the developer pipeline's on it. Check back in 10 min for the results." 255
        exit 1 # Stop the pipeline
    fi
}

# Send a notification about SAST report
sast_notification(){
    # Find the highest severity
    highest_severity=$(jq -r '.vulnerabilities[0].severity' gl-sast-report.json)
    
    # Check -> Highest severity -> Generate fitting output
    case "$highest_severity" in
        "Critical" )
            icon="⛔"
            message="Critical vulnerability found!"
            color=16711680 
            ;;
        "High")
            icon="🟠"
            message="High severity vulnerability found."
            color=16753920 
            ;;
        "Medium" | "low")
            icon="⚠️"
            message="Medium or low severity vulnerabilities found."
            color=16776960    
            ;;
        "Info" | "Unknown")
            icon="☑️"
            message="Informational or unknown severity."
            color=255 
            ;;
        *)  
            icon="✅"
            message="No vulnerabilities found."
            color=65280 
            ;;
    esac

    # Send notificatio
    send_notification $icon "**SAST**" "$message \n\n Find the full report about vulnerabilities: \n*$CI_PIPELINE_URL/security*" $color
}

# TEST AWS SERVICES
aws_tests(){
    # Local Variables
    report="**AWS Services:**\n\n"

    # Execute the tests -> Build report allong the way
    # ECR
    report+="**ECR**\n"
    aws_ecr_test $OUTPUT_ECR_NAME
    report+="- $ecr_message\n\n"

    # ECS 
    report+="**ECS**\n"
    aws_ecs_test $OUTPUT_ECS_NAME_EAST us-east-1
    report+="- $ecs_message\n"
    aws_ecs_test $OUTPUT_ECS_NAME_WEST us-west-2
    report+="- $ecs_message\n\n"

    # ALB
    report+="**ALB**\n"
    aws_lb_test $OUTPUT_ALB_ID_EAST us-east-1 "Loadbalancer in East"
    report+="- $lb_message\n"
    aws_lb_test $OUTPUT_ALB_ID_WEST us-west-2 "Loadbalancer in West"
    report+="- $lb_message\n\n"

    # RDS
    report+="**RDS**\n"
    aws_rds_test
    report+="- $rds_message\n\n"\

    # Wait 2 minutes
    sleep 60 
 
    # Website
    report+="**WEBSITE**\n"
    website_test $OUTPUT_ALB_DNS_NAME_EAST  "Website on East"
    report+="- $website_message\n"
    website_test $OUTPUT_ALB_DNS_NAME_WEST "Website on West"
    report+="- $website_message\n\n"

    # Links
    report+="**Links**\n"
    report+="http://$OUTPUT_ALB_DNS_NAME_EAST\n"
    report+="http://$OUTPUT_ALB_DNS_NAME_WEST"

    # Send notification
    send_notification "☑️" "**Testing Services**" "$report" 255
}

# Testing ECR
aws_ecr_test(){
    # Check if ECR exists -> Generate a fitting output
    if aws ecr describe-repositories --repository-names $1 --region $AWS_DEFAULT_REGION; then
        ecr_message="*$1*: up and running"
    else
        ecr_message="*$1*: currently not running"
    fi
}

# Testing ECS
aws_ecs_test(){
    # Check if ECS is active -> Generate a fitting output
    if [ $(aws ecs describe-clusters --clusters $1 --region $2 --query clusters[0].status --output text) == "ACTIVE" ] ; then
        ecs_message="*$1*: is up and running"
    else
        ecs_message="*$1*: currently not running or available"
    fi
}

# Testing ALB
aws_lb_test(){
    local STATUS=$(aws elbv2 describe-load-balancers --load-balancer-arns $1 --region $2 --query LoadBalancers[0].State.Code --output text)
    # Check if ALB is active -> Generate a fitting output
    if [ $STATUS == "active" ] ; then
        lb_message="*$3*: is up and running!"
    else
        lb_message="*$lb_name*: currently not running or available"
    fi
}

# Teting RDS
aws_rds_test(){
    # Check if RDS is available -> Generate a fitting output
    if aws rds describe-db-instances --db-instance-identifier $OUTPUT_RDS_ID; then
        rds_message="*$OUTPUT_RDS_NAME*: up and running"
    else
        rds_message="*$OUTPUT_RDS_NAME*: currently not running or available"
    fi
}

# Testing websites
website_test(){
    # Check if you can visit the application -> Generate a fitting output
    if [ "$(curl -s -o /dev/null -w "%{http_code}" $1)" == "200" ]; then
        website_message="*$2*: is available"
    else
        website_message="*$2*: is not available"
    fi
}

# Delete the EC2 instance that was used to setup the database -> prevent it from running again
cleanup_ec2(){
    # Destroy the instance
    gitlab-terraform destroy -target="aws_instance.instance"

    # Change CI variable to false
    curl --request PUT --header "PRIVATE-TOKEN: $ACCESS_TOKEN_INFRASTRUCTURE" "$REPOSITORY_URL_INFRASTRUCTURE/variables/TF_VAR_ec2_count" --form "value=0"  --form "filter[environment_scope]=$CI_ENVIRONMENT_NAME" > /dev/null

    # Check if EC2 cleanup was successful
    if [ $? -eq 0 ]; then
        send_notification "✅" "**EC2 Cleanup**" "The EC2 that was used to setup the database is successfully destroyed and will not be used again.\n\nJob URL:\n*$CI_JOB_URL*" 65280
    else
        send_notification "⛔" "**EC2 Cleanup**" "Failed to cleanup the EC2.\n\nJob URL:\n*$CI_JOB_URL*" 16711680   
    fi

}

# Destroy all resources
terraform_destroy(){
    # File with modules
    resource_file="./scripts/modules.txt"

    # Loop through files and delete resource
    while IFS= read -r resource_name; do
        echo "Destroying resource: $resource_name"
        gitlab-terraform destroy -target="$resource_name"
    done < "$resource_file"

    # Check if the destroy was successful
    if [ $? -eq 0 ]; then
        send_notification "✅" "**Destroy Successful**" "All resources except the data was deleted.\n\nJob URL:\n*$CI_JOB_URL*" 65280
    else
        send_notification "⛔" "**Destroy Failed**" "Failed to destroy all resources except the data.\n\nJob URL:\n*$CI_JOB_URL*" 16711680   
    fi

    exit 1 # Stop the pipeline
}