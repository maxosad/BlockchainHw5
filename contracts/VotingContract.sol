// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";


contract VotingContract is ERC20Snapshot{
  

    constructor() ERC20("VotingToken", "VT") {
	    _mint(msg.sender, 100000000);
    }

    function decimals() public view override returns (uint8) {
	    return 6;
    }
 
    //NEUTRAL as default 
    enum Choice {NEUTRAL, POSITIVE, NEGATIVE}

    struct Proposal {
        uint votesFor;

        uint votesAgainst;

        uint endTimestamp;

        uint snapshotId;

        
    }

    
    event Accepted(uint indexed propHash);

    event Rejected(uint indexed propHash);

    event Discarded(uint indexed propHash);


    uint private constant TTL = 3 days;
    uint private constant MAX_PROP = 3;
    
    
    Proposal[MAX_PROP + 1] private _proposals;
    bool[MAX_PROP + 1] private _activness;
    mapping(uint => mapping(address => Choice) ) voted;

    //idFromHash[any] = 0 thet's why we don't use index 0
    mapping (uint => uint) idFromHash;
    mapping (uint => uint) hashFromId;

    
    function chiceOfAddressAtProposal(uint prop, address addr) public view returns(Choice){
        return voted[prop][addr];
    }


    function activness() public view returns(bool[3] memory ){
        return [_activness[1],_activness[2],_activness[3]];

    }


   

    //owner could mint more tokens, so we need to know majority at snapshot
    function _getTargetValAT(uint snapshot) internal returns(uint){
        return totalSupplyAt(snapshot) / 2;
    }

    // discard when time runs out and we are asked to add new proposal 
    function tryDiscard() public {
        for (uint i = 1; i <= MAX_PROP; i++) {
            if (_activness[i] && _proposals[i].endTimestamp < block.timestamp) {
                _activness[i] = false;
                emit Discarded(hashFromId[i]);
            }
        }
    }


    modifier tokenOwner {
        require(balanceOf(msg.sender) > 0, "balance must be > 0 ");
        _;
    }

    modifier notExist(uint propHash) {
        require(idFromHash[propHash] == 0 , "such proposal already exists");
        _;
    }

    //toekn owner create new proposal if not exist such hash
    function createProposal(uint propHash) external tokenOwner notExist(propHash) {
        tryDiscard();

        for (uint i = 1; i <= MAX_PROP; i++) {
            if (!_activness[i]) {
                _proposals[i] = Proposal(0, 0, block.timestamp + TTL, _snapshot());
                idFromHash[propHash] = i; 
                hashFromId[i] = propHash;
                _activness[i] = true;
                break;
            }
        }
    }
    



    modifier hasTokensAtSnapshot(uint propHash) {
        require(balanceOfAt(msg.sender, _proposals[idFromHash[propHash]].snapshotId) > 0, "must have tokens in snapshotId block");
        _;
    }

    // 
    modifier active(uint propHash) {
        require(_activness[idFromHash[propHash]] , "Inactive");
        _;
    }

    function voteFor(uint propHash) external hasTokensAtSnapshot(propHash) active(propHash){
        tryDiscard();
        uint id = idFromHash[propHash];
        address sender = msg.sender;
        Choice choice = voted[propHash][sender];
        uint snapshotid = _proposals[id].snapshotId;


        if (choice == Choice.NEUTRAL) {
             //if sender didn't vote before
            voted[propHash][sender] = Choice.POSITIVE;
            _proposals[id].votesFor += balanceOfAt(sender, snapshotid);
        } else if (choice == Choice.NEGATIVE) {
            //if sender want to change his choice to opposite
            voted[propHash][sender] = Choice.POSITIVE;
            uint balance = balanceOfAt(sender, snapshotid);
            _proposals[id].votesFor += balance;
            _proposals[id].votesAgainst -= balance;
        }

        
        // if we achieved a majority of votes we Accept the proposal
        if(_proposals[id].votesFor > _getTargetValAT(snapshotid)){
            _activness[id] = false;
            emit Accepted(propHash);
        }
    }


    function voteAgainst(uint propHash) external hasTokensAtSnapshot(propHash) active(propHash){
        tryDiscard();
        uint id = idFromHash[propHash];
        address sender = msg.sender;
        Choice choice = voted[propHash][sender];
        uint snapshotid = _proposals[id].snapshotId;

        
        if (choice == Choice.NEUTRAL) {
            //if sender didn't vote before
            voted[propHash][sender] = Choice.NEGATIVE;
            _proposals[id].votesAgainst += balanceOfAt(sender, snapshotid);
        } else if (choice == Choice.POSITIVE) {
            //if sender want to change his choice to opposite
            voted[propHash][sender] = Choice.NEGATIVE;
            uint balance = balanceOfAt(sender, snapshotid);
            _proposals[id].votesAgainst += balance;
            _proposals[id].votesFor -= balance;
        }
        
        // if we achieved a majority of votes we reject the proposal
        if(_proposals[id].votesAgainst > _getTargetValAT(snapshotid)){
            _activness[id] = false;
            emit Rejected(propHash);
        }
    }
}