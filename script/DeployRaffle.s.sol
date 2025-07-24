// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script,console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interaction.s.sol";

contract DeployRaffle is Script {
    error NoSubscriptionId();


    function run() external {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();


        if (config.subscriptionId == 0) {
            revert NoSubscriptionId();

            /**These won't work, because when FundSubscription() be called, createSubscription()is still pending
             * thus the subId will be invalid 
            */
            // console2.log("No SubId, Getting SubId");
            // CreateSubscription createSubscription = new CreateSubscription();
            // (config.subscriptionId,config.vrfCoordinator) = createSubscription.createSubscriptionUsingConfig();
        
            // FundSubscription fundSubscription = new FundSubscription();
            // fundSubscription.fundSubscription(config.vrfCoordinator,config.subscriptionId, config.link, config.account);
            //fundSubscription.fundSubscriptionUsingConfig();
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.subscriptionId,
            config.gasLane,
            config.automationUpdateInterval,
            config.raffleEntranceFee,
            config.callbackGasLimit,
            config.vrfCoordinator
        );
        vm.stopBroadcast();
        console2.log("Contract Deployed. Address: ",address(raffle));
        AddConsumer addConsumer = new AddConsumer();
        //will broad in addConsumer
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);


        return (raffle, helperConfig);
    }
}
