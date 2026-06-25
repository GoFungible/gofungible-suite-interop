// test/utils/types.ts
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { MockedRelayer, MockTargetContract } from "../../gofungible-suite-token/typechain-types/index.js";

// Contract type definitions
export interface RelayerContract extends MockedRelayer {}
export interface TargetContract extends MockTargetContract {}

// Status enums
export enum MessageStatus {
    Pending = 0,
    Relaying = 1,
    Confirmed = 2,
    Failed = 3,
    Reverted = 4
}

// Configuration types
export interface RelayerConfig {
    sourceChainId: number;
    destinationChainId: number;
    relayerAddress: string;
}

export interface MessagePayload {
    id: string;
    data: string;
    timestamp: number;
}

// Return types
export interface MessageDetails {
    id: bigint;
    sender: string;
    recipient: string;
    payload: string;
    timestamp: bigint;
    fee: bigint;
    retryCount: number;
    status: MessageStatus;
    txHash: string;
    gasUsed: bigint;
    revertData: string;
}

// Event types
export interface MessageSentEvent {
    messageId: bigint;
    sender: string;
    recipient: string;
    payload: string;
    timestamp: bigint;
    fee: bigint;
}

export interface MessageDeliveredEvent {
    messageId: bigint;
    relayer: string;
    txHash: string;
    gasUsed: bigint;
    timestamp: bigint;
}

export interface MessageFailedEvent {
    messageId: bigint;
    reason: string;
    retryCount: number;
}

// Test fixture type
export interface TestFixture {
    signers: {
        owner: SignerWithAddress;
        relayer: SignerWithAddress;
        sender: SignerWithAddress;
        user: SignerWithAddress;
        unauthorized: SignerWithAddress;
    };
    contracts: {
        relayer: MockedRelayer;
        target: MockTargetContract;
    };
}

// Configuration constant
export const CONFIG = {
    SOURCE_CHAIN_ID: 1,
    DEST_CHAIN_ID: 2,
    RELAYER_FEE: ethers.parseEther("0.01"),
    MAX_RETRY: 3,
    MESSAGE_EXPIRY: 3600, // 1 hour
    GAS_LIMIT: 1000000
} as const;

// Utility type for bigint comparisons
export type BigIntish = bigint | number | string;

// Function type for test helpers
export type SendMessageFunction = (
    relayer: MockedRelayer,
    sender: SignerWithAddress,
    target: MockTargetContract,
    fee?: bigint
) => Promise<{
    messageId: bigint;
    receipt: any;
    payload: string;
}>;

export type RelayMessageFunction = (
    relayer: MockedRelayer,
    relayerSigner: SignerWithAddress,
    messageId: bigint
) => Promise<MessageDetails>;