// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

contract IntellectualPropertyRegistry {
    struct IP {
        string ipfsHash;
        string ipType; // patent / copyright / trademark
        string description;
        address owner;
        uint256 timestamp;
    }
    struct License {
        address licensee;
        uint256 expiry;
        bool active;
    }

    mapping(uint256 => address[]) public ownershipHistory;
    mapping(uint256 => License[]) public licenses;
    mapping(uint256 => IP) public ipRecords;
    uint256[] private ipIds; 

    event IPRegistered(uint256 indexed ipId, address indexed owner, string ipfsHash, uint256 timestamp);
    event OwnershipTransferred(uint256 indexed ipId, address indexed previousOwner, address indexed newOwner);
    event LicenseGranted(uint256 indexed ipId, address indexed licensee, uint256 expiry);
    event LicenseRevoked(uint256 indexed ipId, address licensee);

    modifier onlyOwner(uint256 ipId) {
        require(ipRecords[ipId].owner == msg.sender, "Only the owner can perform this action.");
        _;
    }

    function registerIp(string memory ipfsHash, string memory ipType, string memory description) external {
        uint256 ipId = uint256(keccak256(abi.encodePacked(msg.sender, ipfsHash, block.timestamp)));

        require(ipRecords[ipId].owner == address(0), "IP already registered.");

        ipRecords[ipId] = IP(ipfsHash, ipType, description, msg.sender, block.timestamp);
        ownershipHistory[ipId].push(msg.sender);
        ipIds.push(ipId);

        emit IPRegistered(ipId, msg.sender, ipfsHash, block.timestamp);
    }

    function transferOwnership(uint256 ipId, address newOwner) public onlyOwner(ipId) {
        require(ipRecords[ipId].owner != address(0), "IP not registered.");
        require(newOwner != address(0), "Invalid new owner address");
        require(newOwner != ipRecords[ipId].owner, "New owner must be different");


        address previousOwner = ipRecords[ipId].owner;
        ipRecords[ipId].owner = newOwner;
        ownershipHistory[ipId].push(newOwner);

        emit OwnershipTransferred(ipId, previousOwner, newOwner);
    }

    function grantLicense(uint256 ipId, address licensee, uint256 duration) public onlyOwner(ipId) {
        require(licensee != address(0), "Invalid licensee address");

        uint256 expiry = block.timestamp + duration;
        licenses[ipId].push(License(licensee, expiry, true));

        emit LicenseGranted(ipId, licensee, duration);
    }

    function revokeLicense(uint256 ipId, address licensee) public onlyOwner(ipId) {
        License[] storage ipLicenses = licenses[ipId];

        for(uint256 i=0; i<ipLicenses.length; i++) {
            if(ipLicenses[i].licensee == licensee && ipLicenses[i].active){
                ipLicenses[i].active = false;
                emit LicenseRevoked(ipId, licensee);
                return;
            }
        }
        revert("License not found");
    }

    function verifyIP(uint256 ipId) public view returns(bool){
        return ipRecords[ipId].owner != address(0);
    }

    function getOwnershipHistory(uint256 ipId) public view returns(address[] memory){
        return ownershipHistory[ipId];
    }

    function getOwner(uint256 ipId) public view returns(address){
        return ipRecords[ipId].owner;
    }

    function getIPDetails(uint256 ipId) public view returns (address, string memory, string memory, string memory, uint256) {
        IP memory ip = ipRecords[ipId];
        return(ip.owner, ip.ipType, ip.description, ip.ipfsHash, ip.timestamp);
    }

    function getLicenseDetails(uint256 ipId) public view returns(License[] memory) {
        return licenses[ipId];
    }

    function getRegisteredIPs() public view returns (uint256[] memory) {
        return ipIds;
    }

    function isLicenseActive(uint256 ipId, address licensee) public view returns(bool) {
        License[] memory ipLicenses = licenses[ipId];

        for(uint256 i=0; i<ipLicenses.length; i++) {
            if(ipLicenses[i].licensee == licensee && ipLicenses[i].active && ipLicenses[i].expiry > block.timestamp){
                return true;
            }   
        } 
        return false;
    }
}
