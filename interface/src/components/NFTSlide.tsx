import {NFTProfile} from "@/components/NFTProfile";
import {useTokenList} from "@/hooks/useTokenList";
import {useEffect, useState} from "react";


export default function NFTSlide(){
    const { tokenList } = useTokenList();
    console.log(tokenList);
    const [selectedToken, setSelectedToken] = useState<number>(0);
    useEffect(() => {
        if (tokenList.length > 0) {
            setInterval(() => {
                console.log("setInterval", tokenList);
                setSelectedToken(Math.floor(Math.random() * tokenList.length));
            }, 2000);
        }
    }, [tokenList]);
    return (
        <NFTProfile tokenId={tokenList[selectedToken] || BigInt(0)} />
  );
}
