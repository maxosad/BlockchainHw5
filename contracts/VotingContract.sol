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
    
    Proposal[MAX_PROP] private _proposals;
    bool[MAX_PROP] private _activness;
    mapping(uint => mapping(address => Choice) ) voted;


    mapping (uint => uint) idFromHash;
    mapping (uint => uint) hashFromId;

    modifier tokenOwner {
        require(balanceOf(msg.sender) > 0);
        _;
    }


        // uint bts = block.timestamp;
        // uint tv = _getTargetVal();
        // bool f = false;


    function _getTargetValAT(uint snapshot) internal returns(uint){
        return totalSupplyAt(snapshot) / 2;
    }

    function tryDiscard() public {
        for (uint i = 0; i < MAX_PROP; i++) {
            if (_activness[i] && _proposals[i].endTimestamp < block.timestamp) {
                _activness[i] = false;
                emit Discarded(hashFromId[i]);
            }
        }
    }


    //create new proposal 
    function _createProposal(uint propHash) external tokenOwner {
        tryDiscard();

        for (uint i = 0; i < MAX_PROP; i++) {
            if (!_activness[i]) {
                _proposals[i] = Proposal(0, 0, block.timestamp + TTL, _snapshot());
                idFromHash[propHash] = i; 
                hashFromId[i] = propHash;
                break;
            }
        }
    }
    



    modifier hasTokensAtSnapshot(uint propHash) {
        require(balanceOfAt(msg.sender, _proposals[idFromHash[propHash]].snapshotId) > 0);
        _;
    }

    function voteFor(uint propHash) external hasTokensAtSnapshot(propHash) {
        tryDiscard();
        uint id = idFromHash[propHash];
        address sender = msg.sender;
        Choice choice = voted[propHash][sender];
        uint snapshotid = _proposals[id].snapshotId;

        if(!_activness[id]) {
            revert();
        }
        
        //first change flag then change state
        if (choice == Choice.NEUTRAL) {
            voted[propHash][sender] = Choice.POSITIVE;
            _proposals[id].votesFor += balanceOfAt(sender, snapshotid);
        } else if (choice == Choice.NEGATIVE) {
            voted[propHash][sender] = Choice.POSITIVE;
            uint balance = balanceOfAt(sender, snapshotid);
            _proposals[id].votesFor += balance;
            _proposals[id].votesAgainst -= balance;
        }

        
        
        if(_proposals[id].votesFor > _getTargetValAT(snapshotid)){
            _activness[id] = false;
            emit Accepted(propHash);
        }
    }

    function voteAgainst(uint propHash) external hasTokensAtSnapshot(propHash) {
        tryDiscard();
        uint id = idFromHash[propHash];
        address sender = msg.sender;
        Choice choice = voted[propHash][sender];
        uint snapshotid = _proposals[id].snapshotId;

        if(!_activness[id]) {
            revert();
        }
        
        //first change flag then change state
        if (choice == Choice.NEUTRAL) {
            voted[propHash][sender] = Choice.NEGATIVE;
            _proposals[id].votesAgainst += balanceOfAt(sender, snapshotid);
        } else if (choice == Choice.POSITIVE) {
            voted[propHash][sender] = Choice.NEGATIVE;
            uint balance = balanceOfAt(sender, snapshotid);
            _proposals[id].votesAgainst += balance;
            _proposals[id].votesFor -= balance;
        }

        
        
        
        if(_proposals[id].votesAgainst > _getTargetValAT(snapshotid)){
            _activness[id] = false;
            emit Rejected(propHash);
        }
    }


   //emit Discarded(d);

}