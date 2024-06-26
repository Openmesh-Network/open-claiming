import { Address, Deployer, DeployInfo } from "../web3webdeploy/types";
import {
  OpenTokenDeployment,
  deploy as openTokenDeploy,
} from "../lib/open-token/deploy/deploy";
import {
  deployVerifiedContributorClaiming,
  DeployVerifiedContributorClaimingSettings,
} from "./internal/VerifiedContributorClaiming";
import {
  deployNodesWithdrawClaiming,
  DeployNodesWithdrawClaimingSettings,
} from "./internal/NodesWithdrawClaiming";

export interface OpenClaimingDeploymentSettings {
  openTokenDeployment: OpenTokenDeployment;
  verifiedContributorClaiming: Omit<
    DeployVerifiedContributorClaimingSettings,
    "token"
  >;
  nodesWithdrawClaiming: Omit<DeployNodesWithdrawClaimingSettings, "token">;
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
    const existingDeployment = await deployer.loadDeployment({
      deploymentName: "latest.json",
    });
    if (existingDeployment !== undefined) {
      return existingDeployment;
    }
  }

  deployer.startContext("lib/open-token");
  const openTokenDeployment =
    settings?.openTokenDeployment ?? (await openTokenDeploy(deployer));
  deployer.finishContext();

  const ovcClaiming = await deployVerifiedContributorClaiming(deployer, {
    token: openTokenDeployment.openToken,
    ...(settings?.verifiedContributorClaiming ?? {}),
  });

  const nodeClaiming = await deployNodesWithdrawClaiming(deployer, {
    token: openTokenDeployment.openToken,
    ...(settings?.nodesWithdrawClaiming ?? {}),
  });

  const deployment: OpenClaimingDeployment = {
    ovcClaiming: ovcClaiming,
    nodeClaiming: nodeClaiming,
  };
  await deployer.saveDeployment({
    deploymentName: "latest.json",
    deployment: deployment,
  });
  return deployment;
}
