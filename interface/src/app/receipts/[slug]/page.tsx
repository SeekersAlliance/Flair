'use client';
import { notFound, useRouter } from 'next/navigation';
import Icon from '@ant-design/icons';
import { useCallback, useEffect, useState } from 'react';
import { NFTProfile2 } from '@/components/NFTProfile';
import { useWaitForTransaction } from 'wagmi';
import { filterERC1155Events } from '@/core/events/erc1155';
import { TransferBatchParams, TransferSingleParams } from '@/core/types';
import { getConfig } from '@/config';

export default function Page({ params }: { params: { slug: string } }) {
  const { openseaCollectionUrl, vrfUrl } = getConfig();
  const router = useRouter();
  const { slug } = params;
  const [tokenList, setTokenList] = useState<bigint[]>([]);
  const { data, error } = useWaitForTransaction({
    hash: slug as `0x${string}`,
    chainId: 43113,
  });

  useEffect(() => {
    if (error) {
      router.push('/_not-found');
    }
  }, [error]);

  useEffect(() => {
    if (data) {
      const tokenBatch = filterERC1155Events('TransferBatch', data.logs);
      const tokenSingle = filterERC1155Events('TransferSingle', data.logs);
      const l = [] as bigint[];
      tokenBatch.forEach((item) => {
        const params = item.args as TransferBatchParams;
        for (let i = 0; i < params.values.length; i++) {
          for (let j = 0; j < params.values[i]; j++) {
            l.push(params.ids[i]);
          }
        }
      });
      tokenSingle.forEach((item) => {
        const params = item.args as TransferSingleParams;
        for (let i = 0; i < params.value; i++) {
          l.push(params.id);
        }
      });
      setTokenList(l);
    }
  }, [data]);

  return (
    <main className='min-h-screen bg-[#0c0e12]'>
      <div className='w-[100%] p-[193px]'>
        <div className='grid grid-flow-dense grid-cols-5 justify-between'>
          {tokenList.map((item, index) => (
            <div key={index} className='flex flex-col items-center'>
              <NFTProfile2 tokenId={item} />
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}
