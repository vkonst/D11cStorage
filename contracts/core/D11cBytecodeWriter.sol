// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @notice Write data as deployed bytecode to a deterministic (abbreviated as "D11c") address.
 * @author vkonst (https://github.com/vkonst/D11cStorage)
 * @dev It deploys data via the deterministic-deployment-proxy. The deployment address on any
 * EVM-based network is deterministically defined by the data itself and known before deployment.
 * The deterministic-deployment-proxy has the same address on all EVM-based networks (anyone may
 * deploy it to a new EVM network at the same address) and uses CREATE2 opcode for deployment.
 * More on the deterministic-deployment-proxy:
 * https://github.com/Arachnid/deterministic-deployment-proxy/
 * (note its code in source/deterministic-deployment-proxy.yul).
 */
abstract contract D11cBytecodeWriter {
    // Address of the deterministic-deployment-proxy.
    // https://blockscan.com/address/0x4e59b44847b379578588920ca78fbf26c0b4956c
    // It is the same on all networks the contract is (and will be) deployed at:
    address private constant DETERMINISTIC_DEPLOYER =
        0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // The "salt" to pass to the deterministic deployer
    // (0xe83661647013d6f32adb6510984aad7eb9fb8fbc257c60441132293990d1c069)
    bytes32 private constant SALT = keccak256("d11c");

    /// @dev Return the init code to deploy the bytecode with the given data
    function getInitCode(
        bytes memory data
    ) internal pure virtual returns (bytes memory);

    /**
     * @notice Compute the deployment address for the given `initCode`.
     * @dev The DETERMINISTIC_DEPLOYER is assumed to call CREATE2 with the `initCode`
     * and with SALT as the salt.
     */
    function getDataAddress(
        bytes memory initCode
    ) internal pure returns (address) {
        bytes32 initCodeHash = keccak256(initCode);

        bytes32 encodedAddress = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(DETERMINISTIC_DEPLOYER),
                SALT,
                initCodeHash
            )
        );
        // Extract and return 20 last bytes of `encodedAddress`
        return address(uint160(uint256(encodedAddress)));
    }

    function write(bytes memory data) internal returns (address pointer) {
        // Prepare callData for the deterministic-deployer-proxy call
        bytes memory callData = abi.encodePacked(SALT, getInitCode(data));

        // Call the deterministic-deployer-proxy
        (bool success, bytes memory res) = DETERMINISTIC_DEPLOYER.call(
            callData
        );
        require(success && res.length == 20, "DEPLOYMENT_FAILED");

        // Extract the deployment address
        uint256 pointer256 = 0;
        /// @solidity memory-safe-assembly
        assembly {
            // Write `res`, skipping first 32 bytes with `res.length`
            pointer256 := mload(add(res, 32))
        }
        pointer = address(uint160(pointer256 >> 96));
    }
}
