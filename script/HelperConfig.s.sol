//SPDX-License-Identifier: MIT


// Applications- 1. Depoy mocks when we are on a local anvil chain
// 2. Keep track of contract address across different chains
// Eg- Sepolia ETH/USD and Mainnet ETH/USD will have diff addresses

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/mockV3Aggregator.sol";

contract HelperConfig is Script{
    //If we are on a local anvil, we deploy mocks
    // Otherwise, grab the existing address from the live network
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig{ //helps to get only the price feed and non other information
        address priceFeed; //ETH/USD priceFeed address
    }

    constructor(){
        if (block.chainid == 11155111){ //every network has a chain id
            activeNetworkConfig = getSepoliaEthConfig();
        }else if(block.chainid == 1){
            activeNetworkConfig = getMainnetEthConfig();
        }else{
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){ //will get config for everything we need in sepolia
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed : 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    } 

    function getMainnetEthConfig() public pure returns(NetworkConfig memory){ //will get config for everything we need in sepolia
        //price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed : 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
    } 

    
    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if(activeNetworkConfig.priceFeed != address(0)){ //If you have already deployed one you dont need to deploy more
            return activeNetworkConfig;
        }
        //price feed address

        // 1. Deploy the mocks
        // 2. Return the mock address

        vm.startBroadcast(); //this way we can deploy our mock contracts on the anvil chain
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
