#!/bin/bash

# Sui AMM Deployment Script
# This script deploys the Sui AMM contracts to the specified network

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Sui AMM Deployment Script ===${NC}"
echo ""

# Check if sui CLI is installed
if ! command -v sui &> /dev/null; then
    echo -e "${RED}Error: sui CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.sui.io/build/install"
    exit 1
fi

# Get network from argument or default to testnet
NETWORK=${1:-testnet}
echo -e "${YELLOW}Deploying to: ${NETWORK}${NC}"

# Change to contracts directory
cd "$(dirname "$0")/../contracts"

# Build the contracts
echo ""
echo -e "${GREEN}Building contracts...${NC}"
sui move build

# Check if build was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Deploy to network
echo ""
echo -e "${GREEN}Deploying to ${NETWORK}...${NC}"

# Set the network
if [ "$NETWORK" == "mainnet" ]; then
    echo -e "${RED}WARNING: You are deploying to MAINNET!${NC}"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    sui client switch --env mainnet
elif [ "$NETWORK" == "testnet" ]; then
    sui client switch --env testnet
elif [ "$NETWORK" == "devnet" ]; then
    sui client switch --env devnet
elif [ "$NETWORK" == "localnet" ]; then
    sui client switch --env localnet
else
    echo -e "${RED}Unknown network: ${NETWORK}${NC}"
    echo "Available networks: mainnet, testnet, devnet, localnet"
    exit 1
fi

# Publish the package
echo ""
echo -e "${GREEN}Publishing package...${NC}"
PUBLISH_OUTPUT=$(sui client publish --gas-budget 500000000 --json 2>&1)

# Check if publish was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Publish failed!${NC}"
    echo "$PUBLISH_OUTPUT"
    exit 1
fi

# Extract package ID from output
PACKAGE_ID=$(echo "$PUBLISH_OUTPUT" | grep -o '"packageId":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$PACKAGE_ID" ]; then
    echo -e "${RED}Failed to extract package ID${NC}"
    echo "$PUBLISH_OUTPUT"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Deployment Successful! ===${NC}"
echo ""
echo -e "Package ID: ${YELLOW}${PACKAGE_ID}${NC}"
echo ""

# Save deployment info
DEPLOY_INFO_FILE="../deployments/${NETWORK}_deployment.json"
mkdir -p ../deployments

cat > "$DEPLOY_INFO_FILE" << EOF
{
    "network": "${NETWORK}",
    "packageId": "${PACKAGE_ID}",
    "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "modules": [
        "constants",
        "errors",
        "events",
        "math",
        "lp_position_nft",
        "pool_factory",
        "stable_swap_pool",
        "fee_distributor",
        "slippage_protection",
        "demo_tokens"
    ]
}
EOF

echo -e "Deployment info saved to: ${YELLOW}${DEPLOY_INFO_FILE}${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Mint demo tokens: ./scripts/demo.sh mint-tokens"
echo "2. Create a pool: ./scripts/demo.sh create-pool"
echo "3. Add liquidity: ./scripts/demo.sh add-liquidity"
echo "4. Perform a swap: ./scripts/demo.sh swap"

