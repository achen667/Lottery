// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/Script.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinator;
    address account;
    LinkToken link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 1000 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    /*event*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        automationUpdateInterval = config.automationUpdateInterval;
        raffleEntranceFee = config.raffleEntranceFee;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinator = config.vrfCoordinator;
        link = LinkToken(config.link); // Cast the Address into the Interface or Contract
        account = config.account;

        vm.startPrank(msg.sender);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(msg.sender, LINK_BALANCE);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, LINK_BALANCE);
        }
        link.approve(vrfCoordinator, LINK_BALANCE);
        vm.stopPrank();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitialization() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWithNoEnoughEntrance() public {
        //arrange
        vm.prank(PLAYER);

        //act
        vm.expectRevert(Raffle.Raffle__NotEnoughEntranceFee.selector);
        raffle.enterRaffle();
        //assert
    }

    function testRaffleRecordedWhenPlayerEnter() public {
        //arrange
        vm.prank(PLAYER);

        //act
        raffle.enterRaffle{value: raffleEntranceFee}();
        //assert

        address playerAddr = raffle.getPlaerAddress(0);
        assert(playerAddr == PLAYER);
    }

    function testEnterRaffleEventEmitted() public {
        //arrange
        vm.prank(PLAYER);

        //act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        //assert
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    function testDontLetPlayerEnterRaffleWhileCalculating() public {
        //arrange
        //isOpen
        //hasPlayers/hasBalance
        raffle.enterRaffle{value: raffleEntranceFee}();
        //timePassed
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        //act/assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    /*checkUpkeep*/
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public raffleEntered {
        // Arrange
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatedAndEmitRequestId() public raffleEntered {
        //Arrange
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        console2.log("requestId");
        console2.logBytes32(requestId);
        //Assert
        Raffle.RaffleState rState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }
    //fuzz testing

    function testFulfillRandomWordsCanOnlyBeCalledByPerformUpkeep(uint256 randomRequestId)
        public
        raffleEntered
        skipFork
    {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandowWordsPicksAWinnerThenResetAndSendMoney() public raffleEntered skipFork {
        //arrange
        uint256 addtionalPlayerAmount = 3; //total 4 players
        uint256 startingIndex = 1;
        address expectWinner = address(1);

        for (uint256 index = startingIndex; index < startingIndex + addtionalPlayerAmount; index++) {
            address newPlayer = address(uint160(index));
            hoax(newPlayer, 2 ether);
            raffle.enterRaffle{value: raffleEntranceFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 expectWinnerStartingBalance = expectWinner.balance;

        //act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState rafflestate = raffle.getRaffleState();

        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = raffleEntranceFee * (addtionalPlayerAmount + 1); // 1 player entranced in modifier

        assert(recentWinner == expectWinner);
        assert(uint256(rafflestate) == 0); //OPEN
        console2.log(
            "winnerBalance == expectWinnerStartingBalance + prize ", winnerBalance, expectWinnerStartingBalance, prize
        );
        console2.log(expectWinnerStartingBalance + prize);
        assert(winnerBalance == expectWinnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
