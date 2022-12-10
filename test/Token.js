require("@nomicfoundation/hardhat-chai-matchers")
const { expect } = require("chai");
const keccak256 = require('keccak256')

const { ethers } = require("hardhat")

describe("deploy VotingContract", function () {
  let owner, user1, user2, user3
  let votingContract


  beforeEach(async function() {
    [owner, user1, user2, user3] = await ethers.getSigners()

      const VotingContract = await ethers.getContractFactory("VotingContract", owner)
      votingContract = await VotingContract.deploy()
      await votingContract.deployed()

      expect(await votingContract.balanceOf(owner.address)).to.eq(100000000)
  })

  it("User story 25for 35against 40for", async function () {
      // console.log('hello')
      // console.log(keccak256('hello'))
      let hash = keccak256("hello")
      // console.log(hash)

      await votingContract.transfer(user1.address, 25000000)
      expect(await votingContract.balanceOf(user1.address)).to.eq(25000000)
      await votingContract.transfer(user2.address, 35000000)
      expect(await votingContract.balanceOf(user2.address)).to.eq(35000000)
      await votingContract.createProposal(hash);
      
      await votingContract.connect(user1).voteFor(hash)
      await votingContract.connect(user2).voteAgainst(hash)
      const t =await votingContract.voteFor(hash)


      await expect(t)
              .to.emit(votingContract, "Accepted")
      

        
  })

  it("User story 25for 35against 24for, first revote to against", async function () {
    // console.log('hello')
    // console.log(keccak256('hello'))
    let hash = keccak256("hello")
    // console.log(hash)

    await votingContract.transfer(user1.address, 25000000)
    expect(await votingContract.balanceOf(user1.address)).to.eq(25000000)

    await votingContract.transfer(user2.address, 35000000)
    expect(await votingContract.balanceOf(user2.address)).to.eq(35000000)
    
    await votingContract.transfer(user3.address, 24000000)
    expect(await votingContract.balanceOf(user3.address)).to.eq(24000000)
    await votingContract.createProposal(hash);

    
    await votingContract.connect(user1).voteFor(hash)
    await votingContract.connect(user2).voteAgainst(hash)
    await votingContract.connect(user3).voteFor(hash)
    const t = await votingContract.connect(user1).voteAgainst(hash)

    await expect(t)
            .to.emit(votingContract, "Rejected")
    

      
})

it("Create 4 Proposals", async function () {
  // console.log('hello')
  // console.log(keccak256('hello'))
  let hash = keccak256("hello")
  let hash1 = keccak256("hello1")
  let hash2 = keccak256("hello2")
  let hash3 = keccak256("hello3")
//   console.log(hash)
//   console.log(hash1)
//   console.log(hash2)
//   console.log(hash3)
  
  // console.log(hash)

  await votingContract.transfer(user1.address, 25000000)
  expect(await votingContract.balanceOf(user1.address)).to.eq(25000000)

  await votingContract.transfer(user2.address, 35000000)
  expect(await votingContract.balanceOf(user2.address)).to.eq(35000000)
  
  await votingContract.transfer(user3.address, 24000000)
  expect(await votingContract.balanceOf(user3.address)).to.eq(24000000)

  await votingContract.createProposal(hash);
  await votingContract.createProposal(hash1);
  await votingContract.createProposal(hash2);
  
  
  await votingContract.connect(user1).voteFor(hash)
  await votingContract.connect(user2).voteAgainst(hash)
  await votingContract.connect(user3).voteFor(hash)
  const t = await votingContract.connect(user1).voteAgainst(hash)

  await expect(t)
          .to.emit(votingContract, "Rejected")
  
  await votingContract.createProposal(hash3);

  await votingContract.connect(user1).voteFor(hash3)
  await votingContract.connect(user2).voteAgainst(hash3)
  await votingContract.connect(user3).voteFor(hash3)
  const t1 = await votingContract.connect(user1).voteAgainst(hash3)

  await expect(t1)
          .to.emit(votingContract, "Rejected")
    
})


  it("Revert with must have tokens in snapshotId block", async function () {
    let hash = keccak256("hello")
    
    await votingContract.createProposal(hash);

    await votingContract.transfer(user1.address, 25000000)
    expect(await votingContract.balanceOf(user1.address)).to.eq(25000000)
    
   
    await expect(
      votingContract.connect(user1).voteFor(hash)
    ).to.be.revertedWith("must have tokens in snapshotId block");
           
  })

  it("Revert with balance must be > 0", async function () {
    
    let hash = keccak256("hello")

    await expect(
      votingContract.connect(user1).createProposal(hash)
    ).to.be.revertedWith("balance must be > 0 ");
           
    
  })

  it("Revert with Inactive", async function () {
    // console.log('hello')
    // console.log(keccak256('hello'))
    let hash = keccak256("hello")
    // console.log(hash)

    await votingContract.transfer(user1.address, 25000000)
    expect(await votingContract.balanceOf(user1.address)).to.eq(25000000)

    await votingContract.transfer(user2.address, 35000000)
    expect(await votingContract.balanceOf(user2.address)).to.eq(35000000)
    
    await votingContract.transfer(user3.address, 24000000)
    expect(await votingContract.balanceOf(user3.address)).to.eq(24000000)
    await votingContract.createProposal(hash);

    
    await votingContract.connect(user1).voteFor(hash)
    await votingContract.connect(user2).voteAgainst(hash)
    await votingContract.connect(user3).voteFor(hash)
    const t = await votingContract.connect(user1).voteAgainst(hash)

    await expect(t)
            .to.emit(votingContract, "Rejected")

    await expect(votingContract.voteFor(hash)).to.be.revertedWith("Inactive") 
  })

  it("Revert with such proposal already exists", async function () {
    // console.log('hello')
    // console.log(keccak256('hello'))
    let hash = keccak256("hello")
    let hash2= keccak256("hello")
    // console.log(hash)

   
    await votingContract.createProposal(hash);
    await expect(votingContract.createProposal(hash)).to.be.revertedWith("such proposal already exists")
  })

});
