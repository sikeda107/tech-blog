#!/bin/bash

# Script to generate Terraform backend configuration from template
# Usage: ./generate-backend.sh --bucket=<bucket> --prefix=<prefix> --project=<project> --environment=<env>

set -euo pipefail

# Default values
GCS_BUCKET="terraform-remote-backend"
TERRAFORM_PREFIX=""
GCP_PROJECT=""
ENVIRONMENT=""

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --bucket=*)
      GCS_BUCKET="${arg#*=}"
      shift
      ;;
    --prefix=*)
      TERRAFORM_PREFIX="${arg#*=}"
      shift
      ;;
    --project=*)
      GCP_PROJECT="${arg#*=}"
      shift
      ;;
    --environment=*)
      ENVIRONMENT="${arg#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 --bucket=<bucket> --prefix=<prefix> --project=<project> --environment=<env>"
      echo ""
      echo "Options:"
      echo "  --bucket=<bucket>           GCS bucket name for Terraform state"
      echo "  --prefix=<prefix>           Prefix path in GCS bucket"
      echo "  --project=<project>         GCP project ID"
      echo "  --environment=<env>         Environment name (e.g., dev, staging, prod)"
      echo "  --help                      Display this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$GCS_BUCKET" ]]; then
  echo "Error: --bucket is required"
  exit 1
fi

if [[ -z "$TERRAFORM_PREFIX" ]]; then
  echo "Error: --prefix is required"
  exit 1
fi

if [[ -z "$GCP_PROJECT" ]]; then
  echo "Error: --project is required"
  exit 1
fi

if [[ -z "$ENVIRONMENT" ]]; then
  echo "Error: --environment is required"
  exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/backend.template.tf"

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Error: Template file not found: $TEMPLATE_FILE"
  exit 1
fi

# Export variables for envsubst
export GCS_BUCKET
export TERRAFORM_PREFIX
export GCP_PROJECT
export ENVIRONMENT

# Generate Terraform configuration and output to stdout
envsubst < "$TEMPLATE_FILE"
