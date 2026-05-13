#!/bin/bash
set -eo pipefail

# Get current version from VERSION file
get_version() {
  cat VERSION
}

# Get the repository name from something available inside the github action execution environment
get_full_repository() {
  echo "$GITHUB_REPOSITORY"
}

# Get the repsitory name from the full repository name
get_repository_name() {
  local full_repo=$(get_full_repository)
  echo "${full_repo##*/}"
}

# Get the organization name from the full repository name
get_organization() {
  local full_repo=$(get_full_repository)
  echo "${full_repo%%/*}"
}

# Update version file and commit
update_version() {
  local new_version=$1
  
  git pull

  echo "$new_version" > VERSION
  
  git config --local user.email "action@github.com"
  git config --local user.name "GitHub Action"
  

  git add VERSION
  git commit -m "Bump version to $new_version [skip ci]" || echo "No changes to commit"

  # Use the token directly in the push command
  # We use HEAD to push the current commit to the triggering branch
  git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" HEAD
  
  echo "NEW_VERSION=$new_version" >> "$GITHUB_OUTPUT"
}

# Create GitHub Release Tag
create_tag() {
  local version=$1
  local tag_name="v$version"
  
  git pull
  git tag -a "$tag_name" -m "Release $version"
  
  # Push the specific tag using the token
  git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$tag_name"
  
  echo "TAG=$tag_name" >> "$GITHUB_OUTPUT"
}
# Create Artifact
create_artifact() {
  local filename=$1
  (cd src/web && zip -r "../../$filename" .)
  echo "::artifact name=$filename::$filename created."
}

get_artifact_name() {
  local env=$1
  local name=$(get_repository_name)
  if [[ "$env" == "candidate" ]]  
  then
    name="$name-CANDIDATE"
  else
    name="$name-$(get_version)"
  fi
  echo "$name.zip"
}

upload_artifact() {
  local filename=$1
  local target=$2
  local username=$3
  local token=$4
  local cPanelUrl=$5
  
  local filemanURI="execute/Fileman/upload_files"
  #local filemanURI="execute/DomainInfo/list_domains"

  # echo "user: $username" |  sed 's/./& /g'
  # echo "target: $target" |  sed 's/./& /g'
  # echo "filename: $filename" |  sed 's/./& /g'
  # echo "token: $token" |  sed 's/./& /g'
  # echo "cPanelUrl: $cPanelUrl" |  sed 's/./& /g'
  # echo "input 1: $1" |  sed 's/./& /g'
  # echo "Uploading artifact: $filename to $cPanelUrl:$target via url: $cPanelUrl/$filemanURI"
  curl -v -L \
          -H "Authorization: cpanel $username:$token" \
          -H "Accept: application/json" \
          -F "dir=$target" \
          -F "file-1=@$filename" \
          "$cPanelUrl/$filemanURI"
}

unzip_server_artifact() {
  local filename=$1
  local source=$2
  local target=$3
  local username=$4
  local token=$5
  local cPanelUrl=$6

  local unzipURI="json-api/cpanel"

  echo "filename: $filename" |  sed 's/./& /g'
  echo "source: $source" |  sed 's/./& /g'
  echo "target: $target" |  sed 's/./& /g'
  echo "user: $username" |  sed 's/./& /g'
  echo "cPanelUrl: $cPanelUrl" |  sed 's/./& /g'


  echo "Unzipping artifact: $filename on $cPanelUrl from $source to $target via url: $cPanelUrl/$unzipURI"
  curl -v -L \
          -H "Authorization: cpanel $username:$token" \
          -d "cpanel_jsonapi_apiversion=2" \
          -d "cpanel_jsonapi_module=Fileman" \
          -d "cpanel_jsonapi_func=fileop" \
          -d "op=extract" \
          -d "sourcefiles=$source/$filename" \
          -d "destfiles=$target" \
          -d "doubledecode=1" \
          "$cPanelUrl/$unzipURI"
}

remove_server_item() {
  local target=$1
  local username=$CPANEL_USERNAME
  local token=$CPANEL_PASSWORD
  local cPanelUrl=$CPANEL_URL

  local removeURI="json-api/cpanel"

  echo "Removing item $target on $cPanelUrl"
  curl -v -L \
          -H "Authorization: cpanel $username:$token" \
          -d "cpanel_jsonapi_apiversion=2" \
          -d "cpanel_jsonapi_module=Fileman" \
          -d "cpanel_jsonapi_func=fileop" \
          -d "op=unlink" \
          -d "sourcefiles=$target" \
          "$cPanelUrl/$removeURI"
}

remove_server_deployment() {
  
  local env=$1

  artifact_name=$(get_artifact_name "$env")

  echo "Removing server deployment for $env environment, artifact: $DEPLOY_TEMP_DIR/$artifact_name"
  remove_server_item "$DEPLOY_TEMP_DIR/$artifact_name"

  local home_dir=""
  if [[ "$env" == "candidate" ]]
  then
    home_dir="$CPANEL_CANDIDATE_HOME"
  elif [[ "$env" == "dev" ]]
  then
    home_dir="$CPANEL_DEV_HOME"
  elif [[ "$env" == "prod" ]]
  then
    home_dir="$CPANEL_PROD_HOME"
  else
    echo "Invalid environment: $env. Use candidate/dev."
    exit 1
  fi  

  echo "Removing server deployment for $env environment, home directory: $home_dir"
  remove_server_item "$home_dir"
}
