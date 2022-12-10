


```
put your key in .env
.env example 
ALCHEMY_API_KEY=123456789qwertyuiasdfghjkzxcvbnw
```

```
npm install keccak256
npm install dotenv
npm install @openzeppelin/contracts
npm install --save-dev hardhat 
npx hardhat
```
```
Then run the command that prompts
npx hardhat test


  deploy VotingContract
    √ User story 25for 35against 40for (171ms)
    √ User story 25for 35against 24for, first revote to against (184ms)
    √ Create 4 Proposals (312ms)
    √ Revert with must have tokens in snapshotId block (83ms)
    √ Revert with balance must be > 0
    √ Revert with Inactive (165ms)
    √ Revert with such proposal already exists


  7 passing (9s)


```

```
Contract for voting
one token - 1 vote
Votes are counted at the time the proposal is created
You can re-vote until a majority of votes is gained
If a majority of votes is received, the proposal is closed
Anyone who has tokens can create a proposal 
The proposal is created for 3 days
If the Proposal did not manage to get a majority of votes, then it is deleted
While 3 offers are active, other offers cannot be created

```
