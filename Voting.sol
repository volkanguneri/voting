// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// pragma solidity 0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    // Proposal structure
    struct Proposal {
        address proposer;
        string description;
        uint voteCount; // A voir comment incorporer
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Vote {
        address voter;
        uint proposalIndex;
    }

    // Winning proposal ID
    uint winningProposalId;

    // For the registration session of proposals to vote
    bool public registrationStatut;

    // Voting session statut
    bool public votingSessionStatut;

    // Registered proposals
    Proposal[] public proposals;

    // Acces restriction to certain functions
    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner() || msg.sender == adminAddress,
            "Permission denied"
        );
        _;
    }

    // Admin Address
    address public adminAddress;

    constructor() Ownable(msg.sender) {
        adminAddress = msg.sender;
        registrationStatut = false;
        votingSessionStatut = false;
    }

    Vote[] public votes;

    // Electors' adress stocked by the owner
    mapping(address => bool) public _whitelist;

    // when a new voter address added
    event voterAdded(address _voterAddr);

    // when a new voter address removed
    event voterRemoved(address _voterAddr);

    // when registration is activated
    event registerAvtivated(bool);

    // when a proposal registered
    event proposalRegistered(address indexed proposer, string descrption);

    // when voting session activated
    event votingSessionActivated(bool);

    // When a vote registered
    event voteRegistered(address indexed voter, uint proposalIndex);

    // Votre smart contract doit définir les événements suivants :
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    // Votre smart contract doit définir une énumération qui gère les différents états d’un vote
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Adds a voter to the whitelist - OnlyOwner
    function addVoter(address _voterAddr) public onlyOwner {
        require(!_whitelist[_voterAddr], "Voter is already whitelisted");
        _whitelist[_voterAddr] = true;
        emit voterAdded(_voterAddr);
    }

    // Removes a voter to the whitelist - OnlyOwner
    function removedVoter(address _voterAddr) public onlyOwner {
        require(_whitelist[_voterAddr], "Voter is not whitelisted");
        _whitelist[_voterAddr] = false;
        emit voterRemoved(_voterAddr);
    }

    // Verifies if voter address is whitelisted
    function isVoter(address _voterAddr) public view returns (bool) {
        return _whitelist[_voterAddr];
    }

    // Activates proposal registration session
    function activateRegistration() public onlyOwner {
        require(!registrationStatut, "Registration is already active");
        registrationStatut = true;
        emit registerAvtivated(true);
    }

    // Ends proposal registration session
    function endRegistration() public onlyOwner {
        require(registrationStatut, "Registration is not active");
        registrationStatut = false;
        emit registerAvtivated(false);
    }

    // Authorizes whitelisted electors to register their proposals during the registration session
    function registerProposal(string memory description) public {
        require(registrationStatut, "Registration session is closed");
        require(
            bytes(description).length > 0,
            "You may enter a proposal description"
        );

        Proposal memory newProposal = Proposal({
            proposer: msg.sender,
            description: description,
            voteCount: 1
        });

        proposals.push(newProposal);

        emit proposalRegistered(msg.sender, description);
    }

    // Number of total propositions
    function getProposalCount() public view returns (uint) {
        return proposals.length;
    }

    // Activates voting session
    function activateVotingSession() public onlyOwnerOrAdmin {
        require(!votingSessionStatut, "The session is already active");
        votingSessionStatut = true;
        emit votingSessionActivated(true);
    }

    // Ends voting session
    function endVotingSession() public onlyOwnerOrAdmin {
        require(votingSessionStatut, "The session is already closed");
        votingSessionStatut = false;
        emit votingSessionActivated(false);
    }

    // Registered voters can vote
    function voting(uint proposalIndex) public {
        require(votingSessionStatut = true, "Voting session is not open");
        require(isVoter(msg.sender), "You are not authorized for voting");
        require(proposalIndex < proposals.length, "Proposition inexistante");
    }

    // // Verifies if the voter has already voted
    // for (uint i = 0; i < votes.length; i++) {
    //     require(votes[i].voter != msg.sender, "Vous avez déjà voté");

    //     Vote.push(newVote);

    //     emit voteRegistered(msg.sender, proposalIndex);
    // }
}
