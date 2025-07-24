// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/Script.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interaction.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract InteractionTest  is  Test, CodeConstants{

    /**event */
     event SubscriptionFunded(uint256 indexed subId, uint256 oldBalance, uint256 newBalance);

    function setUp() public{

    }

    function testCreateSubscriptionAndGetSubID() public {
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subId, ) = createSubscription.createSubscriptionUsingConfig();

        assert(subId != 0);

    }

    // function testFundSubscriptionAndGetSubId() public{
    //     HelperConfig helperConfig = new HelperConfig();
    //     uint256 subId = helperConfig.getConfig().subscriptionId;
        

    //     FundSubscription fundSubscription = new FundSubscription();
        

    //     vm.expectEmit(true, false, false, false, address(fundSubscription));
    //     emit SubscriptionFunded(subId, 0, 0 + 1 ether);

    //     fundSubscription.fundSubscriptionUsingConfig();
    // }

    function testFundSubscriptionAndGetSubId() public {
    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig  memory config = helperConfig.getConfig();

    FundSubscription fundSubscription = new FundSubscription();

    vm.recordLogs();
    fundSubscription.fundSubscriptionUsingConfig();
    Vm.Log[] memory logs = vm.getRecordedLogs();

    bool found = false;
    
    for (uint i = 0; i < logs.length; i++) {
        if (logs[i].topics.length > 0 && logs[i].topics[0] == keccak256("SubscriptionFunded(uint256,uint256,uint256)")) {
            found = true;
            break;
        }
    }

    assertTrue(found, "Expected SubscriptionFunded event not emitted");
    }
}