// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
// pragma solidity 0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    uint proposalId;
    uint winningProposalId;
    bool registerSessionStarted;
    bool votingSessionStarted;
   
    Proposal[] proposals;

    mapping(address => bool) whiteList;
    mapping (address => Voter) voters;


    struct Proposal {
        address proposer;
        string description;
        uint voteCount;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    constructor() Ownable(msg.sender) {
    registerSessionStarted = false;
    votingSessionStarted = false;
    proposalId = 0;
    winningProposalId = 0;
    whiteList[msg.sender] = true;
    voters[msg.sender].isRegistered = true;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    function registerVoter(address _addr) public onlyOwner {
        require(!whiteList[_addr], "Voter already added");
        whiteList[_addr] = true;
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }


    // Proposal registration starts and ends
    function registerStart() public onlyOwner {
        require(!registerSessionStarted, "Proposal registeration session has already started");
        registerSessionStarted = true;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function registerEnd() public onlyOwner {
        require(registerSessionStarted, "Proposal registeration session has not started yet");
        registerSessionStarted = false;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    // Authorizes whitelisted electors to register one or several proposals during the registration session
    function registerProposal(string memory _description) public onlyOwner {
        require(registerSessionStarted, "Proposal registeration session is closed");
        require(voters[msg.sender].isRegistered, "You are not allowed to register any proposals");
        
        Proposal memory newProposal = Proposal(msg.sender, _description, 0);
        proposals.push(newProposal);
        proposalId ++;

        emit ProposalRegistered(proposalId); 
    }

    // Voting session starts
    function votingStart() public onlyOwner {
        require(!votingSessionStarted, "Voting session is already open");
        require(!registerSessionStarted, "Register session is still open");
        require(proposals.length > 0, "There is no proposal to vote for");
        votingSessionStarted = true;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    // Voting session ends
    function votingEnd() public onlyOwner {
        require(votingSessionStarted, "Voting session is already closed");
        votingSessionStarted = false;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    // One elector can vote for one proposal
    function vote(uint _proposalId) public {
        require(voters[msg.sender].isRegistered, "You are not allowed to vote");
        require(!voters[msg.sender].hasVoted, "You've already voted");
        require(_proposalId < proposals.length, "Invalid proposal ID");

        proposals[_proposalId].voteCount ++;

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;

        emit Voted(msg.sender, _proposalId);
    }

    function countVote() public onlyOwner returns(uint) {
        require(!votingSessionStarted, "Voting session is still open");
        require(!registerSessionStarted, "Register session is still open");
        require(proposals.length > 0, "There is no proposal to vote for");

        uint winnersVoteCount = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winnersVoteCount) {
                proposalId = i;
                winnersVoteCount = proposals[i].voteCount;
                winningProposalId = proposalId + 1;
            }
        }
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        return winningProposalId;
    }

    // Everybody can verify details about the winning proposal

    function showWinningProposal() public view returns (uint, string memory, uint, address) {
        address winnerAddress = proposals[winningProposalId-1].proposer;
        string memory winnerProposal = proposals[winningProposalId-1].description;
        uint winnerProposalVoteCount = proposals[winningProposalId-1].voteCount;

        return (winningProposalId, winnerProposal, winnerProposalVoteCount, winnerAddress);
    }
}
