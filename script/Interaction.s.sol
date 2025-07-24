// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script , CodeConstants{

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        return createSubscription(vrfCoordinator, account);
         
    }

    function createSubscription(
        address vrfCoordinator, address account
    ) public returns (uint256, address) {
        vm.startBroadcast(account);
        //both loacl test net and sepolia(also mainnet) can use it to fund subscription
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        console2.log("Subscription ID:", subscriptionId);
        vm.stopBroadcast();
        return (subscriptionId, vrfCoordinator);
    }
    function run() external {
        createSubscriptionUsingConfig();
    }
}


contract FundSubscription is Script, CodeConstants{

    uint256 public constant FUND_AMOUNT = 15 ether; //15 Link

    function  fundSubscriptionUsingConfig()public {
         
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
   
    }

    function  fundSubscription(address vrfCoordinator,uint256 subscriptionId, address linkToken, address account)public  {
        console2.log("Funding subscription: ", subscriptionId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);
        if(block.chainid ==  LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT 
            );
            console2.log("Subscription funded with ",FUND_AMOUNT);
            vm.stopBroadcast();    
        }else{
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            console2.log("Sepolia Subscription funded with ",FUND_AMOUNT);
            vm.stopBroadcast();
        }
       
    }
    function run() external {
        fundSubscriptionUsingConfig();
    }
}


contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account );
    }
    
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console2.log("Adding consumer contract: ", contractToAddToVrf);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }
 
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}