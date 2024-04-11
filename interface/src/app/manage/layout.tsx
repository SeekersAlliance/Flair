"use client";
import { Layout } from "antd";

const { Footer } = Layout;

export default function PageLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <Layout className="flex min-h-screen justify-between bg-[#0c0e12]">
      {children}
    </Layout>
  );
}
