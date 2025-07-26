#To encrypt docker password- run this on terminal
#echo "your_password" | openssl enc -aes-256-cbc -a -salt -pbkdf2 -pass pass:MySecretKey  > docker_pass.enc
# nano .env    #add the MySecretKey
# DOCKER_SECRET_KEY=MySecretKey
# echo ".env" >> .gitignore   #add it to gitignore

#bash script name
#!/bin/bash

# -----------------------------------------------------------------------------
# Docker Image Deployment Script with Encrypted Password Support
# -----------------------------------------------------------------------------
# Requirements:
# - Encrypted Docker password stored in 'docker_pass.enc'
# - Secret key stored in $HOME/.env as DOCKER_SECRET_KEY
# - Openssl for encryption/decryption
# -----------------------------------------------------------------------------

# Load the encryption key from ~/.env
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "ERROR: Environment file $ENV_FILE not found."
    echo "Please create it with the line: DOCKER_SECRET_KEY=MySecretKey"
    exit 1
fi

# Check if the secret key is available
if [ -z "$DOCKER_SECRET_KEY" ]; then
    echo "ERROR: DOCKER_SECRET_KEY is not set in $ENV_FILE"
    exit 1
fi

# Configuration
DOCKER_USERNAME="ladymarg007"
REPO_NAME="cartservice"
IMAGE_TAG="latest"
IMAGE_NAME="$REPO_NAME"
ENCRYPTED_PASSWORD_FILE="$HOME/docker_pass.enc"

# Check if the encrypted password file exists
if [ ! -f "$ENCRYPTED_PASSWORD_FILE" ]; then
    echo "ERROR: Encrypted password file '$ENCRYPTED_PASSWORD_FILE' not found."
    exit 1
fi

# Decrypt the Docker password
echo "Decrypting Docker password..."
DOCKER_PASSWORD=$(openssl enc -aes-256-cbc -a -d -salt -pbkdf2 \
    -pass pass:"$DOCKER_SECRET_KEY" -in "$ENCRYPTED_PASSWORD_FILE")

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to decrypt Docker password. Check your secret key."
    exit 1
fi

# Log in to Docker Hub
echo "Logging into Docker Hub..."
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

if [ $? -ne 0 ]; then
    echo "ERROR: Docker login failed."
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

# # Check if the Docker Hub repository exists
# echo "Checking if repository '$REPO_NAME' exists on Docker Hub..."
# REPO_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
#     "https://hub.docker.com/v2/repositories/$DOCKER_USERNAME/$REPO_NAME/")

# if [ "$REPO_CHECK" -eq 404 ]; then
#     echo "Repository does not exist. Creating it on Docker Hub..."
#     curl -s -X POST "https://hub.docker.com/v2/repositories/" \
#         -H "Content-Type: application/json" \
#         -u "$DOCKER_USERNAME:$DOCKER_PASSWORD" \
#         -d "{\"name\": \"$REPO_NAME\", \"is_private\": false}"
# else
#     echo "Repository already exists."
# fi

# Tag the Docker image for Docker Hub
echo "Tagging image..."
docker tag "$IMAGE_NAME:$IMAGE_TAG" "$DOCKER_USERNAME/$REPO_NAME:$IMAGE_TAG"

# Push the Docker image to Docker Hub
echo "Pushing image to Docker Hub..."
docker push "$DOCKER_USERNAME/$REPO_NAME:$IMAGE_TAG"

# Done
echo "Deployment complete. Image available at: $DOCKER_USERNAME/$REPO_NAME:$IMAGE_TAG"
