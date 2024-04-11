// SPDX-License-Identifier: MIT
pragma solidity = 0.8.23;

library PackedArray {

    error InvalidIndex(uint256);

    struct PackedArray32 {
        uint256 nums;
        uint256[] result;
    }

    function pack(uint32[] memory _arr) internal pure returns(PackedArray32 memory) {
        PackedArray32 memory packedArray;
        packedArray.nums = uint32(_arr.length);

        uint256 rows = _arr.length/8;
        if(_arr.length % 8 != 0) {
            rows ++;
        }
        
        packedArray.result = new uint256[](rows);
        for(uint256 i;i<_arr.length;i++) {
            packedArray = set(packedArray, i, _arr[i]);
        }

        return packedArray;
    }

    function set(PackedArray32 memory p, uint256 index, uint32 data) internal pure returns(PackedArray32 memory){
        uint256 row = index / 8;
        uint256 i = index % 8;
        uint256 mask = ~(uint256(type(uint32).max) << 32 * (7-i));
        p.result[row] &= mask;
        p.result[row] |= (uint256(data) << 32 * (7-i));

        return p;
    }

    function get(PackedArray32 memory p, uint256 index) internal pure returns(uint32) {
        if(index >= p.nums) revert InvalidIndex(index);
        uint256 row = index / 8;
        uint256 i = index % 8;
        return uint32(p.result[row] >> (7-i) * 32);
    }
}