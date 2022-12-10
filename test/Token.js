require("@nomicfoundation/hardhat-chai-matchers")
const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("Swap", function () {
    let owner

  it("Create Token, Create Pair, Swap", async function () {
        [owner] = await ethers.getSigners()

        const MyToken = await ethers.getContractFactory("VotingContract", owner)
        const myToken = await MyToken.deploy()
        await myToken.deployed()

        console.log(await myToken.balanceOf(owner.address))
        expect(await myToken.balanceOf(owner.address)).to.eq(100000000)
  })
});