"use client";
import { ReactNode, useCallback, useEffect, useMemo, useState } from "react";
import { PrimaryButton, SelectingButton } from "@/components/Button";
import { useAccount, useNetwork, useSwitchNetwork } from "wagmi";
import { useRouter } from "next/navigation";
import ConnectWalletButton from "@/components/ConnectWalletButton";
import useTxnNotify from "@/hooks/useTxnNotify";
import { TransactionAction } from "@/utils/transaction";
import useMarketplaceTxn from "@/hooks/useMarketplaceTxn";
import { useAddresses } from "@/hooks/useAddresses";
import useWaitForCCIP from "@/hooks/useWaitForCCIP";
import Link from "next/link";
import { getConfig } from "@/config";
import useCoinTxn from "@/hooks/useCoinTxn";
import { useCoinAddress } from "@/hooks/useCoinAddress";
import useCoinRead from "@/hooks/useCoinRead";
import NFTSlide from "@/components/NFTSlide";

export default function Page() {
  const { packId } = getConfig();
  const networkList = ["AVALANCHE", "ETHEREUM", "OPTIMISM","opBNB"];
  const amountList = [1, 5, 10, 15, 20, 25];
  const selectedNetwork = 0;
  const [selectedToken, setSelectedToken] = useState(0);
  const [selectedAmount, setSelectedAmount] = useState(0);
  const [messageId, setMessageId] = useState<string | undefined>(undefined);
  const [senderHash, setSenderHash] = useState<`0x${string}` | undefined>(
    undefined,
  );
  const messageLink = useMemo(() => {
    return `https://ccip.chain.link/msg/${messageId}`;
  }, [messageId]);
  const hashLink = useMemo(() => {
    switch (networkList[selectedNetwork]) {
      case "AVALANCHE":
        return `https://testnet.snowtrace.io/tx/${senderHash}`;
        case "opBNB":
        return `https://testnet.bscscan.com/tx/${senderHash}`;
      case "ETHEREUM":
        return `https://sepolia.etherscan.io/tx/${senderHash}`;
      case "OPTIMISM":
        return `https://goerli-optimism.etherscan.io/tx/${senderHash}`;
    }
  }, [senderHash, selectedNetwork, networkList]);
  console.log(`messageLink`, messageLink);
  console.log(`hashLink`, hashLink);
  console.log(`selectedAmount`, amountList[selectedAmount]);
  const nativeCoin = useMemo(() => {
    switch (networkList[selectedNetwork]) {
      case "AVALANCHE":
        return "AVAX";
      case 'opBNB':
        return "BNB";
      default:
        return "ETH";
    }
  }, [selectedNetwork]);
  const coin = useMemo(() => {
    switch (selectedToken) {
      case 0:
        return nativeCoin;
      case 1:
        return "USDT";
      default:
        return nativeCoin;
    }
  }, [selectedToken, nativeCoin]);
  const isNative = useMemo(() => {
    return selectedToken === 0;
  }, [selectedToken]);
  const price = useMemo(() => {
    if (isNative) {
      return BigInt(0);
    }
    return BigInt(0);
  }, [isNative]);
  const handleMessageId = useCallback((messageId: string) => {
    setMessageId(messageId);
  }, []);
  const handleSenderHash = useCallback((hash: `0x${string}`) => {
    setSenderHash(hash);
  }, []);
  console.log(`senderHash`, senderHash);
  console.log(`!!!!!!!!!!!!`, senderHash);
  const scanLogo = useMemo(() => {
    switch (networkList[selectedNetwork]) {
      case "AVALANCHE":
        return "/avalanche-avax-logo.svg";
      case "opBNB":
        return "/bscscan-logo-circle.svg";
      case "ETHEREUM":
        return "/etherscan-logo.svg";
      case "OPTIMISM":
        return "/optimism-logo.svg";
    }
  }, [selectedNetwork, networkList]);
  const handleSelectToken = useCallback((index: number) => {
    return () => setSelectedToken(index);
  }, []);
  const handleSelectAmount = useCallback((index: number) => {
    return () => setSelectedAmount(index);
  }, []);
  return (
    <main className='flex min-h-screen bg-[#0c0e12]'>
      <div className='flex flex-col items-center w-[100%] gap-4 pt-12'>
        <div className="w-[300px]">
          <NFTSlide />
        </div>
          <div className="flex h-[60px] w-[465px] flex-row gap-4">
            <SelectingButton
                selected={selectedToken === 0}
                onClick={handleSelectToken(0)}
            >
              {nativeCoin}
            </SelectingButton>
            <SelectingButton
                selected={selectedToken === 1}
                onClick={handleSelectToken(1)}
            >
              USDT
            </SelectingButton>
          </div>
          <div className="flex h-[60px] w-[465px] flex-row gap-4">
            {amountList.map((item, index) => {
              const selected = index === selectedAmount;
              return (
                  <SelectingButton
                      key={index}
                      selected={selected}
                      onClick={handleSelectAmount(index)}
                  >
                    {item}
                  </SelectingButton>
              );
            })}
          </div>
          <div className="flex h-[60px] w-[465px] flex-row justify-between gap-2">
            <div className="w-[83%]">
              <BuyStatusButton
                  packId={packId}
                  network={networkList[selectedNetwork]}
                  amount={amountList[selectedAmount]}
                  price={price}
                  onMessageId={handleMessageId}
                  onSenderHash={handleSenderHash}
                  coin={coin}
                  isNative={isNative}
              >
                BUY
              </BuyStatusButton>
            </div>
            <div className="w-[14%]">
              <div className="flex h-[100%] w-[100%] items-center justify-center rounded-[4px] bg-gray-600">
                <Link href={hashLink || ""} target={"_blank"}>
                  <img src={scanLogo} alt={'scan'} width={40} />
                </Link>
              </div>
            </div>
          </div>
        </div>
    </main>
  );
}

