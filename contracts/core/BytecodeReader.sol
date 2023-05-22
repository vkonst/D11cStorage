// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @notice Read deployed bytecode.
 * @author vkonst (https://github.com/vkonst/D11cStorage)
 * @author Originated from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 */
abstract contract BytecodeReader {
    function read(address pointer) internal view returns (bytes memory) {
        uint256 offset = _getDataOffset();
        return _readBytecode(pointer, offset, pointer.code.length - offset);
    }

    function readFromTo(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        uint256 offset = _getDataOffset();
        require(pointer.code.length >= end + offset, "OUT_OF_BOUNDS");
        return _readBytecode(pointer, start + offset, end - start);
    }

    function _getDataOffset() internal pure virtual returns (uint256);

    function _readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}
