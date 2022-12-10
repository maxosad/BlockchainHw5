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
        int votes;

        uint endTimestamp;

        uint snapshotId;

        mapping(address => Choice) voted;
    }

    
    event Accepted(uint indexed propHash);

    event Rejected(uint indexed propHash);

    event Discarded(uint indexed propHash);

    uint private constant TTL = 3 days;
    uint private constant MAX_PROP = 3;
    
    Proposal[MAX_PROP] private _proposals;
    bool[MAX_PROP] private _activness;



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



    // function tryFinalize() public {
    //     for (uint i = 0; i < MAX_PROP; i++) {
    //         if (_activness) {
    //             if (_proposals[i].endTimestamp < block.timestamp) {
    //                 _activness[i] = false;
    //                 emit Discarded(hashFromId[i]);
    //             } else if(_proposals[i].votesFor > _getTargetValAT(_proposals[i].snapshotId)){
    //                 _activness[i] = false;
    //                 emit Accepted(hashFromId[i]);
    //             } else if(_proposals[i].votesAgainst > _getTargetValAT(_proposals[i].snapshotId)){
    //                 _activness[i] = false;
    //                 emit Rejected(hashFromId[i]);
    //             }
    //         }
    //     }
    // }

    function tryDiscard() public {
        for (uint i = 0; i < MAX_PROP; i++) {
            if (_activness && _proposals[i].endTimestamp < block.timestamp) {
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
                _proposals[i] = Proposal(0, block.timestamp + TTL, _snapshot());
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
        Choice choice = _proposals[id].voted(sender);
        uint snapshotid = _proposals[id].snapshotId;

        if(!_activness[id]) {
            revert();
        }
        
        //first change flag then change state
        if (choice == Choice.NEUTRAL) {
            _proposals[id].voted(sender) = Choice.POSITIVE;
            _proposals[id].voteFor += balanceOfAt(sender, snapshotid);
        } else if (choice == Choice.NEGATIVE) {
            _proposals[id].voted(sender) = Choice.POSITIVE;
            _proposals[id].voteFor += 2 * balanceOfAt(sender,snapshotid);
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
        Choice choice = _proposals[id].voted(sender) ;
        uint snapshotid = _proposals[id].snapshotId;

        if(!_activness[id]) {
            revert();
        }
        
        //first change flag then change state
        if (choice == Choice.NEUTRAL) {
            _proposals[id].voted(sender) = Choice.NEGATIVE;
            _proposals[id].voteFor -= balanceOfAt(sender,snapshotid);

        } else if (choice == Choice.POSITIVE) {
            _proposals[id].voted(sender) = Choice.POSITIVE;
            _proposals[id].voteFor -= 2 * balanceOfAt(sender,snapshotid);
        }

        if(_proposals[id].votesFor > _getTargetValAT(snapshotid)){
            _activness[id] = false;
            emit Rejected(propHash);
        }
    }


   //emit Discarded(d);

}