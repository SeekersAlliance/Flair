import { Button } from "antd";
import styled from "styled-components";
import { ReactNode, useCallback, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useAccount, useConnect, useNetwork, useSwitchNetwork } from "wagmi";

export const BaseButton = styled(Button)`
  width: 100%;
  height: 100%;
  color: #000000;
  font-size: 21px;
  font-weight: bold;
  text-transform: uppercase;
  font-family: "Space Grotesk", sans-serif;
  border-radius: 4px;
`;

export const PrimaryButton = styled(BaseButton)`
  border: 1px solid #fffd8c;
  background: #f0b90b;
  text-transform: none;
  font-family: "Work Sans", sans-serif;
`;

export const SelectedButton = styled(BaseButton)`
  color: #29ffef;
  background-color: rgba(
    255,
    255,
    255,
    0.298
  ); /* Adjusted for correct opacity */
  /* Tailwind class: backdrop-blur-[10px] */
  backdrop-filter: blur(10px);

  /* Tailwind class: backdrop-brightness-[100%] */
  -webkit-backdrop-filter: brightness(100%);

  /* Tailwind class: [-webkit-backdrop-filter:blur(10px)_brightness(100%)] */
  -webkit-backdrop-filter: blur(10px) brightness(100%);
`;

export const UnSelectedButton = styled(SelectedButton)`
  color: #000000;
`;


interface SelectingButtonProps {
  selected: boolean;
  onClick?: () => void;
  children: ReactNode;
}

export function SelectingButton({
  selected,
  onClick,
  children,
}: SelectingButtonProps) {
  return (
    <>
      {selected ? (
        <SelectedButton onClick={onClick}>{children}</SelectedButton>
      ) : (
        <UnSelectedButton onClick={onClick}>{children}</UnSelectedButton>
      )}
    </>
  );
}

interface SpecificChainButtonProps {
  isLoading?: boolean;
  chainId: number;
  onClick: () => void;
  children: React.ReactNode;
}

export function SpecificChainButton({
  isLoading,
  chainId,
  onClick,
  children,
}: SpecificChainButtonProps) {
  const { chain } = useNetwork();
  const { isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { switchNetwork } = useSwitchNetwork();
  const isCorrectChain = useMemo(() => {
    return chain?.id === chainId;
  }, [chain]);
  const router = useRouter();
  const handleChangeChain = useCallback(() => {
    if (chain?.id === chainId) {
      return;
    }
    switchNetwork?.(chainId);
  }, [switchNetwork, chain]);
  const handleConnect = useCallback(() => {
    console.log(connectors);
    const connector = connectors.find(
      (connector) => connector.id === "injected",
    );
    console.log(connector);
    connect({ connector: connector });
  }, [connect, isConnected]);
  console.log(`isLoading ${isLoading}`);
  return isConnected ? (
    isCorrectChain ? (
      <PrimaryButton loading={isLoading} onClick={onClick}>
        {children}
      </PrimaryButton>
    ) : (
      <PrimaryButton onClick={handleChangeChain}>Switch Network</PrimaryButton>
    )
  ) : (
    <PrimaryButton onClick={handleConnect}>Connect Wallet</PrimaryButton>
  );
}