function getChainId(network: string): number {
  let chainId = 5;
  switch (network) {
    case "AVALANCHE":
      chainId = 43113;
      break;
    case "ETHEREUM":
      chainId = 11155111;
      break;
    case "OPTIMISM":
      chainId = 420;
      break;
  }
  return chainId;
}

enum BuyStatus {
  BeforeBuy,
  Buy,
  PendingBuy,
  AfterBuy,
}

interface BuyStatusButtonProps {
  onMessageId?: (messageId: string) => void;
  onSenderHash?: (hash: `0x${string}`) => void;
  packId: number;
  price: bigint;
  amount: number;
  network: string;
  isNative: boolean;
  coin: string;
  children?: ReactNode;
}

function BuyStatusButton({
  network,
  amount,
  packId,
  price,
  onMessageId,
  coin,
  isNative,
  children,
  onSenderHash,
}: BuyStatusButtonProps) {
  const [status, setStatus] = useState(BuyStatus.BeforeBuy);
  const { isConnected } = useAccount();
  const { chain } = useNetwork();
  const { switchNetwork } = useSwitchNetwork();
  const router = useRouter();
  const [senderHash, setSenderHash] = useState<`0x${string}` | undefined>(
    undefined,
  );
  const {
    isSuccess,
    isLoading: isCCIPLoading,
    isError,
    error,
    messageId,
    receiverHash,
  } = useWaitForCCIP(11155111, senderHash);
  const handleHash = useCallback(
    (hash: `0x${string}`) => {
      if (getChainId(network) === 43113) {
        setSenderHash(hash);
        setStatus(BuyStatus.AfterBuy);
      } else {
        setSenderHash(hash);
        setStatus(BuyStatus.PendingBuy);
      }
      onSenderHash?.(hash);
    },
    [network],
  );
  const handleChainChanged = useCallback(
    (network: string) => {
      let chainId = getChainId(network);
      if (chainId === chain?.id) {
        console.log("same chain");
        return;
      }
      console.log(chainId);
      switchNetwork?.(chainId);
    },
    [switchNetwork, chain],
  );

  const handleAfterBuy = useCallback(() => {
    if (status === BuyStatus.AfterBuy) {
      router.push("/open-pack/open");
      return;
    }
  }, [status]);
  useEffect(() => {
    if (isSuccess && status === BuyStatus.PendingBuy) {
      setStatus(BuyStatus.AfterBuy);
    }
  }, [status, isSuccess]);

  useEffect(() => {
    if (status === BuyStatus.BeforeBuy) {
      if (isConnected && getChainId(network) === chain?.id) {
        setStatus(BuyStatus.Buy);
      }
    } else {
      if (!isConnected || getChainId(network) !== chain?.id) {
        setStatus(BuyStatus.BeforeBuy);
      }
    }
  }, [status, isConnected, chain, network]);
  useEffect(() => {
    if (messageId) {
      console.log(`messageId`, messageId);
      onMessageId?.(messageId);
    }
  }, [messageId]);
  switch (status) {
    case BuyStatus.BeforeBuy:
      return (
        <ConnectWalletButton onAfterConnect={() => handleChainChanged(network)}>
          SWITCH NETWORK
        </ConnectWalletButton>
      );
    case BuyStatus.Buy:
      return (
        <BuyButton
          amount={amount}
          packId={packId}
          price={price}
          network={network}
          onHash={handleHash}
          coin={coin}
          isNative={isNative}
        >
          {children}
        </BuyButton>
      );
    case BuyStatus.PendingBuy:
      return <PrimaryButton loading={true}>Waiting For CCIP</PrimaryButton>;
    case BuyStatus.AfterBuy:
      return <PrimaryButton onClick={handleAfterBuy}>OPEN PACKS</PrimaryButton>;
  }
}

