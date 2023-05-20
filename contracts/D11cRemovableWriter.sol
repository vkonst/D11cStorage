// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./core/D11cBytecodeWriter.sol";

/**
 * @notice Deploy immutable data as bytecode at a deterministic (abbreviated as "D11c") address
 * rather than store data into contract storage to save gas cost.
 * The EoA that deploys data may permanently remove (but not update) it.
 * @author vkonst (https://github.com/vkonst/D11cSstore2)
 * @author Reworked from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 * @author Originated from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @dev Data is written as via CREATE2 and read via EXTCODECOPY opcodes.
 * The deployed data address on any network is deterministically defined by the data only.
 * Unlike the original SSTORE2 library, data gets deployed:
 * - via the deterministic-deployment-proxy, that has the same address on all EVM-based networks;
 * (https://github.com/Arachnid/deterministic-deployment-proxy/)
 * - by the CREATE2 (rather than CREATE) opcode with constant salt;
 * - at the deterministically defined by the data itself address on all networks.
 * The bytecode (with data) deployed via this contract may be permanently removed:
 * when called by the deployer EoA, the SELFDESTRUCT opcode gets executed.
 */
abstract contract D11cRemovableWriter is D11cBytecodeWriter {
    /**
     * @dev When called as a "constructor", it stores `msg.origin` into the slot 0 of the contract
     * being instantiated and returns the rest of the "init code" skipping 14 bytes of itself.
     * | Bytecode | Mnemonic       | Stack View               // Comments                          |
     * |----------|----------------|---------------------------------------------------------------|
     * | 0x32     | ORIGIN         | origin                   // msg.origin                        |
     * | 0x3d     | RETURNDATASIZE | 0, origin                // Same as `DUP1 0x00` but shorter   |
     * | 0x55     | SSTORE         | -                        // Store msg.origin to the slot 0    |
     * | 0x600e   | PUSH1 14       | codeOffset               // This code length                  |
     * | 0x3d     | RETURNDATASIZE | 0 codeOffset                                                  |
     * | 0x81     | DUP2           | codeOffset 0 codeOffset                                       |
     * | 0x38     | CODESIZE       | codeSize codeOffset 0 codeOffset                              |
     * | 0x03     | SUB            | (codeSize - codeOffset) 0 codeOffset                          |
     * | 0x80     | DUP1           | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset  |
     * | 0x92     | SWAP3          | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)  |
     * | 0x3d     | RETURNDATASIZE | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)|
     * | 0x39     | CODECOPY       | 0 (codeSize - codeOffset) // Skip this constructor bytecode   |
     * | 0xf3     | RETURN         |                          // Return the rest of the init code  |
     */
    uint112 constant private CONSTRUCTOR = 0x323d55600e3d81380380923d39f3;

    /**
     * @dev The deployed code shall start with this bytecode. Being called by the `owner` (stored at
     * the storage in the slot 0), this code executes SELFDESTRUCT opcode.
     * | bytecode | mnemonic       | stack view               // comments                          |
     * |----------|----------------|---------------------------------------------------------------|
     * | 0x33     | CALLER         | caller                   // memorize msg.sender               |
     * | 0x3d     | RETURNDATASIZE | 0x00, caller                                                  |
     * | 0x54     | SLOAD          | owner, caller            // load the owner addr from slot 0   |
     * | 0x03     | SUB            | SUB(owner, caller)                                            |
     * | 0x600c   | PUSH1 0x0c     | 0x0c, SUB(owner, caller)                                      |
     * | 0x57     | JUMPI          | -                        // if msg.sender!=owner, return      |
     * | 0x3d     | RETURNDATASIZE | 0x00                                                          |
     * | 0x80     | DUP1           | 0x00, 0x00                                                    |
     * | 0x55     | SSTORE         | -                        // clear slot 0 to regain some gas   |
     * | 0x33     | caller         | caller                   // owner to receive remaining balance|
     * | 0xff     | SELFDESTRUCT   | -                        // destruct the contract             |
     * | 0x5b     | JUMPDEST       | -                        // the end                           |
     * | 0x00     | STOP           | -                        // reverts execution after this point|
     */
    uint112 constant private HEADER = 0x333d5403600c573d805533ff5b00;

    function getInitCode(
        bytes memory data
    ) internal pure override returns(bytes memory initCode) {
        initCode = abi.encodePacked(CONSTRUCTOR, HEADER, data);
    }
}