pragma solidity ^0.4.21;

import "./Ownable.sol";
import "./MatchBetting.sol";

contract MatchBettingFactory is Ownable {
    // Array of all the matches deployed
    address[] deployedMatches;
    // The address to which some ether is to be transferred
    address jackpotAddress;

    //@notice Constructor thats sets up the jackpot address
    function MatchBettingFactory(address _jackpotAddress) public{
        jackpotAddress = _jackpotAddress;
    }

    //@notice Creates a match with given team names, minimum bet amount and a match number
    function createMatch(string teamA, string teamB, uint _minimumBetAmount, uint _matchNumber) public onlyOwner{
        address matchBetting = new MatchBetting(teamA, teamB, _minimumBetAmount, msg.sender, jackpotAddress, _matchNumber);
        deployedMatches.push(matchBetting);
    }

    //@notice get a address of all deployed matches
    function getDeployedMatches() public view returns (address[]) {
        return deployedMatches;
    }
}