import { useAddresses } from "@/hooks/useAddresses";
import { parseAbi } from "viem";
export default function useDrawingConfig() {
  const { drawingAddress } = useAddresses();
  const chainId = 43113;
  return {
    address: drawingAddress,
    // abi: DRAWING_ABI,
    abi: parseAbi([
      "function setUnitPool(uint32[] memory _probs)",
      "function setDrawingPool(uint32[] memory _unitIDs, uint32[] memory _probs)",
      "function setTokenMaxAmount(uint32[] memory _maxAmounts)",
      "function sendRequest(uint32[] memory _poolsID, uint32[] memory _drawAmounts)",
    ]),
    chainId: chainId,
  };
}
