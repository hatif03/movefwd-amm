#!/bin/bash

# Sui AMM Demo Script
# Interactive demo for the Sui AMM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load deployment info
SCRIPT_DIR="$(dirname "$0")"
NETWORK=${NETWORK:-testnet}
DEPLOY_FILE="${SCRIPT_DIR}/../deployments/${NETWORK}_deployment.json"

if [ ! -f "$DEPLOY_FILE" ]; then
    echo -e "${RED}Error: Deployment file not found: ${DEPLOY_FILE}${NC}"
    echo "Please run ./scripts/deploy.sh first"
    exit 1
fi

PACKAGE_ID=$(cat "$DEPLOY_FILE" | grep -o '"packageId":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}=== Sui AMM Demo ===${NC}"
echo -e "Network: ${YELLOW}${NETWORK}${NC}"
echo -e "Package: ${YELLOW}${PACKAGE_ID}${NC}"
echo ""

# Function to display menu
show_menu() {
    echo -e "${BLUE}Available commands:${NC}"
    echo "  1. mint-tokens     - Mint demo tokens to your address"
    echo "  2. create-pool     - Create a new liquidity pool"
    echo "  3. add-liquidity   - Add liquidity to an existing pool"
    echo "  4. remove-liquidity - Remove liquidity from a pool"
    echo "  5. swap            - Swap tokens"
    echo "  6. view-pool       - View pool information"
    echo "  7. view-position   - View your LP position"
    echo "  8. claim-fees      - Claim accumulated fees"
    echo "  9. help            - Show this menu"
    echo "  0. exit            - Exit demo"
    echo ""
}

# Function to get user's address
get_address() {
    sui client active-address
}

# Function to mint demo tokens
mint_tokens() {
    echo -e "${GREEN}Minting demo tokens...${NC}"
    
    ADDRESS=$(get_address)
    echo -e "Recipient: ${YELLOW}${ADDRESS}${NC}"
    
    # Get treasury caps (you'll need to replace these with actual object IDs after deployment)
    echo ""
    echo -e "${YELLOW}Note: You need the TreasuryCap object IDs to mint tokens.${NC}"
    echo "These are created during deployment and transferred to the deployer."
    echo ""
    
    read -p "Enter USDC TreasuryCap ID: " USDC_TREASURY
    read -p "Enter amount to mint (in smallest units): " AMOUNT
    
    if [ -n "$USDC_TREASURY" ] && [ -n "$AMOUNT" ]; then
        echo "Minting ${AMOUNT} DEMO_USDC..."
        sui client call \
            --package "$PACKAGE_ID" \
            --module demo_tokens \
            --function mint_usdc \
            --args "$USDC_TREASURY" "$AMOUNT" "$ADDRESS" \
            --gas-budget 10000000
    fi
}

# Function to create a pool
create_pool() {
    echo -e "${GREEN}Creating a new liquidity pool...${NC}"
    echo ""
    
    read -p "Enter Coin A object ID: " COIN_A
    read -p "Enter Coin B object ID: " COIN_B
    read -p "Enter fee tier (5=0.05%, 30=0.3%, 100=1%): " FEE_TIER
    read -p "Enter Clock object ID (0x6 for shared clock): " CLOCK
    
    CLOCK=${CLOCK:-0x6}
    
    # Get factory object ID
    read -p "Enter PoolFactory object ID: " FACTORY
    
    if [ -n "$COIN_A" ] && [ -n "$COIN_B" ] && [ -n "$FEE_TIER" ] && [ -n "$FACTORY" ]; then
        echo ""
        echo "Creating pool with fee tier: ${FEE_TIER} basis points"
        
        # Note: This is a simplified example. Actual type arguments depend on your coin types.
        echo -e "${YELLOW}Note: You need to specify the exact coin types in the call.${NC}"
        echo "Example command:"
        echo ""
        echo "sui client call \\"
        echo "    --package $PACKAGE_ID \\"
        echo "    --module pool_factory \\"
        echo "    --function create_pool \\"
        echo "    --type-args '<CoinA_Type>' '<CoinB_Type>' \\"
        echo "    --args $FACTORY $COIN_A $COIN_B $FEE_TIER $CLOCK \\"
        echo "    --gas-budget 50000000"
    fi
}

# Function to add liquidity
add_liquidity() {
    echo -e "${GREEN}Adding liquidity to a pool...${NC}"
    echo ""
    
    read -p "Enter Pool object ID: " POOL
    read -p "Enter Coin A object ID: " COIN_A
    read -p "Enter Coin B object ID: " COIN_B
    read -p "Enter minimum LP tokens (for slippage protection): " MIN_LP
    read -p "Enter Clock object ID (0x6): " CLOCK
    
    CLOCK=${CLOCK:-0x6}
    MIN_LP=${MIN_LP:-1}
    
    if [ -n "$POOL" ] && [ -n "$COIN_A" ] && [ -n "$COIN_B" ]; then
        echo ""
        echo "Example command:"
        echo ""
        echo "sui client call \\"
        echo "    --package $PACKAGE_ID \\"
        echo "    --module pool_factory \\"
        echo "    --function add_liquidity \\"
        echo "    --type-args '<CoinA_Type>' '<CoinB_Type>' \\"
        echo "    --args $POOL $COIN_A $COIN_B $MIN_LP $CLOCK \\"
        echo "    --gas-budget 50000000"
    fi
}

# Function to swap tokens
swap_tokens() {
    echo -e "${GREEN}Swapping tokens...${NC}"
    echo ""
    
    read -p "Enter Pool object ID: " POOL
    read -p "Swap direction (1=A->B, 2=B->A): " DIRECTION
    read -p "Enter input Coin object ID: " COIN_IN
    read -p "Enter minimum output amount: " MIN_OUT
    
    MIN_OUT=${MIN_OUT:-0}
    
    if [ -n "$POOL" ] && [ -n "$COIN_IN" ]; then
        FUNCTION="swap_a_for_b"
        if [ "$DIRECTION" == "2" ]; then
            FUNCTION="swap_b_for_a"
        fi
        
        echo ""
        echo "Example command:"
        echo ""
        echo "sui client call \\"
        echo "    --package $PACKAGE_ID \\"
        echo "    --module pool_factory \\"
        echo "    --function $FUNCTION \\"
        echo "    --type-args '<CoinA_Type>' '<CoinB_Type>' \\"
        echo "    --args $POOL $COIN_IN $MIN_OUT \\"
        echo "    --gas-budget 50000000"
    fi
}

# Function to view pool info
view_pool() {
    echo -e "${GREEN}Viewing pool information...${NC}"
    echo ""
    
    read -p "Enter Pool object ID: " POOL
    
    if [ -n "$POOL" ]; then
        echo ""
        sui client object "$POOL" --json
    fi
}

# Function to view LP position
view_position() {
    echo -e "${GREEN}Viewing LP position...${NC}"
    echo ""
    
    read -p "Enter LPPositionNFT object ID: " POSITION
    
    if [ -n "$POSITION" ]; then
        echo ""
        sui client object "$POSITION" --json
    fi
}

# Function to remove liquidity
remove_liquidity() {
    echo -e "${GREEN}Removing liquidity from a pool...${NC}"
    echo ""
    
    read -p "Enter Pool object ID: " POOL
    read -p "Enter LPPositionNFT object ID: " POSITION
    read -p "Enter LP tokens to remove: " LP_TOKENS
    read -p "Enter minimum amount A: " MIN_A
    read -p "Enter minimum amount B: " MIN_B
    read -p "Enter Clock object ID (0x6): " CLOCK
    
    CLOCK=${CLOCK:-0x6}
    MIN_A=${MIN_A:-1}
    MIN_B=${MIN_B:-1}
    
    if [ -n "$POOL" ] && [ -n "$POSITION" ] && [ -n "$LP_TOKENS" ]; then
        echo ""
        echo "Example command:"
        echo ""
        echo "sui client call \\"
        echo "    --package $PACKAGE_ID \\"
        echo "    --module pool_factory \\"
        echo "    --function remove_liquidity \\"
        echo "    --type-args '<CoinA_Type>' '<CoinB_Type>' \\"
        echo "    --args $POOL $POSITION $LP_TOKENS $MIN_A $MIN_B $CLOCK \\"
        echo "    --gas-budget 50000000"
    fi
}

# Main command handler
case "${1:-menu}" in
    mint-tokens|1)
        mint_tokens
        ;;
    create-pool|2)
        create_pool
        ;;
    add-liquidity|3)
        add_liquidity
        ;;
    remove-liquidity|4)
        remove_liquidity
        ;;
    swap|5)
        swap_tokens
        ;;
    view-pool|6)
        view_pool
        ;;
    view-position|7)
        view_position
        ;;
    claim-fees|8)
        echo -e "${YELLOW}Fee claiming is done through the fee_distributor module.${NC}"
        echo "See documentation for details."
        ;;
    help|9)
        show_menu
        ;;
    exit|0)
        echo "Goodbye!"
        exit 0
        ;;
    menu|*)
        show_menu
        
        # Interactive mode
        while true; do
            read -p "Enter command (or 'help'): " cmd
            case "$cmd" in
                1|mint-tokens) mint_tokens ;;
                2|create-pool) create_pool ;;
                3|add-liquidity) add_liquidity ;;
                4|remove-liquidity) remove_liquidity ;;
                5|swap) swap_tokens ;;
                6|view-pool) view_pool ;;
                7|view-position) view_position ;;
                8|claim-fees) echo "See fee_distributor module" ;;
                9|help) show_menu ;;
                0|exit|quit|q) echo "Goodbye!"; exit 0 ;;
                *) echo -e "${RED}Unknown command: $cmd${NC}"; show_menu ;;
            esac
            echo ""
        done
        ;;
esac

