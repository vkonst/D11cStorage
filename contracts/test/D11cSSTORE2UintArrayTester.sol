// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "../D11cSSTORE2Reader.sol";
import "../D11cSSTORE2Writer.sol";

contract D11cSSTORE2UintArrayTester is D11cSSTORE2Reader, D11cSSTORE2Writer {
    function writeAsUintArray(uint256[] memory data) external returns (address pointer) {
        bytes memory encodedData = abi.encode(data);
        pointer = write(encodedData);
    }

    function readAsUintArray(address pointer) external view returns (uint256[] memory data) {
        bytes memory encodedData = read(pointer);
        (data) = abi.decode(encodedData, (uint256[]));
    }
}
