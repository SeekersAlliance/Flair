"use client";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import React, { CSSProperties } from "react";
import { Layout, Menu } from "antd";
const { Header, Content } = Layout;
const headerStyle: CSSProperties = {
  display: "flex",
  justifyContent: "space-between",
};

interface NavBarProps {
  children?: React.ReactNode;
}

export default function NavBar({ children }: NavBarProps) {
  const items = [
    {
      name: "HOME",
      link: "/open-pack/start",
    },
    {
      name: "OPEN",
      link: "/open-pack/start",
    },
  ];
  const itemLinks = items.map((item, index) => {
    return {
      key: `${index}`,
      name: item.name,
      label: (
        <div key={`navbar-${index}`} className="h-[60px] w-[60px]">
          <a href={item.link}>{item.name}</a>
        </div>
      ),
    };
  });
  return (
    <Layout>
      <Header style={headerStyle}>
        <div className="w-[100%] flex flex-row items-center justify-between">
          <div className="w-[60%] flex flex-row items-center">
            <Menu
              theme="dark"
              mode="horizontal"
              style={{ flex: 1, minWidth: 0 }}
              items={itemLinks}
            />
          </div>
          <div className="h-[50px] w-[410px]">
            <ConnectButton />
          </div>
        </div>
      </Header>
      <Content>{children}</Content>
    </Layout>
  );
}
