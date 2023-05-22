// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./core/D11cBytecodeWriter.sol";

/**
 * @notice Deploy immutable data as bytecode at a deterministic (abbreviated as "D11c") address.
 * It may save gas cost writing/reading to/from the contract storage would take.
 * @author vkonst (https://github.com/vkonst/D11cStorage)
 * @author Reworked from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 * @author Originated from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @dev Data is written via CREATE2 and read via EXTCODECOPY opcodes.
 * The deployed data address on any network is deterministically defined by the data only.
 * Unlike the original SSTORE2 library, this contract deploys data:
 * - via the deterministic-deployment-proxy, that has the same address on all EVM-based networks;
 *   (https://github.com/Arachnid/deterministic-deployment-proxy/)
 * - by the CREATE2 (rather than CREATE) opcode with constant salt;
 * - at the address deterministically defined for any network by the data itself.
 */
abstract contract D11cSSTORE2Writer is D11cBytecodeWriter {
    /**
     * @dev When called as the CONSTRUCTOR, this code skips 11 bytes of itself and returns
     * the rest of the "init code" (i.e. the "deployed code" that follows these 11 bytes):
     * | Bytecode | Mnemonic  | Stack View                                                    |
     * |----------|-----------|---------------------------------------------------------------|
     * | 0x600B   | PUSH1 11  | codeOffset                                                    |
     * | 0x59     | MSIZE     | 0 codeOffset                                                  |
     * | 0x81     | DUP2      | codeOffset 0 codeOffset                                       |
     * | 0x38     | CODESIZE  | codeSize codeOffset 0 codeOffset                              |
     * | 0x03     | SUB       | (codeSize - codeOffset) 0 codeOffset                          |
     * | 0x80     | DUP1      | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset  |
     * | 0x92     | SWAP3     | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)  |
     * | 0x59     | MSIZE     | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)|
     * | 0x39     | CODECOPY  | 0 (codeSize - codeOffset)                                     |
     * | 0xf3     | RETURN    | -                                                             |
     *
     * @dev Deployed bytecode starts with this HEADER to prevent calling the bytecode
     * | Bytecode | Mnemonic  | Stack View                                                    |
     * |----------|-----------|---------------------------------------------------------------|
     * | 0x00     | STOP      | -                                                             |
     */
    uint96 private constant CONSTRUCTOR_AND_HEADER = 0x600B5981380380925939F300;

    function getInitCode(
        bytes memory data
    ) internal pure override returns (bytes memory initCode) {
        initCode = abi.encodePacked(CONSTRUCTOR_AND_HEADER, data);
    }
}
