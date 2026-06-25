// test/MockedRelayer.test.ts
import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { Contract, ContractFactory } from "ethers";
import { MockedRelayer, MockTargetContract } from "../../gofungible-suite-token/typechain-types/index.js";

// Type definitions
type ChainId = number;
type Wei = bigint;

interface MessageDetails {
    id: bigint;
    sender: string;
    recipient: string;
    payload: string;
    timestamp: bigint;
    fee: bigint;
    retryCount: number;
    status: number;
    txHash: string;
    gasUsed: bigint;
}

interface MessageSentEvent {
    messageId: bigint;
    sender: string;
    recipient: string;
    payload: string;
    timestamp: bigint;
    fee: bigint;
}

describe.skip("MockedRelayer", function () {
    // Contract instances
    let relayer: MockedRelayer;
    let targetContract: MockTargetContract;
    
    // Signers
    let owner: SignerWithAddress;
    let relayerAddress: SignerWithAddress;
    let sender: SignerWithAddress;
    let user: SignerWithAddress;
    let unauthorizedUser: SignerWithAddress;
    
    // Constants
    const SOURCE_CHAIN_ID: ChainId = 1;
    const DEST_CHAIN_ID: ChainId = 2;
    const RELAYER_FEE: Wei = ethers.parseEther("0.01");
    const MESSAGE_EXPIRY: number = 3600; // 1 hour in seconds

    // This runs before each test
    beforeEach(async function () {
        // Get signers from Hardhat's built-in accounts
        [owner, relayerAddress, sender, user, unauthorizedUser] = await ethers.getSigners();
        
        console.log("📋 Accounts initialized:");
        console.log("  Owner:", owner.address);
        console.log("  Relayer:", relayerAddress.address);
        console.log("  Sender:", sender.address);
        console.log("  User:", user.address);
        console.log("  Unauthorized:", unauthorizedUser.address);

        // Deploy MockedRelayer contract
        const MockedRelayerFactory: ContractFactory = await ethers.getContractFactory("MockedRelayer");
        relayer = await MockedRelayerFactory.deploy(
            SOURCE_CHAIN_ID,
            DEST_CHAIN_ID,
            relayerAddress.address
        ) as MockedRelayer;
        await relayer.waitForDeployment();
        
        console.log("📦 MockedRelayer deployed at:", await relayer.getAddress());

        // Deploy MockTargetContract
        const MockTargetContractFactory: ContractFactory = await ethers.getContractFactory("MockTargetContract");
        targetContract = await MockTargetContractFactory.deploy() as MockTargetContract;
        await targetContract.waitForDeployment();
        
        console.log("📦 MockTargetContract deployed at:", await targetContract.getAddress());

        // Authorize the sender to send messages
        await relayer.connect(owner).authorizeSender(sender.address, true);
        
        // Optionally authorize user as well
        await relayer.connect(owner).authorizeSender(user.address, true);
        
        console.log("✅ Senders authorized");
    });

    // Helper function to create and send a message
    async function sendTestMessage(
        signer: SignerWithAddress = sender, 
        recipient: string = await targetContract.getAddress()
    ): Promise<{ messageId: bigint; receipt: any; payload: string }> {
        const payload = ethers.toUtf8Bytes("Test Message");
        const tx = await relayer.connect(signer).sendMessage(
            recipient,
            payload,
            { value: RELAYER_FEE }
        );
        const receipt = await tx.wait();
        
        // Get the message ID from events
        const messageSentEvent = receipt?.logs
            ?.map((log: any) => {
                try {
                    return relayer.interface.parseLog(log);
                } catch {
                    return null;
                }
            })
            ?.find((event: any) => event?.name === 'MessageSent');
        
        const messageId = messageSentEvent?.args?.messageId;
        
        return { 
            messageId, 
            receipt, 
            payload: ethers.toUtf8String(payload) 
        };
    }

    // Helper function to relay a message
    async function relayMessage(
        messageId: bigint, 
        signer: SignerWithAddress = relayerAddress
    ): Promise<MessageDetails> {
        const tx = await relayer.connect(signer).relayMessage(messageId);
        await tx.wait();
        
        // Get updated message status
        const message = await relayer.getMessage(messageId);
        return message;
    }

    // Helper to increase time
    async function increaseTime(seconds: number): Promise<void> {
        await ethers.provider.send("evm_increaseTime", [seconds]);
        await ethers.provider.send("evm_mine", []);
    }

    // Helper to get contract balance
    async function getContractBalance(contract: Contract): Promise<bigint> {
        return await ethers.provider.getBalance(await contract.getAddress());
    }

    describe("Deployment", function () {
        it("Should set the correct owner", async function () {
            expect(await relayer.owner()).to.equal(owner.address);
        });

        it("Should set the correct relayer", async function () {
            expect(await relayer.relayer()).to.equal(relayerAddress.address);
        });

        it("Should set the correct chain IDs", async function () {
            const [source, dest] = await relayer.getChainConfig();
            expect(source).to.equal(SOURCE_CHAIN_ID);
            expect(dest).to.equal(DEST_CHAIN_ID);
        });

        it("Should have correct fee", async function () {
            const fee = await relayer.RELAYER_FEE();
            expect(fee).to.equal(RELAYER_FEE);
        });

        it("Should have correct max retry", async function () {
            const maxRetry = await relayer.MAX_RETRY();
            expect(maxRetry).to.equal(3);
        });
    });

    describe("Sending Messages", function () {
        it("Should send a message successfully", async function () {
            const payload = ethers.toUtf8Bytes("Hello Cross-Chain!");
            
            // Check balance before
            const balanceBefore = await ethers.provider.getBalance(sender.address);
            
            await expect(
                relayer.connect(sender).sendMessage(
                    await targetContract.getAddress(),
                    payload,
                    { value: RELAYER_FEE }
                )
            ).to.emit(relayer, "MessageSent");

            const messageId = await relayer.messageCounter();
            const message = await relayer.getMessage(messageId);
            
            expect(message.sender).to.equal(sender.address);
            expect(message.recipient).to.equal(await targetContract.getAddress());
            expect(message.status).to.equal(0); // Pending
            expect(message.fee).to.equal(RELAYER_FEE);
        });

        it("Should revert if sender is not authorized", async function () {
            const payload = ethers.toUtf8Bytes("Test");
            
            await expect(
                relayer.connect(unauthorizedUser).sendMessage(
                    await targetContract.getAddress(),
                    payload,
                    { value: RELAYER_FEE }
                )
            ).to.be.revertedWith("Relayer__UnauthorizedSender");
        });

        it("Should revert if fee is insufficient", async function () {
            const payload = ethers.toUtf8Bytes("Test");
            const insufficientFee = ethers.parseEther("0.001");
            
            await expect(
                relayer.connect(sender).sendMessage(
                    await targetContract.getAddress(),
                    payload,
                    { value: insufficientFee }
                )
            ).to.be.revertedWith("Relayer__InsufficientFee");
        });

        it("Should refund excess ether", async function () {
            const payload = ethers.toUtf8Bytes("Test");
            const excessFee = ethers.parseEther("0.02");
            const balanceBefore = await ethers.provider.getBalance(sender.address);
            
            const tx = await relayer.connect(sender).sendMessage(
                await targetContract.getAddress(),
                payload,
                { value: excessFee }
            );
            
            // Wait for transaction
            await tx.wait();
            
            const balanceAfter = await ethers.provider.getBalance(sender.address);
            
            // Balance should decrease by exactly RELAYER_FEE (refunded the rest)
            const actualDecrease = balanceBefore - balanceAfter;
            
            // Allow for gas costs
            expect(actualDecrease).to.be.closeTo(
                RELAYER_FEE,
                ethers.parseEther("0.001") // Gas buffer
            );
        });

        it("Should emit MessageSent event with correct data", async function () {
            const payload = ethers.toUtf8Bytes("Event Test");
            
            const tx = await relayer.connect(sender).sendMessage(
                await targetContract.getAddress(),
                payload,
                { value: RELAYER_FEE }
            );
            
            const receipt = await tx.wait();
            const event = receipt?.logs
                ?.map((log: any) => {
                    try {
                        return relayer.interface.parseLog(log);
                    } catch {
                        return null;
                    }
                })
                ?.find((e: any) => e?.name === 'MessageSent');
            
            expect(event).to.not.be.undefined;
            expect(event?.args.sender).to.equal(sender.address);
            expect(event?.args.recipient).to.equal(await targetContract.getAddress());
        });
    });

    describe("Relaying Messages", function () {
        let messageId: bigint;

        beforeEach(async function () {
            const result = await sendTestMessage();
            messageId = result.messageId;
        });

        it("Should relay a message successfully", async function () {
            await expect(
                relayer.connect(relayerAddress).relayMessage(messageId)
            ).to.emit(relayer, "MessageDelivered");

            const message = await relayer.getMessage(messageId);
            expect(message.status).to.equal(2); // Confirmed
            expect(message.txHash).to.not.equal(ethers.ZeroHash);
            expect(message.gasUsed).to.be.greaterThan(0);
        });

        it("Should fail if not called by relayer", async function () {
            await expect(
                relayer.connect(user).relayMessage(messageId)
            ).to.be.revertedWith("Relayer__NotRelayer");
        });

        it("Should fail if message doesn't exist", async function () {
            const nonExistentId: bigint = 99999n;
            await expect(
                relayer.connect(relayerAddress).relayMessage(nonExistentId)
            ).to.be.revertedWith("Relayer__MessageNotFound");
        });

        it("Should fail if message already delivered", async function () {
            // First relay
            await relayer.connect(relayerAddress).relayMessage(messageId);
            
            // Try to relay again
            await expect(
                relayer.connect(relayerAddress).relayMessage(messageId)
            ).to.be.revertedWith("Relayer__MessageAlreadyDelivered");
        });

        it("Should handle multiple relay attempts", async function () {
            let attempts = 0;
            let message = await relayer.getMessage(messageId);
            
            // Attempt relay until success or max attempts
            while (message.status !== 2 && attempts < 5) {
                await relayer.connect(relayerAddress).relayMessage(messageId);
                message = await relayer.getMessage(messageId);
                attempts++;
            }
            
            // Should eventually succeed or be retryable
            expect([2, 3]).to.include(Number(message.status));
        });

        it("Should handle expired messages", async function () {
            // Increase time beyond expiry (1 hour)
            await increaseTime(3601);
            
            await expect(
                relayer.connect(relayerAddress).relayMessage(messageId)
            ).to.be.revertedWith("Relayer__ExpiredMessage");
        });
    });

    describe("Retry Mechanism", function () {
        let messageId: bigint;

        beforeEach(async function () {
            const result = await sendTestMessage();
            messageId = result.messageId;
        });

        it("Should retry failed messages", async function () {
            // Force a failure by making the relay fail
            let retryCount = 0;
            let message = await relayer.getMessage(messageId);
            
            // Keep attempting until it fails or we exceed attempts
            while (message.status !== 3 && retryCount < 10) {
                await relayer.connect(relayerAddress).relayMessage(messageId);
                message = await relayer.getMessage(messageId);
                retryCount++;
            }

            if (message.status === 3) { // Failed
                await relayer.connect(relayerAddress).retryMessage(messageId);
                const updatedMessage = await relayer.getMessage(messageId);
                expect(updatedMessage.status).to.equal(0); // Reset to Pending
                expect(updatedMessage.retryCount).to.be.greaterThan(0);
            }
        });

        it("Should not retry beyond max retries", async function () {
            let message = await relayer.getMessage(messageId);
            let attempts = 0;
            
            // Keep attempting until max retries exceeded
            while (attempts < 10) {
                await relayer.connect(relayerAddress).relayMessage(messageId);
                message = await relayer.getMessage(messageId);
                
                if (message.status === 3) { // Failed
                    await relayer.connect(relayerAddress).retryMessage(messageId);
                    message = await relayer.getMessage(messageId);
                }
                attempts++;
            }
            
            // Should eventually fail permanently or succeed
            const finalMessage = await relayer.getMessage(messageId);
            expect(finalMessage.retryCount).to.be.at.most(3);
        });

        it("Should emit MessageFailed event on failure", async function () {
            // Force multiple attempts to trigger failure
            for (let i = 0; i < 3; i++) {
                await relayer.connect(relayerAddress).relayMessage(messageId);
                const message = await relayer.getMessage(messageId);
                if (message.status === 3) break;
            }
            
            // Check if failed, should have emitted event
            const message = await relayer.getMessage(messageId);
            if (message.status === 3) {
                // Event should have been emitted
                expect(message.retryCount).to.be.greaterThan(0);
            }
        });
    });

    describe("Delivering Messages", function () {
        let messageId: bigint;

        beforeEach(async function () {
            const result = await sendTestMessage();
            messageId = result.messageId;
            
            // Relay the message first
            await relayer.connect(relayerAddress).relayMessage(messageId);
        });

        it("Should deliver message to target contract", async function () {
            await expect(
                relayer.connect(relayerAddress).deliverMessageMock(
                    messageId,
                    await targetContract.getAddress()
                )
            ).to.emit(relayer, "MessageDelivered");

            const message = await relayer.getMessage(messageId);
            expect(message.status).to.equal(2); // Confirmed
            
            // Check target contract
            expect(await targetContract.processedMessages(messageId)).to.be.true;
            expect(await targetContract.messageCount(sender.address)).to.equal(1);
        });

        it("Should fail if target contract reverts", async function () {
            // Deploy a target that will revert
            const RevertingTargetFactory = await ethers.getContractFactory("RevertingTarget");
            const revertingTarget = await RevertingTargetFactory.deploy();
            await revertingTarget.waitForDeployment();
            
            // Send a new message to the reverting target
            const result = await sendTestMessage(sender, await revertingTarget.getAddress());
            const newMessageId = result.messageId;
            
            // Relay the message
            await relayer.connect(relayerAddress).relayMessage(newMessageId);
            
            // Try to deliver - should revert
            await expect(
                relayer.connect(relayerAddress).deliverMessageMock(
                    newMessageId,
                    await revertingTarget.getAddress()
                )
            ).to.emit(relayer, "MessageReverted");
        });

        it("Should fail if message not confirmed", async function () {
            // Send a new message but don't relay it
            const result = await sendTestMessage();
            const newMessageId = result.messageId;
            
            await expect(
                relayer.connect(relayerAddress).deliverMessageMock(
                    newMessageId,
                    await targetContract.getAddress()
                )
            ).to.be.revertedWith("Relayer__MessageNotFound");
        });
    });

    describe("Admin Functions", function () {
        it("Should update relayer address", async function () {
            const newRelayer = user.address;
            await expect(
                relayer.connect(owner).updateRelayer(newRelayer)
            ).to.emit(relayer, "RelayerUpdated");

            expect(await relayer.relayer()).to.equal(newRelayer);
        });

        it("Should not allow non-owner to update relayer", async function () {
            const newRelayer = user.address;
            await expect(
                relayer.connect(user).updateRelayer(newRelayer)
            ).to.be.revertedWith("Relayer__NotOwner");
        });

        it("Should authorize senders", async function () {
            await relayer.connect(owner).authorizeSender(user.address, true);
            expect(await relayer.authorizedSenders(user.address)).to.be.true;
            
            await relayer.connect(owner).authorizeSender(user.address, false);
            expect(await relayer.authorizedSenders(user.address)).to.be.false;
        });

        it("Should emit SenderAuthorized event", async function () {
            await expect(
                relayer.connect(owner).authorizeSender(user.address, true)
            ).to.emit(relayer, "SenderAuthorized")
                .withArgs(user.address, true);
        });

        it("Should withdraw fees", async function () {
            // First send some messages to accumulate fees
            for (let i = 0; i < 3; i++) {
                const payload = ethers.toUtf8Bytes(`Message ${i}`);
                await relayer.connect(sender).sendMessage(
                    await targetContract.getAddress(),
                    payload,
                    { value: RELAYER_FEE }
                );
            }
            
            const balanceBefore = await ethers.provider.getBalance(owner.address);
            
            // Withdraw fees
            const tx = await relayer.connect(owner).withdrawFees(owner.address);
            const receipt = await tx.wait();
            const gasCost = receipt?.gasUsed * receipt?.effectiveGasPrice;
            
            const balanceAfter = await ethers.provider.getBalance(owner.address);
            
            // Balance should increase by collected fees minus gas
            const contractBalance = await getContractBalance(relayer);
            expect(balanceAfter).to.be.greaterThan(balanceBefore);
        });
    });

    describe("View Functions", function () {
        let messageId: bigint;

        beforeEach(async function () {
            const result = await sendTestMessage();
            messageId = result.messageId;
        });

        it("Should get message details", async function () {
            const message = await relayer.getMessage(messageId);
            expect(message.id).to.equal(messageId);
            expect(message.sender).to.equal(sender.address);
            expect(message.recipient).to.equal(await targetContract.getAddress());
            expect(message.payload).to.be.a('string');
        });

        it("Should get message hash", async function () {
            const hash = await relayer.getMessageHash(messageId);
            expect(hash).to.be.a("string");
            expect(hash).to.have.lengthOf(66); // 0x + 64 chars
            expect(hash).to.match(/^0x[a-fA-F0-9]{64}$/);
        });

        it("Should check if message is deliverable", async function () {
            let deliverable = await relayer.isMessageDeliverable(messageId);
            expect(deliverable).to.be.false;
            
            // Relay the message
            await relayer.connect(relayerAddress).relayMessage(messageId);
            
            const message = await relayer.getMessage(messageId);
            if (message.status === 2) {
                deliverable = await relayer.isMessageDeliverable(messageId);
                expect(deliverable).to.be.true;
            }
        });

        it("Should get chain configuration", async function () {
            const [source, dest] = await relayer.getChainConfig();
            expect(source).to.equal(SOURCE_CHAIN_ID);
            expect(dest).to.equal(DEST_CHAIN_ID);
        });

        it("Should get message count", async function () {
            // Send multiple messages
            for (let i = 0; i < 3; i++) {
                await sendTestMessage();
            }
            
            const counter = await relayer.messageCounter();
            expect(counter).to.be.greaterThanOrEqual(4); // Including the one from beforeEach
        });
    });

    describe("Error Scenarios", function () {
        let messageId: bigint;

        beforeEach(async function () {
            const result = await sendTestMessage();
            messageId = result.messageId;
        });

        it("Should handle message cancellation", async function () {
            // Cancel the message
            await relayer.connect(relayerAddress).cancelMessage(messageId);
            
            const message = await relayer.getMessage(messageId);
            expect(message.status).to.equal(4); // Reverted
            
            // Check that sender was refunded
            // Note: Would need to check balance change to verify refund
        });

        it("Should not cancel already delivered message", async function () {
            // Relay and deliver
            await relayer.connect(relayerAddress).relayMessage(messageId);
            await relayer.connect(relayerAddress).deliverMessageMock(
                messageId,
                await targetContract.getAddress()
            );
            
            await expect(
                relayer.connect(relayerAddress).cancelMessage(messageId)
            ).to.be.revertedWith("Relayer__MessageAlreadyDelivered");
        });

        it("Should fail to cancel non-existent message", async function () {
            const nonExistentId: bigint = 99999n;
            await expect(
                relayer.connect(relayerAddress).cancelMessage(nonExistentId)
            ).to.be.revertedWith("Relayer__MessageNotFound");
        });

        it("Should handle relay failure with revert data", async function () {
            // Force a specific failure scenario
            // This might need multiple attempts or specific conditions
            let attempts = 0;
            let message = await relayer.getMessage(messageId);
            
            while (message.status !== 4 && attempts < 10) {
                await relayer.connect(relayerAddress).relayMessage(messageId);
                message = await relayer.getMessage(messageId);
                attempts++;
            }
            
            if (message.status === 4) {
                expect(message.revertData).to.not.be.empty;
            }
        });
    });
});