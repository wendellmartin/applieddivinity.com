#!/bin/bash
source ./utils.sh

DEPLOY_ENV=${1:-dev}
VERSION=${2}
NAME=$(get_repository_name)

if DEPLOY_ENV == "candidate" 
then
  NAME="$NAME-CANDIDATE"
else
  if [ -z "$VERSION" ]; then
    NAME="$NAME-$(get_version)"
  else
    NAME="$NAME-$VERSION"
  fi
fi

FILENAME="$NAME.zip"
echo "Creating artifact: $FILENAME"
create_artifact "$FILENAME"

# Download artifact 
wget -qO artifact.zip "$VERSION"

# Deploy logic (replace with cPanel API calls)
if [ "$DEPLOY_ENV" = "prod" ]; then
  # Prod deployment steps here
  echo "Deploying $VERSION to PROD..."
else
  echo "Deploying $VERSION to DEV..."
fi

# Add error handling/revert logic here if needed