import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const HoneyChainModule = buildModule("HoneyChainModule", (m) => {
  const honeyChain = m.contract("HoneyChain");

  return { honeyChain };
});

export default HoneyChainModule;
