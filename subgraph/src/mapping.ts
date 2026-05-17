import { BigInt } from "@graphprotocol/graph-ts";
import { Swap as SwapEvent } from "../generated/ResourceAMM/ResourceAMM";
import { Transfer as TransferEvent } from "../generated/GameVault/GameVaultV1";
import { VoteCast as VoteCastEvent } from "../generated/GameGovernor/GameGovernor";
import { Swap, Transfer, Vote, UserStat } from "../generated/schema";

function getOrCreateUserStat(address: string, timestamp: BigInt): UserStat {
  let user = UserStat.load(address);
  if (!user) {
    user = new UserStat(address);
    user.totalSwaps = BigInt.fromI32(0);
    user.totalVolumeIn = BigInt.fromI32(0);
    user.totalVotes = BigInt.fromI32(0);
    user.lastActiveAt = timestamp;
  }
  return user;
}

export function handleSwap(event: SwapEvent): void {
  let id = event.transaction.hash.toHex();
  let swap = new Swap(id);
  swap.user = event.params.user;
  swap.tokenIn = event.params.tokenIn;
  swap.tokenOut = event.params.tokenOut;
  swap.amountIn = event.params.amountIn;
  swap.amountOut = event.params.amountOut;
  swap.timestamp = event.block.timestamp;
  swap.save();

 
  let userStat = getOrCreateUserStat(event.params.user.toHex(), event.block.timestamp);
  userStat.totalSwaps = userStat.totalSwaps.plus(BigInt.fromI32(1));
  userStat.totalVolumeIn = userStat.totalVolumeIn.plus(event.params.amountIn);
  userStat.lastActiveAt = event.block.timestamp;
  userStat.save();
}

export function handleTransfer(event: TransferEvent): void {
  let id = event.transaction.hash.toHex() + "-" + event.logIndex.toString();
  let transfer = new Transfer(id);
  transfer.from = event.params.from;
  transfer.to = event.params.to;
  transfer.amount = event.params.value;
  transfer.timestamp = event.block.timestamp;
  transfer.save();
}

export function handleVote(event: VoteCastEvent): void {
  let id = event.transaction.hash.toHex();
  let vote = new Vote(id);
  vote.voter = event.params.voter;
  vote.proposalId = event.params.proposalId;
  vote.support = event.params.support;
  vote.weight = event.params.weight;
  vote.reason = event.params.reason;
  vote.save();

  let userStat = getOrCreateUserStat(event.params.voter.toHex(), event.block.timestamp);
  userStat.totalVotes = userStat.totalVotes.plus(BigInt.fromI32(1));
  userStat.lastActiveAt = event.block.timestamp;
  userStat.save();
}