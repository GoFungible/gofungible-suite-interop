// test/MockedRelayerWithHelper.test.ts
import { expect } from "chai";
import { ethers } from "hardhat";
import TestHelper from "./utils/testHelpers";
import { MessageStatus } from "./utils/types";

describe("MockedRelayer with Helper", function () {
    let helper: TestHelper;
    let signers: any;
    let relayer: any;
    let target: any;
    const RELAYER_FEE = ethers.parseEther("0.01");

    before(async function () {
        helper = new TestHelper();
        const setup = await helper.setup();
        
        signers = setup.signers;
        relayer = setup.relayer;
        target = setup.target;
    });

    describe("Using helper functions", function () {
        it("Should send message using helper", async function () {
            const result = await helper.sendMessage(
                relayer,
                signers.sender,
                target,
                RELAYER_FEE
            );
            
            expect(result.messageId).to.be.greaterThan(0);
            
            const message = await relayer.getMessage(result.messageId);
            expect(message.sender).to.equal(signers.sender.address);
            expect(message.status).to.equal(MessageStatus.Pending);
        });

        it("Should relay message using helper", async function () {
            const result = await helper.sendMessage(
                relayer,
                signers.sender,
                target,
                RELAYER_FEE
            );
            
            const message = await helper.relayMessage(
                relayer,
                signers.relayer,
                result.messageId
            );
            
            // Message status should be either Confirmed or Failed
            expect([MessageStatus.Confirmed, MessageStatus.Failed])
                .to.include(Number(message.status));
        });

        it("Should deliver message using helper", async function () {
            const result = await helper.sendMessage(
                relayer,
                signers.sender,
                target,
                RELAYER_FEE
            );
            
            await helper.relayMessage(
                relayer,
                signers.relayer,
                result.messageId
            );
            
            await helper.deliverMessage(
                relayer,
                signers.relayer,
                result.messageId,
                target
            );
            
            const message = await relayer.getMessage(result.messageId);
            expect(message.status).to.equal(MessageStatus.Confirmed);
        });

        it("Should assert event emission", async function () {
            const tx = await relayer.connect(signers.sender).sendMessage(
                await target.getAddress(),
                ethers.toUtf8Bytes("Event Test"),
                { value: RELAYER_FEE }
            );
            
            await helper.assertEventEmitted(
                tx,
                relayer,
                "MessageSent",
                { sender: signers.sender.address }
            );
        });

        it("Should handle time manipulation", async function () {
            const result = await helper.sendMessage(
                relayer,
                signers.sender,
                target,
                RELAYER_FEE
            );
            
            // Increase time beyond expiry
            await helper.increaseTime(3601);
            
            await expect(
                relayer.connect(signers.relayer).relayMessage(result.messageId)
            ).to.be.revertedWith("Relayer__ExpiredMessage");
        });

        it("Should get contract balance", async function () {
            const balance = await helper.getContractBalance(relayer);
            expect(balance).to.be.a('bigint');
        });

        it("Should get message status", async function () {
            const result = await helper.sendMessage(