require("@nomicfoundation/hardhat-chai-matchers")
const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("Swap", function () {
    let owner, user1, user2 



    beforeEach(async function() {
      [owner, user1, user2] = await ethers.getSigners()

        const VotingContract = await ethers.getContractFactory("VotingContract", owner)
        const votingContract = await VotingContract.deploy()
        await votingContract.deployed()

        expect(await myToken.balanceOf(owner.address)).to.eq(100000000)
  })

  it("Create Token, Create Pair, Swap", async function () {
        [owner] = await ethers.getSigners()

        const VotingContract = await ethers.getContractFactory("VotingContract", owner)
        const votingContract = await VotingContract.deploy()
        await votingContract.deployed()

        expect(await myToken.balanceOf(owner.address)).to.eq(100000000)
  })
});