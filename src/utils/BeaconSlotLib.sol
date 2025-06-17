// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for Ethereum beacon chain slot calculations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/BeaconSlotLib.sol)
/// @dev
/// This library provides gas-optimized functions for calculating Ethereum beacon chain
/// slot numbers, epochs, and timing information. All functions are pure or view and
/// designed to work with any beacon chain network by accepting genesis time as a parameter.
library BeaconSlotLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Seconds per slot in the beacon chain.
    uint256 internal constant SECONDS_PER_SLOT = 12;

    /// @dev Number of slots per epoch.
    uint256 internal constant SLOTS_PER_EPOCH = 32;

    /// @dev Seconds per epoch (12 * 32).
    uint256 internal constant SECONDS_PER_EPOCH = 384;

    /// @dev Attestation deadline within a slot (4 seconds).
    uint256 internal constant ATTESTATION_DEADLINE = 4;

    // Network genesis times (Unix timestamps)

    /// @dev Mainnet genesis time: December 1, 2020, 12:00:23 PM UTC.
    uint256 internal constant MAINNET_GENESIS = 1606824023;

    /// @dev Goerli testnet genesis time: March 23, 2021, 2:00:00 PM UTC.
    uint256 internal constant GOERLI_GENESIS = 1616508000;

    /// @dev Sepolia testnet genesis time: June 20, 2022, 2:00:00 PM UTC.
    uint256 internal constant SEPOLIA_GENESIS = 1655733600;

    /// @dev Holesky testnet genesis time: September 28, 2023, 12:00:00 PM UTC.
    uint256 internal constant HOLESKY_GENESIS = 1695902400;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The slot number is invalid.
    error InvalidSlot();

    /// @dev The epoch number is invalid.
    error InvalidEpoch();

    /// @dev The genesis time is invalid.
    error InvalidGenesisTime();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Comprehensive information about a beacon chain slot.
    struct SlotInfo {
        uint256 slot;
        uint256 epoch;
        uint256 slotInEpoch;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool inAttestationWindow;
    }

    /// @dev Information about a beacon chain epoch.
    struct EpochInfo {
        uint256 epoch;
        uint256 firstSlot;
        uint256 lastSlot;
        uint256 startTime;
        uint256 endTime;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     CORE CALCULATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current beacon chain slot based on block timestamp.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return slot The current slot number, or 0 if before genesis.
    function getCurrentSlot(uint256 genesisTime) internal view returns (uint256 slot) {
        /// @solidity memory-safe-assembly
        assembly {
            let ts := timestamp()
            let isAfterGenesis := gt(ts, genesisTime)
            let secondsSince := mul(isAfterGenesis, sub(ts, genesisTime))
            slot := div(secondsSince, SECONDS_PER_SLOT)
        }
    }

    /// @dev Returns the slot number at a specific timestamp.
    /// @param queryTime The timestamp to query.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return slot The slot number at the given timestamp, or 0 if before genesis.
    function getSlotAtTime(uint256 queryTime, uint256 genesisTime) internal pure returns (uint256 slot) {
        /// @solidity memory-safe-assembly
        assembly {
            let isAfterGenesis := gt(queryTime, genesisTime)
            let secondsSince := mul(isAfterGenesis, sub(queryTime, genesisTime))
            slot := div(secondsSince, SECONDS_PER_SLOT)
        }
    }

    /// @dev Returns the start timestamp of a given slot.
    /// @param slot The slot number.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return startTime The timestamp when the slot starts.
    function getSlotStartTime(uint256 slot, uint256 genesisTime) internal pure returns (uint256 startTime) {
        unchecked {
            startTime = genesisTime + (slot * SECONDS_PER_SLOT);
        }
    }

    /// @dev Returns the end timestamp of a given slot.
    /// @param slot The slot number.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return endTime The timestamp when the slot ends.
    function getSlotEndTime(uint256 slot, uint256 genesisTime) internal pure returns (uint256 endTime) {
        unchecked {
            endTime = genesisTime + ((slot + 1) * SECONDS_PER_SLOT);
        }
    }

    /// @dev Converts a slot number to its epoch number.
    /// @param slot The slot number.
    /// @return epoch The epoch number containing the slot.
    function slotToEpoch(uint256 slot) internal pure returns (uint256 epoch) {
        /// @solidity memory-safe-assembly
        assembly {
            // Use bit shifting since SLOTS_PER_EPOCH = 32 = 2^5
            epoch := shr(5, slot)
        }
    }

    /// @dev Returns the position of a slot within its epoch (0-31).
    /// @param slot The slot number.
    /// @return slotInEpoch The position within the epoch.
    function getSlotInEpoch(uint256 slot) internal pure returns (uint256 slotInEpoch) {
        /// @solidity memory-safe-assembly
        assembly {
            // Use bitwise AND since SLOTS_PER_EPOCH = 32, mask = 31
            slotInEpoch := and(slot, 31)
        }
    }

    /// @dev Returns the first slot number of a given epoch.
    /// @param epoch The epoch number.
    /// @return firstSlot The first slot number in the epoch.
    function epochToFirstSlot(uint256 epoch) internal pure returns (uint256 firstSlot) {
        /// @solidity memory-safe-assembly
        assembly {
            // Use bit shifting since SLOTS_PER_EPOCH = 32 = 2^5
            firstSlot := shl(5, epoch)
        }
    }

    /// @dev Returns the last slot number of a given epoch.
    /// @param epoch The epoch number.
    /// @return lastSlot The last slot number in the epoch.
    function epochToLastSlot(uint256 epoch) internal pure returns (uint256 lastSlot) {
        unchecked {
            lastSlot = epochToFirstSlot(epoch) + SLOTS_PER_EPOCH - 1;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    TIMING CALCULATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the time until a slot starts (negative if already started).
    /// @param slot The slot number.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return secondsUntil Seconds until slot starts (negative if in the past).
    function getTimeUntilSlot(uint256 slot, uint256 genesisTime) internal view returns (int256 secondsUntil) {
        uint256 slotStartTime = getSlotStartTime(slot, genesisTime);
        unchecked {
            secondsUntil = int256(slotStartTime) - int256(block.timestamp);
        }
    }

    /// @dev Checks if a slot is currently active.
    /// @param slot The slot number.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return active True if the slot is currently active.
    function isSlotActive(uint256 slot, uint256 genesisTime) internal view returns (bool active) {
        uint256 startTime = getSlotStartTime(slot, genesisTime);
        uint256 endTime = getSlotEndTime(slot, genesisTime);
        active = block.timestamp >= startTime && block.timestamp < endTime;
    }

    /// @dev Checks if we're within the attestation window for a slot (0-4 seconds).
    /// @param slot The slot number.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return inWindow True if within the attestation window.
    function isInAttestationWindow(uint256 slot, uint256 genesisTime) internal view returns (bool inWindow) {
        uint256 startTime = getSlotStartTime(slot, genesisTime);
        uint256 timeSinceStart = block.timestamp >= startTime ? block.timestamp - startTime : 0;
        inWindow = timeSinceStart <= ATTESTATION_DEADLINE;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   INFORMATION QUERIES                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns comprehensive information about a slot.
    /// @param slot The slot number.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return info Detailed information about the slot.
    function getSlotInfo(uint256 slot, uint256 genesisTime) internal view returns (SlotInfo memory info) {
        info.slot = slot;
        info.epoch = slotToEpoch(slot);
        info.slotInEpoch = getSlotInEpoch(slot);
        info.startTime = getSlotStartTime(slot, genesisTime);
        info.endTime = getSlotEndTime(slot, genesisTime);
        info.isActive = isSlotActive(slot, genesisTime);
        info.inAttestationWindow = info.isActive && isInAttestationWindow(slot, genesisTime);
    }

    /// @dev Returns information about an epoch.
    /// @param epoch The epoch number.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return info Detailed information about the epoch.
    function getEpochInfo(uint256 epoch, uint256 genesisTime) internal pure returns (EpochInfo memory info) {
        info.epoch = epoch;
        info.firstSlot = epochToFirstSlot(epoch);
        info.lastSlot = epochToLastSlot(epoch);
        info.startTime = getSlotStartTime(info.firstSlot, genesisTime);
        info.endTime = getSlotEndTime(info.lastSlot, genesisTime);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    BATCH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the range of slots that occur within a time period.
    /// @param startTime The start timestamp.
    /// @param endTime The end timestamp.
    /// @param genesisTime The genesis timestamp for the target network.
    /// @return startSlot The first slot in the range.
    /// @return endSlot The last slot in the range.
    /// @return count The number of slots in the range.
    function getSlotsInTimeRange(uint256 startTime, uint256 endTime, uint256 genesisTime)
        internal
        pure
        returns (uint256 startSlot, uint256 endSlot, uint256 count)
    {
        if (startTime > endTime) {
            return (0, 0, 0);
        }
        
        startSlot = getSlotAtTime(startTime, genesisTime);
        endSlot = getSlotAtTime(endTime, genesisTime);
        
        // Handle case where endTime is exactly at slot boundary
        if (endTime == getSlotStartTime(endSlot, genesisTime) && endSlot > 0) {
            endSlot -= 1;
        }
        
        count = endSlot >= startSlot ? endSlot - startSlot + 1 : 0;
    }

    /// @dev Returns the first and last slot numbers for an epoch.
    /// @param epoch The epoch number.
    /// @return firstSlot The first slot in the epoch.
    /// @return lastSlot The last slot in the epoch.
    function getEpochBounds(uint256 epoch) internal pure returns (uint256 firstSlot, uint256 lastSlot) {
        firstSlot = epochToFirstSlot(epoch);
        lastSlot = epochToLastSlot(epoch);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   NETWORK UTILITIES                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current slot for Ethereum mainnet.
    /// @return slot The current mainnet slot.
    function getCurrentMainnetSlot() internal view returns (uint256 slot) {
        slot = getCurrentSlot(MAINNET_GENESIS);
    }

    /// @dev Returns the current slot for Sepolia testnet.
    /// @return slot The current Sepolia slot.
    function getCurrentSepoliaSlot() internal view returns (uint256 slot) {
        slot = getCurrentSlot(SEPOLIA_GENESIS);
    }

    /// @dev Returns the current slot for Holesky testnet.
    /// @return slot The current Holesky slot.
    function getCurrentHoleskySlot() internal view returns (uint256 slot) {
        slot = getCurrentSlot(HOLESKY_GENESIS);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    HELPER FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Formats a slot number with epoch information.
    /// @param slot The slot number.
    /// @return formatted A string representation of the slot and epoch.
    /// @dev Note: This function is provided for convenience but may be gas-expensive.
    /// Consider using LibString.toString() directly if you need just the number.
    function formatSlot(uint256 slot) internal pure returns (string memory formatted) {
        // For production use, import LibString and use LibString.toString()
        // This is a simplified implementation for demonstration
        uint256 epoch = slotToEpoch(slot);
        uint256 slotInEpoch = getSlotInEpoch(slot);
        
        formatted = string(abi.encodePacked(
            "Slot ", _toString(slot),
            " (Epoch ", _toString(epoch),
            ", Slot ", _toString(slotInEpoch), "/31)"
        ));
    }

    /// @dev Simple internal toString function.
    /// @dev For production, use LibString.toString() instead.
    function _toString(uint256 value) private pure returns (string memory str) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        str = string(buffer);
    }
}