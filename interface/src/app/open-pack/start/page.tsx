"use client";
import ConnectWalletButton from "@/components/ConnectWalletButton";
import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import NFTSlide from "@/components/NFTSlide";

export default function Page() {
  const router = useRouter();
  const handleToBuy = useCallback(() => {
    console.log("connected");
    router.push("/open-pack/buy");
  }, [router]);
  return (
    <main className="flex flex-col min-h-screen bg-black items-center">
      <div className="pt-24 flex flex-col items-center">
        <div className="w-[300px]">
          <NFTSlide />
        </div>
        <div className="h-[60px] w-[465px] gap-4">
          <ConnectWalletButton onAfterConnect={handleToBuy}>
            {"BUY PACKS"}
          </ConnectWalletButton>
        </div>
      </div>
    </main>
  );
}
