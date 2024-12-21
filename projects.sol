// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CollaborativeChallenges {

    struct Challenge {
        uint256 id;
        string name;
        address[] teamMembers;
        uint256 rewardAmount;
        bool isCompleted;
    }

    address public owner;
    uint256 public challengeCount;
    mapping(uint256 => Challenge) public challenges;
    mapping(address => uint256[]) public userChallenges;
    
    event ChallengeCreated(uint256 challengeId, string name);
    event ChallengeCompleted(uint256 challengeId, uint256 rewardAmount);
    event RewardDistributed(uint256 challengeId, address teamMember, uint256 rewardAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyCompletedChallenge(uint256 challengeId) {
        require(challenges[challengeId].isCompleted, "Challenge is not completed yet");
        _;
    }

    modifier isTeamMember(uint256 challengeId) {
        bool isMember = false;
        for (uint256 i = 0; i < challenges[challengeId].teamMembers.length; i++) {
            if (challenges[challengeId].teamMembers[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, "You are not a team member of this challenge");
        _;
    }

    constructor() {
        owner = msg.sender;
        challengeCount = 0;
    }

    function createChallenge(string memory _name, address[] memory _teamMembers, uint256 _rewardAmount) public onlyOwner {
        require(_teamMembers.length > 0, "There must be at least one team member");
        challengeCount++;
        
        challenges[challengeCount] = Challenge({
            id: challengeCount,
            name: _name,
            teamMembers: _teamMembers,
            rewardAmount: _rewardAmount,
            isCompleted: false
        });

        for (uint256 i = 0; i < _teamMembers.length; i++) {
            userChallenges[_teamMembers[i]].push(challengeCount);
        }

        emit ChallengeCreated(challengeCount, _name);
    }

    function markChallengeAsCompleted(uint256 challengeId) public onlyOwner {
        require(challenges[challengeId].id != 0, "Challenge does not exist");
        challenges[challengeId].isCompleted = true;

        emit ChallengeCompleted(challengeId, challenges[challengeId].rewardAmount);
    }

    function distributeReward(uint256 challengeId) public payable onlyCompletedChallenge(challengeId) isTeamMember(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        uint256 rewardPerMember = challenge.rewardAmount / challenge.teamMembers.length;

        // Ensure contract has enough balance to distribute
        require(msg.value == challenge.rewardAmount, "Incorrect reward amount sent");

        for (uint256 i = 0; i < challenge.teamMembers.length; i++) {
            address teamMember = challenge.teamMembers[i];
            payable(teamMember).transfer(rewardPerMember);

            emit RewardDistributed(challengeId, teamMember, rewardPerMember);
        }
    }

    function getUserChallenges(address user) public view returns (uint256[] memory) {
        return userChallenges[user];
    }

    function getChallengeDetails(uint256 challengeId) public view returns (string memory, address[] memory, uint256, bool) {
        Challenge memory challenge = challenges[challengeId];
        return (challenge.name, challenge.teamMembers, challenge.rewardAmount, challenge.isCompleted);
    }

    // Fallback function to accept Ether
    receive() external payable {}
}
