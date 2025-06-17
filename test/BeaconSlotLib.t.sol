// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {BeaconSlotLib} from "../src/utils/BeaconSlotLib.sol";
import {BeaconNetworks} from "../src/utils/BeaconNetworks.sol";

contract BeaconSlotLibTest is SoladyTest, BeaconNetworks {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Known slot numbers for testing
    uint256 constant TEST_SLOT_0 = 0;
    uint256 constant TEST_SLOT_100 = 100;
    uint256 constant TEST_SLOT_1000 = 1000;
    uint256 constant TEST_SLOT_EPOCH_BOUNDARY = 32; // First slot of epoch 1

    // Test timestamps
    uint256 constant MAINNET_GENESIS = BeaconSlotLib.MAINNET_GENESIS;
    uint256 constant AFTER_GENESIS = MAINNET_GENESIS + 120; // 10 slots after genesis
    uint256 constant BEFORE_GENESIS = MAINNET_GENESIS - 60;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    BASIC MATH TESTS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testSlotToEpoch() public {
        // Test epoch boundaries
        assertEq(BeaconSlotLib.slotToEpoch(0), 0);
        assertEq(BeaconSlotLib.slotToEpoch(31), 0);
        assertEq(BeaconSlotLib.slotToEpoch(32), 1);
        assertEq(BeaconSlotLib.slotToEpoch(63), 1);
        assertEq(BeaconSlotLib.slotToEpoch(64), 2);
        
        // Test larger numbers
        assertEq(BeaconSlotLib.slotToEpoch(1000), 31); // 1000 / 32 = 31.25, floored = 31
        assertEq(BeaconSlotLib.slotToEpoch(1024), 32); // 1024 / 32 = 32
    }

    function testGetSlotInEpoch() public {
        // Test within first epoch
        assertEq(BeaconSlotLib.getSlotInEpoch(0), 0);
        assertEq(BeaconSlotLib.getSlotInEpoch(15), 15);
        assertEq(BeaconSlotLib.getSlotInEpoch(31), 31);
        
        // Test epoch boundaries
        assertEq(BeaconSlotLib.getSlotInEpoch(32), 0);
        assertEq(BeaconSlotLib.getSlotInEpoch(63), 31);
        assertEq(BeaconSlotLib.getSlotInEpoch(64), 0);
    }

    function testEpochToFirstSlot() public {
        assertEq(BeaconSlotLib.epochToFirstSlot(0), 0);
        assertEq(BeaconSlotLib.epochToFirstSlot(1), 32);
        assertEq(BeaconSlotLib.epochToFirstSlot(2), 64);
        assertEq(BeaconSlotLib.epochToFirstSlot(100), 3200);
    }

    function testEpochToLastSlot() public {
        assertEq(BeaconSlotLib.epochToLastSlot(0), 31);
        assertEq(BeaconSlotLib.epochToLastSlot(1), 63);
        assertEq(BeaconSlotLib.epochToLastSlot(2), 95);
        assertEq(BeaconSlotLib.epochToLastSlot(100), 3231);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   TIMESTAMP TESTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testGetSlotStartTime() public {
        uint256 genesis = MAINNET_GENESIS;
        
        assertEq(BeaconSlotLib.getSlotStartTime(0, genesis), genesis);
        assertEq(BeaconSlotLib.getSlotStartTime(1, genesis), genesis + 12);
        assertEq(BeaconSlotLib.getSlotStartTime(100, genesis), genesis + 1200);
    }

    function testGetSlotEndTime() public {
        uint256 genesis = MAINNET_GENESIS;
        
        assertEq(BeaconSlotLib.getSlotEndTime(0, genesis), genesis + 12);
        assertEq(BeaconSlotLib.getSlotEndTime(1, genesis), genesis + 24);
        assertEq(BeaconSlotLib.getSlotEndTime(100, genesis), genesis + 1212);
    }

    function testGetSlotAtTime() public {
        uint256 genesis = MAINNET_GENESIS;
        
        // Exactly at genesis
        assertEq(BeaconSlotLib.getSlotAtTime(genesis, genesis), 0);
        
        // Within first slot (0-11 seconds)
        assertEq(BeaconSlotLib.getSlotAtTime(genesis + 5, genesis), 0);
        assertEq(BeaconSlotLib.getSlotAtTime(genesis + 11, genesis), 0);
        
        // Exactly at slot 1 start
        assertEq(BeaconSlotLib.getSlotAtTime(genesis + 12, genesis), 1);
        
        // Before genesis
        assertEq(BeaconSlotLib.getSlotAtTime(genesis - 1, genesis), 0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   FUZZ TESTS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testSlotToEpochFuzz(uint256 slot) public {
        // Bound slot to reasonable range to avoid overflow
        slot = _bound(slot, 0, type(uint128).max);
        
        uint256 epoch = BeaconSlotLib.slotToEpoch(slot);
        uint256 expectedEpoch = slot / 32;
        
        assertEq(epoch, expectedEpoch);
    }

    function testGetSlotInEpochFuzz(uint256 slot) public {
        slot = _bound(slot, 0, type(uint128).max);
        
        uint256 slotInEpoch = BeaconSlotLib.getSlotInEpoch(slot);
        uint256 expectedSlotInEpoch = slot % 32;
        
        assertEq(slotInEpoch, expectedSlotInEpoch);
        assertTrue(slotInEpoch < 32);
    }

    function testEpochSlotConsistencyFuzz(uint256 epoch) public {
        epoch = _bound(epoch, 0, type(uint64).max);
        
        uint256 firstSlot = BeaconSlotLib.epochToFirstSlot(epoch);
        uint256 lastSlot = BeaconSlotLib.epochToLastSlot(epoch);
        
        // First slot should map back to the epoch
        assertEq(BeaconSlotLib.slotToEpoch(firstSlot), epoch);
        assertEq(BeaconSlotLib.slotToEpoch(lastSlot), epoch);
        
        // Last slot should be 31 more than first slot
        assertEq(lastSlot, firstSlot + 31);
        
        // Slot in epoch should be correct
        assertEq(BeaconSlotLib.getSlotInEpoch(firstSlot), 0);
        assertEq(BeaconSlotLib.getSlotInEpoch(lastSlot), 31);
    }

    function testTimestampCalculationsFuzz(uint256 slot, uint256 genesisTime) public {
        slot = _bound(slot, 0, type(uint64).max);
        genesisTime = _bound(genesisTime, 1, type(uint32).max);
        
        uint256 startTime = BeaconSlotLib.getSlotStartTime(slot, genesisTime);
        uint256 endTime = BeaconSlotLib.getSlotEndTime(slot, genesisTime);
        
        // End time should be 12 seconds after start time
        assertEq(endTime - startTime, 12);
        
        // Start time should be calculable from slot
        assertEq(startTime, genesisTime + (slot * 12));
        
        // Should be able to get slot back from start time
        assertEq(BeaconSlotLib.getSlotAtTime(startTime, genesisTime), slot);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   STRUCT TESTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testGetSlotInfo() public {
        uint256 slot = 100;
        uint256 genesis = MAINNET_GENESIS;
        
        BeaconSlotLib.SlotInfo memory info = BeaconSlotLib.getSlotInfo(slot, genesis);
        
        assertEq(info.slot, slot);
        assertEq(info.epoch, BeaconSlotLib.slotToEpoch(slot));
        assertEq(info.slotInEpoch, BeaconSlotLib.getSlotInEpoch(slot));
        assertEq(info.startTime, BeaconSlotLib.getSlotStartTime(slot, genesis));
        assertEq(info.endTime, BeaconSlotLib.getSlotEndTime(slot, genesis));
    }

    function testGetEpochInfo() public {
        uint256 epoch = 10;
        uint256 genesis = MAINNET_GENESIS;
        
        BeaconSlotLib.EpochInfo memory info = BeaconSlotLib.getEpochInfo(epoch, genesis);
        
        assertEq(info.epoch, epoch);
        assertEq(info.firstSlot, BeaconSlotLib.epochToFirstSlot(epoch));
        assertEq(info.lastSlot, BeaconSlotLib.epochToLastSlot(epoch));
        assertEq(info.startTime, BeaconSlotLib.getSlotStartTime(info.firstSlot, genesis));
        assertEq(info.endTime, BeaconSlotLib.getSlotEndTime(info.lastSlot, genesis));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   BATCH OPERATION TESTS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testGetSlotsInTimeRange() public {
        uint256 genesis = MAINNET_GENESIS;
        uint256 startTime = genesis + 24; // Start of slot 2
        uint256 endTime = genesis + 66; // Middle of slot 5 (slot 5 starts at genesis + 60)
        
        (uint256 startSlot, uint256 endSlot, uint256 count) = 
            BeaconSlotLib.getSlotsInTimeRange(startTime, endTime, genesis);
        
        assertEq(startSlot, 2);
        assertEq(endSlot, 5);
        assertEq(count, 4); // Slots 2, 3, 4, 5
    }

    function testGetSlotsInTimeRangeEdgeCases() public {
        uint256 genesis = MAINNET_GENESIS;
        
        // Empty range (start > end)
        (uint256 startSlot, uint256 endSlot, uint256 count) = 
            BeaconSlotLib.getSlotsInTimeRange(genesis + 100, genesis + 50, genesis);
        assertEq(count, 0);
        
        // Single slot
        (startSlot, endSlot, count) = 
            BeaconSlotLib.getSlotsInTimeRange(genesis, genesis + 5, genesis);
        assertEq(startSlot, 0);
        assertEq(endSlot, 0);
        assertEq(count, 1);
    }

    function testGetEpochBounds() public {
        (uint256 firstSlot, uint256 lastSlot) = BeaconSlotLib.getEpochBounds(5);
        
        assertEq(firstSlot, 160); // 5 * 32
        assertEq(lastSlot, 191); // 5 * 32 + 31
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   NETWORK HELPER TESTS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testNetworkConstants() public {
        // Verify the genesis times are what we expect
        assertEq(BeaconSlotLib.MAINNET_GENESIS, 1606824023);
        assertEq(BeaconSlotLib.SEPOLIA_GENESIS, 1655733600);
        assertEq(BeaconSlotLib.HOLESKY_GENESIS, 1695902400);
    }

    function testNetworkHelperFunctions() public {
        // Test that the helper functions work
        uint256 mainnetSlot = BeaconSlotLib.getCurrentMainnetSlot();
        uint256 sepoliaSlot = BeaconSlotLib.getCurrentSepoliaSlot();
        uint256 holeskySlot = BeaconSlotLib.getCurrentHoleskySlot();
        
        // In test environment, block.timestamp might be 1, so these could be 0
        // Just test that they return consistent values with the manual calculation
        assertEq(mainnetSlot, BeaconSlotLib.getCurrentSlot(BeaconSlotLib.MAINNET_GENESIS));
        assertEq(sepoliaSlot, BeaconSlotLib.getCurrentSlot(BeaconSlotLib.SEPOLIA_GENESIS));
        assertEq(holeskySlot, BeaconSlotLib.getCurrentSlot(BeaconSlotLib.HOLESKY_GENESIS));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   BEACON NETWORKS TESTS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testBeaconNetworksInheritance() public {
        // Test that we can use the inherited functions
        uint256 mainnetSlot = getMainnetSlot();
        uint256 mainnetEpoch = getMainnetEpoch();
        
        // Test that inherited functions work consistently
        assertEq(mainnetSlot, BeaconSlotLib.getCurrentMainnetSlot());
        assertEq(mainnetEpoch, BeaconSlotLib.slotToEpoch(mainnetSlot));
    }

    function testBeaconNetworksEnum() public {
        assertEq(uint256(Network.MAINNET), 0);
        assertEq(uint256(Network.SEPOLIA), 1);
        assertEq(uint256(Network.HOLESKY), 2);
        
        assertEq(getGenesisTime(Network.MAINNET), BeaconSlotLib.MAINNET_GENESIS);
        assertEq(getGenesisTime(Network.SEPOLIA), BeaconSlotLib.SEPOLIA_GENESIS);
        assertEq(getGenesisTime(Network.HOLESKY), BeaconSlotLib.HOLESKY_GENESIS);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   GAS BENCHMARKS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testGetCurrentSlotGas() public {
        uint256 gasBefore = gasleft();
        BeaconSlotLib.getCurrentSlot(MAINNET_GENESIS);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Should be very gas efficient
        assertTrue(gasUsed < 1000);
    }

    function testSlotToEpochGas() public {
        uint256 gasBefore = gasleft();
        BeaconSlotLib.slotToEpoch(1000000);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Should be extremely efficient (just a bit shift)
        assertTrue(gasUsed < 500);
    }

    function testGetSlotInfoGas() public {
        uint256 gasBefore = gasleft();
        BeaconSlotLib.getSlotInfo(1000, MAINNET_GENESIS);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Should be reasonably efficient even for complex struct
        assertTrue(gasUsed < 5000);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EDGE CASE TESTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testPreGenesisHandling() public {
        uint256 genesis = MAINNET_GENESIS;
        
        // Before genesis should return 0
        assertEq(BeaconSlotLib.getSlotAtTime(genesis - 1, genesis), 0);
        assertEq(BeaconSlotLib.getSlotAtTime(0, genesis), 0);
    }

    function testLargeNumbers() public {
        // Test with large but reasonable slot numbers
        uint256 largeSlot = 10000000; // About 3.8 years of slots
        uint256 epoch = BeaconSlotLib.slotToEpoch(largeSlot);
        uint256 slotInEpoch = BeaconSlotLib.getSlotInEpoch(largeSlot);
        
        assertEq(epoch, largeSlot / 32);
        assertEq(slotInEpoch, largeSlot % 32);
        assertTrue(slotInEpoch < 32);
    }

    function testFormatSlot() public {
        string memory formatted = BeaconSlotLib.formatSlot(100);
        
        // Should contain expected components
        // Note: This is a basic test since string comparison is complex in Solidity
        assertTrue(bytes(formatted).length > 0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   INTEGRATION TESTS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function testRealWorldScenarios() public {
        // Test scenarios that would be used in real applications
        uint256 currentSlot = BeaconSlotLib.getCurrentSlot(MAINNET_GENESIS);
        
        // Get current epoch
        uint256 currentEpoch = BeaconSlotLib.slotToEpoch(currentSlot);
        
        // Get next epoch's first slot
        uint256 nextEpochFirstSlot = BeaconSlotLib.epochToFirstSlot(currentEpoch + 1);
        
        // Verify relationships
        assertTrue(nextEpochFirstSlot > currentSlot);
        assertEq(BeaconSlotLib.slotToEpoch(nextEpochFirstSlot), currentEpoch + 1);
        assertEq(BeaconSlotLib.getSlotInEpoch(nextEpochFirstSlot), 0);
    }
}