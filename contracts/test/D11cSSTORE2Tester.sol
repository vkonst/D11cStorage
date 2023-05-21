// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../D11cSSTORE2Reader.sol";
import "../D11cSSTORE2Writer.sol";

contract D11cSSTORE2Tester is D11cSSTORE2Reader, D11cSSTORE2Writer {
    function testGetInitCode(
        bytes memory data
    ) external pure returns (bytes memory) {
        return getInitCode(data);
    }

    function testGetDataAddress(
        bytes memory data
    ) external pure returns (address) {
        return getDataAddress(data);
    }

    function testRead(address pointer) external view returns (bytes memory) {
        return read(pointer);
    }

    function testReadFromTo(
        address pointer,
        uint256 start,
        uint256 end
    ) external view returns (bytes memory) {
        return readFromTo(pointer, start, end);
    }

    function testWrite(bytes memory data) external returns (address pointer) {
        pointer = write(data);
    }
}