interface BuyButtonProps {
  onHash?: (hash: `0x${string}`) => void;
  packId: number;
  price: bigint;
  amount: number;
  network: string;
  isNative?: boolean;
  children?: ReactNode;
}

type BuyByCoinButtonProps = BuyButtonProps & {
  coin: string;
};

function BuyButton({
  onHash,
  packId,
  price,
  amount,
  network,
  children,
  isNative = true,
  coin,
}: BuyByCoinButtonProps) {
  const { address } = useAccount();
  const { chain } = useNetwork();
  const { marketplaceReceiverAddress, marketplaceSenderAddress } =
    useAddresses();
  const spender = useMemo(() => {
    switch (chain?.id) {
      case 43113:
        return marketplaceReceiverAddress;
      case 11155111:
        return marketplaceSenderAddress;
      default:
        return marketplaceReceiverAddress;
    }
  }, [chain, marketplaceReceiverAddress, marketplaceSenderAddress]);
  const {
    data: allowance,
    isLoading,
    error,
  } = useCoinRead(coin, "allowance", [address, spender]);
  console.log(`allowance`, allowance);
  console.log(`allowance`, allowance, amount, price);
  const needToApprove = useMemo(() => {
    console.log(`allowance`, allowance, amount, price);
    if (allowance) {
      return allowance < BigInt(amount) * BigInt(price);
    }
    return true;
  }, [allowance, amount, price]);
  if (isNative) {
    return (
      <BuyByNativeButton
        amount={amount}
        packId={packId}
        price={price}
        network={network}
        onHash={onHash}
      >
        {children}
      </BuyByNativeButton>
    );
  } else {
    return needToApprove ? (
      <ApproveButton coin={coin}>APPROVE</ApproveButton>
    ) : (
      <BuyByCoinButton
        amount={amount}
        packId={packId}
        price={price}
        network={network}
        onHash={onHash}
        coin={coin}
      >
        {children}
      </BuyByCoinButton>
    );
  }
}

function BuyByNativeButton({
  network,
  amount,
  packId,
  price,
  onHash,
  children,
}: BuyButtonProps) {
  const { marketplaceReceiverAddress } = useAddresses();
  const { handleTxnResponse, contextHolder, api } = useTxnNotify();
  const {
    hash,
    submit,
    isSubmitError,
    isSubmitSuccess,
    submitError,
    confirmError,
    isConfirmSuccess,
    isConfirmError,
    isLoading,
    confirmData,
  } = useMarketplaceTxn("purchasePackNative", getChainId(network));
  const handleBuy = useCallback(() => {
    console.log(`price: ${price}`);
    const value = price * BigInt(amount);
    console.log(`value: ${value}`);
    switch (getChainId(network)) {
      case 43113:
        //@ts-ignore
        submit?.({ args: [packId, amount], value: value });
        break;
      case 11155111:
        submit?.({
          args: [
            BigInt("14767482510784806043"),
            marketplaceReceiverAddress,
            packId,
            amount,
            1,
          ],
          value: value,
        });
        break;
      default:
        submit?.({
          args: [
            BigInt("14767482510784806043"),
            marketplaceReceiverAddress,
            packId,
            amount,
            1,
          ],
          value: value,
        });
    }

    return;
  }, [amount, packId, price, network]);
  useEffect(() => {
    handleTxnResponse(
      TransactionAction.SUBMIT,
      isSubmitError,
      isSubmitSuccess,
      submitError,
    );
  }, [isSubmitError, isSubmitSuccess, submitError]);
  useEffect(() => {
    handleTxnResponse(
      TransactionAction.CONFIRM,
      isConfirmError,
      isConfirmSuccess,
      confirmError,
    );
  }, [isConfirmError, isConfirmSuccess, confirmError]);

  useEffect(() => {
    console.log(`confirmData`, confirmData);
    if (confirmData) {
      console.log(`confirmData`, confirmData);
      onHash?.(confirmData?.transactionHash);
    }
  }, [confirmData]);
  return (
    <>
      {contextHolder}
      <PrimaryButton loading={isLoading} onClick={handleBuy}>
        {children}
      </PrimaryButton>
    </>
  );
}

