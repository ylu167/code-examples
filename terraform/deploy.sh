#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}==============================${NC}"
echo -e "${GREEN}Terraform Deployment${NC}"
echo -e "${GREEN}==============================${NC}"
echo ""

if [ ! -f "variables.tf" ]; then
    echo -e "${RED}Error: Please run this script from the terraform/ directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: terraform not found. Please install Terraform.${NC}"
    exit 1
fi
echo -e "${GREEN}Terraform found: $(terraform version | head -n1)${NC}"

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud not found. Please install Google Cloud SDK.${NC}"
    exit 1
fi
echo -e "${GREEN}gcloud found${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found. Please install kubectl.${NC}"
    exit 1
fi
echo -e "${GREEN}kubectl found${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker not found. Please install Docker.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker found${NC}"

echo ""

PROJECT_ID=${1:-project-1}
echo -e "${YELLOW}Using GCP Project: ${PROJECT_ID}${NC}"

echo ""
read -p "This will deploy the entire infrastructure. Continue? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Setting GCP project...${NC}"
gcloud config set project $PROJECT_ID

echo ""
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

echo ""
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

if [ ! -f "terraform.tfvars" ]; then
    echo ""
    echo -e "${YELLOW}Creating terraform.tfvars...${NC}"
    cat > terraform.tfvars << EOF
project_id = "$PROJECT_ID"
region = "us-central1"
zone = "us-central1-a"
EOF
    echo -e "${GREEN}terraform.tfvars created${NC}"
fi

echo ""
echo -e "${YELLOW}Creating execution plan...${NC}"
terraform plan -out=tfplan

echo ""
read -p "Review the plan above. Apply these changes? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    rm -f tfplan
    exit 0
fi

echo ""
echo -e "${GREEN}Applying Terraform configuration...${NC}"
echo ""

terraform apply tfplan

rm -f tfplan

echo ""
terraform output
