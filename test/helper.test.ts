// test/utils/testHelpers.ts
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract, ContractFactory, EventLog } from "ethers";
import { MockedRelayer, MockTargetContract } from "../../typechain-types";

export interface TestSigners {
    owner: SignerWithAddress;
    relayer: SignerWithAddress;
    sender: SignerWithAddress;
    user: SignerWithAddress;
    unauthorized: SignerWithAddress;
}

export interface TestSetup {
    signers: TestSigners;
    relayer: MockedRelayer;
    target: MockTargetContract;
}

export interface MessageResult {
    messageId: bigint;
    receipt: any;
    payload: string;
}

export class TestHelper {
    private signers!: TestSigners;
    private relayer!: MockedRelayer;
    private target!: MockTargetContract;
    private readonly RELAYER_FEE = ethers.parseEther("0.01");
    private readonly SOURCE_CHAIN_ID = 1;
    private readonly DEST_CHAIN_ID = 2;

    constructor() {}

    async initialize(): Promise<TestSigners> {
        const [owner, relayer, sender, user, unauthorized] = await ethers.getSigners();
        
        this.signers = {
            owner,
            relayer,
            sender,
            user,
            unauthorized
        };
        
        return this.signers;
    }

    async deployRelayer(
        sourceChainId: number = this.SOURCE_CHAIN_ID,
        destChainId: number = this.DEST_CHAIN_ID
    ): Promise<MockedRelayer> {
        const MockedRelayerFactory: ContractFactory = await ethers.getContractFactory("MockedRelayer");
        const relayer = await MockedRelayerFactory.deploy(
            sourceChainId,
            destChainId,
            this.signers.relayer.address
        ) as MockedRelayer;
        await relayer.waitForDeployment();
        
        this.relayer = relayer;
        return relayer;
    }

    async deployTargetContract(): Promise<MockTargetContract> {
        const MockTargetContractFactory: ContractFactory = await ethers.getContractFactory("MockTargetContract");
        const target = await MockTargetContractFactory.deploy() as MockTargetContract;
        await target.waitForDeployment();
        
        this.target = target;
        return target;
    }

    async setup(): Promise<TestSetup> {
        await this.initialize();
        const relayer = await this.deployRelayer();
        const target = await this.deployTargetContract();
        
        // Authorize senders
        await relayer.connect(this.signers.owner).authorizeSender(
            this.signers.sender.address, 
            true
        );
        await relayer.connect(this.signers.owner).authorizeSender(
            this.signers.user.address, 
            true
        );
        
        return {
            signers: this.signers,
            relayer,
            target
        };
    }

    async sendMessage(
        relayer: MockedRelayer,
        sender: SignerWithAddress,
        target: MockTargetContract,
        fee: bigint = this.RELAYER_FEE
    ): Promise<MessageResult> {
        const payload = ethers.toUtf8Bytes("Test Message");
        const tx = await relayer.connect(sender).sendMessage(
            await target.getAddress(),
            payload,
            { value: fee }
        );
        const receipt = await tx.wait();
        
        // Parse event from logs
        const event = receipt?.logs
            ?.map((log: any) => {
                try {
                    return relayer.interface.parseLog(log);
                } catch {
                    return null;
                }
            })
            ?.find((e: any) => e?.name === 'MessageSent');
        
        const messageId = event?.args?.messageId;
        
        return {
            messageId,
            receipt,
            payload: ethers.toUtf8String(payload)
        };
    }

    async relayMessage(
        relayer: MockedRelayer,
        relayerSigner: SignerWithAddress,
        messageId: bigint
    ): Promise<any> {
        const tx = await relayer.connect(relayerSigner).relayMessage(messageId);
        await tx.wait();
        return await relayer.getMessage(messageId);
    }

    async deliverMessage(
        relayer: MockedRelayer,
        relayerSigner: SignerWithAddress,
        messageId: bigint,
        target: MockTargetContract
    ): Promise<void> {
        const tx = await relayer.connect(relayerSigner).deliverMessageMock(
            messageId,
            await target.getAddress()
        );
        await tx.wait();
    }

    async increaseTime(seconds: number): Promise<void> {
        await ethers.provider.send("evm_increaseTime", [seconds]);
        await ethers.provider.send("evm_mine", []);
    }

    async getContractBalance(contract: Contract): Promise<bigint> {
        return await ethers.provider.getBalance(await contract.getAddress());
    }

    async getMessageStatus(
        relayer: MockedRelayer,
        messageId: bigint
    ): Promise<number> {
        const message = await relayer.getMessage(messageId);
        return Number(message.status);
    }

    async waitForEvent(
        contract: Contract,
        eventName: string,
        timeout: number = 60000
    ): Promise<EventLog[]> {
        return new Promise((resolve) => {
            const filter = contract.filters[eventName]();
            contract.on(filter, (...args: any[]) => {
                const event = args[args.length - 1];
                resolve([event]);
                contract.removeAllListeners();
            });
            
            // Timeout
            setTimeout(() => {
                contract.removeAllListeners();
                resolve([]);
            }, timeout);
        });
    }

    async assertEventEmitted(
        tx: any,
        contract: Contract,
        eventName: string,
        args?: Record<string, any>
    ): Promise<void> {
        const receipt = await tx.wait();
        const events = receipt?.logs
            ?.map((log: any) => {
                try {
                    return contract.interface.parseLog(log);
                } catch {
                    return null;
                }
            })
            ?.filter((e: any) => e?.name === eventName);
        
        expect(events).to.not.be.empty;
        
        if (args) {
            const event = events[0];
            for (const [key, value] of Object.entries(args)) {
                expect(event.args[key]).to.equal(value);
            }
        }
    }
}

// Export default instance
export default TestHelper;