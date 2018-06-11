pragma solidity ^0.4.21;

import "./SafeMath.sol";

/// @title Contract to bet Ether for on a match of two teams
contract MatchBetting {
    using SafeMath for uint256;

    //Represents a team, along with betting information
    struct Team {
        string name;
        mapping(address => uint) bettingContribution;
        uint totalAmount;
        uint totalParticipants;
    }
    //Represents two teams
    Team[2] public teams;
    // Flag to show if the match is completed
    bool public matchCompleted = false;
    // Flag to show if the contract will stop taking bets.
    bool public stopMatchBetting = false;
    // The minimum amount of ether to bet for the match
    uint public minimumBetAmount;
    // WinIndex represents the state of the match. 4 shows match not started.
    // 4 - Match has not started
    // 0 - team[0] has won
    // 1 - team[1] has won
    // 2 - match is draw
    uint public winIndex = 4;
    // A helper variable to track match easily on the backend web server
    uint matchNumber;
    // Owner of the contract
    address public owner;
    // The jackpot address, to which some of the proceeds goto from the match
    address private jackpotAddress;

    address[] public betters;

    // Only the owner will be allowed to excute the function.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    //@notice Contructor that is used configure team names, the minimum bet amount, owner, jackpot address
    // and match Number
    function MatchBetting(string teamA, string teamB, uint _minimumBetAmount, address sender, address _jackpotAddress, uint _matchNumber) public {
        Team memory newTeamA = Team({
            totalAmount : 0,
            name : teamA,
            totalParticipants : 0
            });

        Team memory newTeamB = Team({
            totalAmount : 0,
            name : teamB,
            totalParticipants : 0
            });

        teams[0] = newTeamA;
        teams[1] = newTeamB;
        minimumBetAmount = _minimumBetAmount;
        owner = sender;
        jackpotAddress = _jackpotAddress;
        matchNumber = _matchNumber;
    }

    //@notice Allows a user to place Bet on the match
    function placeBet(uint index) public payable {
        require(msg.value >= minimumBetAmount);
        require(!stopMatchBetting);
        require(!matchCompleted);

        if(teams[0].bettingContribution[msg.sender] == 0 || teams[1].bettingContribution[msg.sender] == 0) {
            betters.push(msg.sender);
        }

        if (teams[index].bettingContribution[msg.sender] == 0) {
            teams[index].totalParticipants = teams[index].totalParticipants.add(1);
        }
        teams[index].bettingContribution[msg.sender] = teams[index].bettingContribution[msg.sender].add(msg.value);
        teams[index].totalAmount = teams[index].totalAmount.add(msg.value);
    }

    //@notice Set the outcome of the match
    function setMatchOutcome(uint winnerIndex, string teamName) public onlyOwner {
        if (winnerIndex == 0 || winnerIndex == 1) {
            //Match is not draw, double check on name and index so that no mistake is made
            require(compareStrings(teams[winnerIndex].name, teamName));
            uint loosingIndex = (winnerIndex == 0) ? 1 : 0;
            if (teams[loosingIndex].totalAmount != 0) {
                uint jackpotShare = (teams[loosingIndex].totalAmount).div(5);
                jackpotAddress.transfer(jackpotShare);
            }
        }
        winIndex = winnerIndex;
        matchCompleted = true;
    }

    //@notice Sets the flag stopMatchBetting to true
    function setStopMatchBetting() public onlyOwner{
        stopMatchBetting = true;
    }

    //@notice Allows the user to get ether he placed on his team, if his team won or draw.
    function getEther() public {
        require(matchCompleted);

        if (winIndex == 2) {
            uint betOnTeamA = teams[0].bettingContribution[msg.sender];
            uint betOnTeamB = teams[1].bettingContribution[msg.sender];

            teams[0].bettingContribution[msg.sender] = 0;
            teams[1].bettingContribution[msg.sender] = 0;

            uint totalBetContribution = betOnTeamA.add(betOnTeamB);
            require(totalBetContribution != 0);

            msg.sender.transfer(totalBetContribution);
        } else {
            uint betValue = teams[winIndex].bettingContribution[msg.sender];

            require(betValue != 0);
            teams[winIndex].bettingContribution[msg.sender] = 0;

            Team storage losingTeam = (winIndex == 0) ? teams[1] : teams[0];
            uint winTotalAmount = teams[winIndex].totalAmount;

            if(losingTeam.totalAmount == 0){
                msg.sender.transfer(betValue);
            }else{
                //original Bet + (original bet * 80 % of bet on losing side)/bet on winning side
                uint userTotalShare = betValue;
                if(losingTeam.totalAmount != 0){
                    uint bettingShare = betValue.mul(80).div(100).mul(losingTeam.totalAmount).div(winTotalAmount);
                    userTotalShare = userTotalShare.add(bettingShare);
                }

                msg.sender.transfer(userTotalShare);
            }
        }
    }

    function getBetters() public view returns (address[]) {
        return betters;
    }

    //@notice get various information about the match and its current state.
    function getMatchInfo() public view returns (string, uint, uint, string, uint, uint, uint, bool, uint, uint, bool) {
        return (teams[0].name, teams[0].totalAmount, teams[0].totalParticipants, teams[1].name,
            teams[1].totalAmount, teams[1].totalParticipants, winIndex, matchCompleted, minimumBetAmount, matchNumber, stopMatchBetting);
    }

    //@notice Returns how much a user has bet on the match.
    function userBetContribution(address userAddress) public view returns (uint, uint) {
        return (teams[0].bettingContribution[userAddress], teams[1].bettingContribution[userAddress]);
    }

    //@notice Private function the helps in comparing strings.
    function compareStrings(string a, string b) private pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
}
