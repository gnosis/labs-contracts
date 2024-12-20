// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Panic} from "@openzeppelin/contracts/utils/Panic.sol";

// Based on OpenZeppelin's DoubleEndedQueue, but with a custom struct as data type instead of bytes32.
// See https://docs.openzeppelin.com/contracts/5.x/api/utils#DoubleEndedQueue
library DoubleEndedStructQueue {
    struct MessageContainer {
        address sender;
        address recipient;
        bytes message;
        uint256 value;
    }

    struct Bytes32Deque {
        uint128 _begin;
        uint128 _end;
        mapping(uint128 index => MessageContainer) _data;
    }

    function pushBack(Bytes32Deque storage deque, MessageContainer memory container) internal {
        unchecked {
            uint128 backIndex = deque._end;
            if (backIndex + 1 == deque._begin) Panic.panic(Panic.RESOURCE_ERROR);
            deque._data[backIndex] = container;
            deque._end = backIndex + 1;
        }
    }

    function popBack(Bytes32Deque storage deque) internal returns (MessageContainer memory value) {
        unchecked {
            uint128 backIndex = deque._end;
            if (backIndex == deque._begin) Panic.panic(Panic.EMPTY_ARRAY_POP);
            --backIndex;
            value = deque._data[backIndex];
            delete deque._data[backIndex];
            deque._end = backIndex;
        }
    }

    function pushFront(Bytes32Deque storage deque, MessageContainer memory value) internal {
        unchecked {
            uint128 frontIndex = deque._begin - 1;
            if (frontIndex == deque._end) Panic.panic(Panic.RESOURCE_ERROR);
            deque._data[frontIndex] = value;
            deque._begin = frontIndex;
        }
    }

    function popFront(Bytes32Deque storage deque) internal returns (MessageContainer memory value) {
        unchecked {
            uint128 frontIndex = deque._begin;
            if (frontIndex == deque._end) Panic.panic(Panic.EMPTY_ARRAY_POP);
            value = deque._data[frontIndex];
            delete deque._data[frontIndex];
            deque._begin = frontIndex + 1;
        }
    }

    function front(Bytes32Deque storage deque) internal view returns (MessageContainer memory value) {
        if (empty(deque)) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        return deque._data[deque._begin];
    }

    function back(Bytes32Deque storage deque) internal view returns (MessageContainer memory value) {
        if (empty(deque)) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        unchecked {
            return deque._data[deque._end - 1];
        }
    }

    function at(Bytes32Deque storage deque, uint256 index) internal view returns (MessageContainer memory value) {
        if (index >= length(deque)) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        // By construction, length is a uint128, so the check above ensures that index can be safely downcast to uint128
        unchecked {
            return deque._data[deque._begin + uint128(index)];
        }
    }

    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        unchecked {
            return uint256(deque._end - deque._begin);
        }
    }

    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end == deque._begin;
    }
}
