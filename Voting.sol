// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    uint winningProposalId;

    struct Proposal {
        address proposer;
        string description;
        uint voteCount;
        uint proposalId;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    // Array of proposal structs
    Proposal[] private proposals;

    // The state variable of the Enum type 
    WorkflowStatus public state;

    mapping(address => bool) private whitelist;
    mapping (address => Voter) private voters;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    constructor() Ownable(msg.sender) {
    whitelist[msg.sender] = true;
    voters[msg.sender].isRegistered = true;
    state = WorkflowStatus.RegisteringVoters;
    }

    modifier onlyVoters {
        require (whitelist[msg.sender], "Only whitelisted voters can access to this function");
        _;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Admin registers voter adresses
    function registerVoter(address _addr) public onlyOwner {
        require(state == WorkflowStatus.RegisteringVoters, "Voter registering is only permissed in the beginning");
        require(!whitelist[_addr], "Voter already added");
        require(_addr != address(0), "Address cannot be the zero address");
        
        whitelist[_addr] = true;
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }


    // Admin starts proposal registration session
    function registerStart() public onlyOwner {
        require(state == WorkflowStatus.RegisteringVoters, "You can not start registration session now");

        state = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    // Admin ends proposal registration session
    function registerEnd() public onlyOwner {
        require(proposals.length > 0, "There is no proposal to vote");
        require(state == WorkflowStatus.ProposalsRegistrationStarted, "Proposals' registration is not open");

        state = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    // Admin authorizes whitelisted electors to register one or several proposals during the registration session
    function registerProposal(string memory _description) public onlyVoters {
        require(state == WorkflowStatus.ProposalsRegistrationStarted, "Proposals' registration session is not open");
        require(voters[msg.sender].isRegistered, "You are not allowed to register any proposals");
        require(bytes(_description).length > 0, "Enter a proposal description");
        
        Proposal memory newProposal = Proposal(msg.sender, _description, 0, 0);
        newProposal.proposalId = proposals.length;
        proposals.push(newProposal);

        emit ProposalRegistered(newProposal.proposalId); 
    }

    // Whitelisted voters can see proposals
    function getProposals() external view onlyVoters returns (Proposal[] memory) {
        require(state == WorkflowStatus.ProposalsRegistrationEnded, "Proposals' registration session is not finished");

        return proposals;
    }

    // Admin triggers voting session
    function votingStart() public onlyOwner {
        require(state == WorkflowStatus.ProposalsRegistrationEnded, "Proposals' registration session is not finished");
        require(proposals.length > 0, "There is no proposal to vote for");

        state = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    // Admin ends the voting session
    function votingEnd() public onlyOwner {
        require(state == WorkflowStatus.VotingSessionStarted, "Voting session is not open");

        state = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    // One elector can vote for one proposal bu using the index number of the proposal from 0 to n
    function vote(uint _proposalId) public onlyVoters {
        require(voters[msg.sender].isRegistered, "You are not allowed to vote for");
        require(!voters[msg.sender].hasVoted, "You've already voted");
        require(_proposalId < proposals.length, "Invalid proposal ID");

        proposals[_proposalId].voteCount ++;

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;    

        emit Voted(msg.sender, _proposalId);
    }

    // Admin triggers the vote counting process to declare the winner
    function countVote() public onlyOwner returns(uint) {
        require(state == WorkflowStatus.VotingSessionEnded, "Voting session is still open");
        require(proposals.length > 0, "There is no proposal to count for");

        uint winnersVoteCount = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winnersVoteCount) {
                winnersVoteCount = proposals[i].voteCount;
                winningProposalId = proposals[i].proposalId;
            }
        }

        state = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        return winningProposalId;
    }


    // Voters can verify details about the winning proposal
    function showWinningProposal() external view onlyVoters returns (uint, string memory, uint, address) {
        require(state == WorkflowStatus.VotesTallied, "Voting session is still open or votes are still not counted");

        address winnerAddress = proposals[winningProposalId].proposer;
        string memory winnerProposal = proposals[winningProposalId].description;
        uint winnerProposalVoteCount = proposals[winningProposalId].voteCount;

        return (winningProposalId, winnerProposal, winnerProposalVoteCount, winnerAddress);
    }

    // Voters can see who voted for which proposal
    function whoVotedForWhichProposal(address _addr) external view onlyVoters returns(uint) {
        require(state == WorkflowStatus.VotesTallied, "Voting session is still open or votes are still not counted");
        require(whitelist[_addr], "Please enter a whitelisted voter address");
        return voters[_addr].votedProposalId;
    }
}
