// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./core/BytecodeReader.sol";

/**
 * @notice Read immutable (but destructible) data stored as deployed bytecode.
 * Compatible with the D11cRemovableWriter contract.
 * @author vkonst (https://github.com/vkonst/D11cSstore2)
 * @author Reworked from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 * @author Originated from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @dev Data is read via EXTCODECOPY opcodes at a fraction of gas cost that SLOAD may take.
 */
abstract contract D11cRemovableReader is BytecodeReader {
    // Data in the deployed bytecode follows the HEADER the D11cRemovableStore2 uses
    uint256 private constant DATA_OFFSET = 14;

    function _getDataOffset() internal pure override returns(uint256) {
        return DATA_OFFSET;
    }
}
