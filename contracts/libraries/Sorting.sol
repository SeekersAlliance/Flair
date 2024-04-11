// SPDX-License-Identifier: MIT
pragma solidity = 0.8.23;

library SortAlgorithms {
    function quickSort(uint256[] memory arr) internal pure returns (uint256[] memory) {
        if (arr.length == 0) {
            return arr;
        }

        uint256[] memory sortedArr = arr;
        uint256 left = 0;
        uint256 right = arr.length - 1;
        _quickSort(sortedArr, left, right);

        return sortedArr;
    }

    function _quickSort(uint256[] memory arr, uint256 left, uint256 right) internal pure {
        if (left < right) {
            uint256 pivotIndex = _partition(arr, left, right);
            if (pivotIndex > 0) {
                _quickSort(arr, left, pivotIndex - 1);
            }
            _quickSort(arr, pivotIndex + 1, right);
        }
    }

    function _partition(uint256[] memory arr, uint256 left, uint256 right) internal pure returns (uint256) {
        uint256 pivotValue = arr[right];
        uint256 i = left;

        for (uint256 j = left; j < right; j++) {
            if (arr[j] <= pivotValue) {
                (arr[i], arr[j]) = (arr[j], arr[i]);
                i++;
            }
        }

        (arr[i], arr[right]) = (arr[right], arr[i]);
        return i;
    }
}