// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VTO is ERC20 {
    using Strings for uint256;

    mapping(address => uint) public addressParticipated; // keeps track of total participation amount of addresses
    mapping(address => uint) public addressFunded; // keeps track of total aided $MATIC amounts of addresses
    mapping(uint256 => Aid) public aidProposals;

    struct Aid {
        bool executed; // keeps track of whether the tokens is sent or not
        mapping(address => uint) aiders;
        uint upvoters;
        uint downvoters;
        string name;
        string description;
        address to; // destination to send tokens
        uint totalFunded;
    }

    uint256 public aidCounter;

    constructor() ERC20 ("aidDAO Membership", "AID") {}
    receive() external payable {}
    fallback() external payable {}

    function joinDAO() external payable {
        require(balanceOf(msg.sender) == 0, "you are already a member");
        _mint(msg.sender, 1);
    }

    function createAid(string memory _description, string memory _name) external payable DAOMemberOnly {
        Aid storage aid = aidProposals[aidCounter];
        aid.description = _description;
        aid.name = _name;
        aid.to = msg.sender;
        aidCounter++;
    }

    modifier DAOMemberOnly() {
        require(balanceOf(msg.sender) == 1, "not a dao member");
        _;
    }
    
    function joinToAid(uint _aidIndex)
        external
        payable
        DAOMemberOnly
    {
        Aid storage aid = aidProposals[_aidIndex];
        require(msg.value > 0, "you should make a bit aid");

        // increases participations
        if(aid.aiders[msg.sender] == 0) {
            addressParticipated[msg.sender]++;
        }
        
        addressFunded[msg.sender] += msg.value;
        aid.aiders[msg.sender] = msg.value;
        aid.totalFunded += msg.value;
    }

    modifier executableAidOnly(uint256 _aidIndex) {
        require(
            aidProposals[_aidIndex].executed == false,
            "aid has been made already"
        );
        _;
    }

    function sendAid(uint256 _aidIndex)
        external
        DAOMemberOnly
        executableAidOnly(_aidIndex)
    {
        Aid storage aid = aidProposals[_aidIndex];
        (bool success, ) = address(payable(aid.to)).call{value : aid.totalFunded}("");
        require(success,"transfer failed");
        
        aid.executed = true;
    }

    
    function getActiveAidCount() external view returns(uint) {
        uint count;
        for(uint i; i < aidCounter; i++){
            Aid storage aid = aidProposals[i];
            if(aid.executed == false) {
                count++;
            }
        }
        
        return count;
    }
}