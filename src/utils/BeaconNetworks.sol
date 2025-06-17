// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BeaconSlotLib} from "./BeaconSlotLib.sol";

/// @notice Helper contract providing easy access to beacon chain calculations for specific networks.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/BeaconNetworks.sol)
/// @dev
/// This contract provides convenience functions for common networks, eliminating the need
/// to pass genesis times manually. Inherit from this contract to get easy access to
/// beacon chain timing for all supported networks.
abstract contract BeaconNetworks {
    using BeaconSlotLib for uint256;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    MAINNET FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current slot on Ethereum mainnet.
    function getMainnetSlot() internal view returns (uint256) {
        return BeaconSlotLib.getCurrentSlot(BeaconSlotLib.MAINNET_GENESIS);
    }

    /// @dev Returns the current epoch on Ethereum mainnet.
    function getMainnetEpoch() internal view returns (uint256) {
        return BeaconSlotLib.slotToEpoch(getMainnetSlot());
    }

    /// @dev Returns detailed information about the current mainnet slot.
    function getMainnetSlotInfo() internal view returns (BeaconSlotLib.SlotInfo memory) {
        return BeaconSlotLib.getSlotInfo(getMainnetSlot(), BeaconSlotLib.MAINNET_GENESIS);
    }

    /// @dev Checks if we're within the attestation window on mainnet.
    function isMainnetAttestationWindow() internal view returns (bool) {
        return BeaconSlotLib.isInAttestationWindow(getMainnetSlot(), BeaconSlotLib.MAINNET_GENESIS);
    }

    /// @dev Returns the mainnet slot at a specific timestamp.
    function getMainnetSlotAtTime(uint256 timestamp) internal pure returns (uint256) {
        return BeaconSlotLib.getSlotAtTime(timestamp, BeaconSlotLib.MAINNET_GENESIS);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    SEPOLIA FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current slot on Sepolia testnet.
    function getSepoliaSlot() internal view returns (uint256) {
        return BeaconSlotLib.getCurrentSlot(BeaconSlotLib.SEPOLIA_GENESIS);
    }

    /// @dev Returns the current epoch on Sepolia testnet.
    function getSepoliaEpoch() internal view returns (uint256) {
        return BeaconSlotLib.slotToEpoch(getSepoliaSlot());
    }

    /// @dev Returns detailed information about the current Sepolia slot.
    function getSepoliaSlotInfo() internal view returns (BeaconSlotLib.SlotInfo memory) {
        return BeaconSlotLib.getSlotInfo(getSepoliaSlot(), BeaconSlotLib.SEPOLIA_GENESIS);
    }

    /// @dev Returns the Sepolia slot at a specific timestamp.
    function getSepoliaSlotAtTime(uint256 timestamp) internal pure returns (uint256) {
        return BeaconSlotLib.getSlotAtTime(timestamp, BeaconSlotLib.SEPOLIA_GENESIS);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    HOLESKY FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current slot on Holesky testnet.
    function getHoleskySlot() internal view returns (uint256) {
        return BeaconSlotLib.getCurrentSlot(BeaconSlotLib.HOLESKY_GENESIS);
    }

    /// @dev Returns the current epoch on Holesky testnet.
    function getHoleskyEpoch() internal view returns (uint256) {
        return BeaconSlotLib.slotToEpoch(getHoleskySlot());
    }

    /// @dev Returns detailed information about the current Holesky slot.
    function getHoleskySlotInfo() internal view returns (BeaconSlotLib.SlotInfo memory) {
        return BeaconSlotLib.getSlotInfo(getHoleskySlot(), BeaconSlotLib.HOLESKY_GENESIS);
    }

    /// @dev Returns the Holesky slot at a specific timestamp.
    function getHoleskySlotAtTime(uint256 timestamp) internal pure returns (uint256) {
        return BeaconSlotLib.getSlotAtTime(timestamp, BeaconSlotLib.HOLESKY_GENESIS);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   CROSS-NETWORK UTILITIES                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Enum for supported networks.
    enum Network {
        MAINNET,
        SEPOLIA,
        HOLESKY
    }

    /// @dev Returns the genesis time for a specific network.
    function getGenesisTime(Network network) internal pure returns (uint256) {
        if (network == Network.MAINNET) return BeaconSlotLib.MAINNET_GENESIS;
        if (network == Network.SEPOLIA) return BeaconSlotLib.SEPOLIA_GENESIS;
        if (network == Network.HOLESKY) return BeaconSlotLib.HOLESKY_GENESIS;
        revert("Unsupported network");
    }

    /// @dev Returns the current slot for any supported network.
    function getCurrentSlotForNetwork(Network network) internal view returns (uint256) {
        return BeaconSlotLib.getCurrentSlot(getGenesisTime(network));
    }

    /// @dev Returns slot information for any supported network.
    function getSlotInfoForNetwork(uint256 slot, Network network) 
        internal 
        view 
        returns (BeaconSlotLib.SlotInfo memory) 
    {
        return BeaconSlotLib.getSlotInfo(slot, getGenesisTime(network));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    UTILITY FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns true if any of the supported networks are currently in attestation window.
    function isAnyNetworkInAttestationWindow() internal view returns (bool) {
        return isMainnetAttestationWindow() ||
               BeaconSlotLib.isInAttestationWindow(getSepoliaSlot(), BeaconSlotLib.SEPOLIA_GENESIS) ||
               BeaconSlotLib.isInAttestationWindow(getHoleskySlot(), BeaconSlotLib.HOLESKY_GENESIS);
    }

    /// @dev Returns the slot difference between mainnet and a testnet.
    /// @param testnetSlot The testnet slot to compare.
    /// @param network The testnet network.
    /// @return difference The absolute difference in slots (always positive).
    function getSlotDifference(uint256 testnetSlot, Network network) 
        internal 
        view 
        returns (uint256 difference) 
    {
        uint256 mainnetSlot = getMainnetSlot();
        
        // Convert both slots to the same time basis for comparison
        uint256 mainnetTime = BeaconSlotLib.getSlotStartTime(mainnetSlot, BeaconSlotLib.MAINNET_GENESIS);
        uint256 testnetTime = BeaconSlotLib.getSlotStartTime(testnetSlot, getGenesisTime(network));
        
        difference = mainnetTime > testnetTime ? 
            (mainnetTime - testnetTime) / BeaconSlotLib.SECONDS_PER_SLOT :
            (testnetTime - mainnetTime) / BeaconSlotLib.SECONDS_PER_SLOT;
    }
}