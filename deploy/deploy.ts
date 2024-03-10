import { Address, Deployer, DeployInfo } from "../web3webdeploy/types";
import {
  OpenTokenDeployment,
  deploy as openTokenDeploy,
} from "../lib/open-token/deploy/deploy";
import { Ether } from "../web3webdeploy/lib/etherUnits";

export interface OpenClaimingDeploymentSettings
  extends Omit<DeployInfo, "contract" | "args" | "salt"> {
  openTokenDeployment: OpenTokenDeployment;
  forceRedeploy?: boolean;
}

export interface OpenClaimingDeployment {
  ovcClaiming: Address;
  nodeClaiming: Address;
}

export async function deploy(
  deployer: Deployer,
  settings?: OpenClaimingDeploymentSettings
): Promise<OpenClaimingDeployment> {
  if (settings?.forceRedeploy !== undefined && !settings.forceRedeploy) {
    return await deployer.loadDeployment({ deploymentName: "latest.json" });
  }

  deployer.startContext("lib/open-token");
  const openTokenDeployment =
    settings?.openTokenDeployment ?? (await openTokenDeploy(deployer));
  deployer.finishContext();

  const second = 1;
  const minute = 60 * second;
  const hour = 60 * minute;
  const day = 24 * hour;
  const week = 7 * day;

  const ovcClaiming = await deployer.deploy({
    id: "VerifiedContribitorRankingClaiming",
    contract: "OpenClaiming",
    args: [
      openTokenDeployment.openToken,
      Ether(100_000), // 0.01% of total supply
      4 * week,
      "0xaF7E68bCb2Fc7295492A00177f14F59B92814e70",
    ],
    salt: "OVC",
    ...settings,
  });

  const nodeClaiming = await deployer.deploy({
    id: "NodesWithdrawClaiming",
    contract: "OpenClaiming",
    args: [
      openTokenDeployment.openToken,
      Ether(10_000_000), // 1% of total supply
      1 * week,
      "0xaF7E68bCb2Fc7295492A00177f14F59B92814e70",
    ],
    salt: "NODE",
    ...settings,
  });

  const deployment = {
    ovcClaiming: ovcClaiming.address,
    nodeClaiming: nodeClaiming.address,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
