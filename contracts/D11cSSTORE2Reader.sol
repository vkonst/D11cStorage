// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./core/BytecodeReader.sol";

/**
 * @notice Read immutable data persistently stored as deployed bytecode.
 * Compatible with the D11cSSTORE2Writer contract and the SSTORE2 library.
 * @author vkonst (https://github.com/vkonst/D11cSstore2)
 * @author Reworked from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 * @author Originated from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @dev Data is read via the EXTCODECOPY opcodes at a fraction of gas cost that SLOAD may take.
 */
abstract contract D11cSSTORE2Reader is BytecodeReader {
    // Data in the deployed bytecode follows one-byte STOP opcode that reverts calls
    uint256 private constant DATA_OFFSET = 1;

    function _getDataOffset() internal pure override returns (uint256) {
        return DATA_OFFSET;
    }
}