function BuyByCoinButton({
  coin,
  network,
  amount,
  packId,
  price,
  onHash,
  children,
}: BuyByCoinButtonProps) {
  const { marketplaceReceiverAddress } = useAddresses();
  const { chain } = useNetwork();
  const usdtAddress = useCoinAddress(coin, chain?.id || 43113);
  const { handleTxnResponse, contextHolder, api } = useTxnNotify();
  const {
    hash,
    submit,
    isSubmitError,
    isSubmitSuccess,
    submitError,
    confirmError,
    isConfirmSuccess,
    isConfirmError,
    isLoading,
    confirmData,
  } = useMarketplaceTxn("purchasePack", getChainId(network));
  const handleBuy = useCallback(() => {
    console.log(`price: ${price}`);
    const value = price * BigInt(amount);
    console.log(`value: ${value}`);
    switch (getChainId(network)) {
      case 43113:
        //@ts-ignore
        submit?.({ args: [usdtAddress, packId, amount] });
        break;
      case 11155111:
        submit?.({
          args: [
            BigInt("14767482510784806043"),
            marketplaceReceiverAddress,
            usdtAddress,
            packId,
            amount,
            1,
          ],
        });
        break;
      default:
        submit?.({
          args: [
            BigInt("14767482510784806043"),
            marketplaceReceiverAddress,
            usdtAddress,
            packId,
            amount,
            1,
          ],
        });
    }

    return;
  }, [amount, packId, price, network, usdtAddress]);
  useEffect(() => {
    handleTxnResponse(
      TransactionAction.SUBMIT,
      isSubmitError,
      isSubmitSuccess,
      submitError,
    );
  }, [isSubmitError, isSubmitSuccess, submitError]);
  useEffect(() => {
    handleTxnResponse(
      TransactionAction.CONFIRM,
      isConfirmError,
      isConfirmSuccess,
      confirmError,
    );
  }, [isConfirmError, isConfirmSuccess, confirmError]);

  useEffect(() => {
    console.log(`confirmData`, confirmData);
    if (confirmData) {
      console.log(`confirmData`, confirmData);
      onHash?.(confirmData?.transactionHash);
    }
  }, [confirmData]);
  return (
    <>
      {contextHolder}
      <PrimaryButton loading={isLoading} onClick={handleBuy}>
        {children}
      </PrimaryButton>
    </>
  );
}

interface ApproveButtonProps {
  coin: string;
  children?: ReactNode;
}

function ApproveButton({ coin, children }: ApproveButtonProps) {
  const { chain } = useNetwork();
  const { marketplaceReceiverAddress, marketplaceSenderAddress } =
    useAddresses();
  const spender = useMemo(() => {
    switch (chain?.id) {
      case 43113:
        return marketplaceReceiverAddress;
      case 11155111:
        return marketplaceSenderAddress;
      default:
        return marketplaceReceiverAddress;
    }
  }, [chain, marketplaceReceiverAddress, marketplaceSenderAddress]);
  const { handleTxnResponse, contextHolder, api } = useTxnNotify();
  const {
    hash,
    submit,
    isSubmitError,
    isSubmitSuccess,
    submitError,
    confirmError,
    isConfirmSuccess,
    isConfirmError,
    isLoading,
    confirmData,
  } = useCoinTxn(coin, "approve");
  const handleApprove = useCallback(() => {
    submit?.({ args: [spender, BigInt(MAX_UINT256)] });
    console.log(`approve to ${spender}`);
    return;
  }, [spender, submit]);
  useEffect(() => {
    handleTxnResponse(
      TransactionAction.SUBMIT,
      isSubmitError,
      isSubmitSuccess,
      submitError,
    );
  }, [isSubmitError, isSubmitSuccess, submitError]);
  useEffect(() => {
    handleTxnResponse(
      TransactionAction.CONFIRM,
      isConfirmError,
      isConfirmSuccess,
      confirmError,
    );
  }, [isConfirmError, isConfirmSuccess, confirmError]);

  useEffect(() => {
    console.log(`confirmData`, confirmData);
    if (confirmData) {
      console.log(`confirmData`, confirmData);
    }
  }, [confirmData]);
  return (
    <>
      {contextHolder}
      <PrimaryButton loading={isLoading} onClick={handleApprove}>
        {children}
      </PrimaryButton>
    </>
  );
}

const MAX_UINT256 =
  "115792089237316195423570985008687907853269984665640564039457584007913129639935";
