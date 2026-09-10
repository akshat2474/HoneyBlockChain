pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol"; // role based authorization
import "@openzeppelin/contracts/utils/Pausable.sol"; 
// contract to have paused / unpaused state
//  Don't allow this function to execute while the contract is paused.
// This is useful as an emergency mechanism.
// For example, if you discover a serious bug:



// smart contract : class + persistent state + publicly addressable blockchain program

contract HoneyChain is AccessControl, Pausable {
    bytes32 public constant BEEKEEPER_ROLE = keccak256("BEEKEEPER_ROLE");
    bytes32 public constant PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant LAB_ROLE = keccak256("LAB_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant RETAILER_ROLE = keccak256("RETAILER_ROLE");

    enum BatchStatus {
        Created,
        Harvested,
        Processed,
        LabVerified,
        Packaged,
        InDistribution,
        AtRetail,
        Sold,
        Recalled,
        Rejected
    }

    struct HoneyBatch {
        bytes32 batchIdHash;
        address beekeeper;
        address currentCustodian;
        uint64 harvestTimestamp;
        uint64 createdAt;
        uint32 quantityGrams;
        BatchStatus status;
        string metadataCID;
        bytes32 metadataHash;
        bytes32 labReportHash;
        bool labVerified;
        bool recalled;
    }
    
    // Given a bytes32 batch ID, find the HoneyBatch belonging to it.
    mapping(bytes32 => HoneyBatch) public batches;

    // An event records something in the transaction's logs.
    // indexed makes the parameter searchable/filterable through event logs.
    event BatchCreated(bytes32 indexed batchIdHash, address indexed beekeeper, string metadataCID, bytes32 metadataHash);
    event HarvestRegistered(bytes32 indexed batchIdHash, uint64 harvestTimestamp, uint32 quantityGrams);
    event ProcessingRegistered(bytes32 indexed batchIdHash, address indexed processor, string metadataCID);
    event LabVerified(bytes32 indexed batchIdHash, address indexed lab, bytes32 labReportHash);
    event Packaged(bytes32 indexed batchIdHash, address indexed processor, string metadataCID);
    event CustodyTransferred(bytes32 indexed batchIdHash, address indexed from, address indexed to, uint8 status);
    event RetailRegistered(bytes32 indexed batchIdHash, address indexed retailer);
    event BatchRecalled(bytes32 indexed batchIdHash, address indexed by, string reasonCID);
    event BatchRejected(bytes32 indexed batchIdHash, address indexed by, string reasonCID);

    // This gives the person deploying the contract the default admin role.
    // msg.sender means: The address that called the current function.

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createBatch(
        bytes32 _batchIdHash,
        uint32 _quantityGrams,
        uint64 _harvestTimestamp,
        string memory _metadataCID,
        bytes32 _metadataHash
    ) external onlyRole(BEEKEEPER_ROLE) whenNotPaused {
        require(batches[_batchIdHash].createdAt == 0, "Batch already exists");

        batches[_batchIdHash] = HoneyBatch({
            batchIdHash: _batchIdHash,
            beekeeper: msg.sender,
            currentCustodian: msg.sender,
            harvestTimestamp: _harvestTimestamp,
            createdAt: uint64(block.timestamp),
            quantityGrams: _quantityGrams,
            status: BatchStatus.Created,
            metadataCID: _metadataCID,
            metadataHash: _metadataHash,
            labReportHash: bytes32(0),
            labVerified: false,
            recalled: false
        });
        // emit creates a log/event saying that something happened.
        // "Create a BatchCreated event/log containing these four values."
        emit BatchCreated(_batchIdHash, msg.sender, _metadataCID, _metadataHash);
    }

    function verifyLab(
        bytes32 _batchIdHash,
        bytes32 _labReportHash,
        string memory _metadataCID,
        bytes32 _metadataHash
    ) external onlyRole(LAB_ROLE) whenNotPaused {
        require(batches[_batchIdHash].createdAt != 0, "Batch does not exist");
        require(!batches[_batchIdHash].recalled, "Batch is recalled");

        batches[_batchIdHash].labReportHash = _labReportHash;
        batches[_batchIdHash].labVerified = true;
        batches[_batchIdHash].metadataCID = _metadataCID;
        batches[_batchIdHash].metadataHash = _metadataHash;
        batches[_batchIdHash].status = BatchStatus.LabVerified;

        emit LabVerified(_batchIdHash, msg.sender, _labReportHash);
    }

    // It takes:
    // _batchIdHash
    // Which batch?
    // _to
    // Who gets custody?
    //_nextStatus
    //What status should the batch have afterward?


    function transferCustody(
        bytes32 _batchIdHash,
        address _to,
        uint8 _nextStatus
    ) external whenNotPaused {
        require(batches[_batchIdHash].createdAt != 0, "Batch does not exist");
        require(!batches[_batchIdHash].recalled, "Batch is recalled");
        require(batches[_batchIdHash].currentCustodian == msg.sender, "Not current custodian");

        batches[_batchIdHash].currentCustodian = _to;
        batches[_batchIdHash].status = BatchStatus(_nextStatus);

        emit CustodyTransferred(_batchIdHash, msg.sender, _to, _nextStatus);
    }

    function recallBatch(
        bytes32 _batchIdHash,
        string memory _reasonCID
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(batches[_batchIdHash].createdAt != 0, "Batch does not exist");

        batches[_batchIdHash].recalled = true;
        batches[_batchIdHash].status = BatchStatus.Recalled;

        emit BatchRecalled(_batchIdHash, msg.sender, _reasonCID);
    }

    function getBatch(bytes32 _batchIdHash) external view returns (HoneyBatch memory) {
        require(batches[_batchIdHash].createdAt != 0, "Batch does not exist");
        return batches[_batchIdHash];
    }
}
