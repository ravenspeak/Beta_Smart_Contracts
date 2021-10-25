// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./IHippieJob.sol";
import "./IHippies.sol";
import "./IHCryptoHippies.sol";

contract HippieLandBSC is
  Initializable,
  ERC1155Upgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  bool public landEnabled_;
  address payable public HSafeVault;
  address public jobsContract;
  address public hippieContract;
  uint256 public specialBlock;
  address public CryptoHippiesAddress;

  /* NOTE
    It maps buildings types to its corresponding hippies types:
    1 = HippieBus = ActivistHippie
    2 = HealersHouse = HealerHippie
    3 = WeedFarm = STonerHippie
    We call this type "genericType"
  */
  // User address => JobType => IDs stacked
  mapping(address => mapping(uint256 => uint256[])) public addressToJobsType;
  // Job Id => Owner Address
  mapping(uint256 => address) buildsAtAddress;
  // User address => Hippie Type => IDs stacked
  mapping(address => mapping(uint256 => uint256[])) public addressToHippiesType;
  // Hippie Id => Owner Address
  mapping(uint256 => address) public hippiesAtAddress;
  // buildingType => Basesalary
  mapping(uint256 => uint256) public jobTypeBaseSalaries;
  // buildingType => Basesalary, it use the info that a job type only stack one type of hippie
  mapping(uint256 => uint256) public hippieTypeBaseSalaries;
  // hippie Id => tiemstamp when it start farming
  mapping(uint256 => uint256) public hippieStartWorkingTimestamp;
  //Special salaries Claim (NFTID - Amount)
  mapping(uint256 => uint256) public NftIDClaimed;
  //Special salary Blocks
  uint256 public specialStartBlockTime;
  uint256 public specialEndBlockTime;
  uint256 public salaryFactor;
  event SpecialSalaryClaimed(uint256 nftID, uint256 amount);
  struct Enemy {
    uint256 typeNum;
    uint256 bait;
    uint256 salary;
    uint256 winningProb;
  }
  mapping(uint256 => Enemy) public enemies_;
  mapping(uint256 => uint256) public winsByNftId;
  mapping(uint256 => uint256) public totalFightsByNftId;
  event FightFinished(address player, uint256 figtherNftID, bool result, uint256 amount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {
    __ERC1155_init(
        "https://storageapi.fleek.co/c62eb97d-92b1-41e4-8dfe-30f91c83bdbf-bucket/CryptoHippies/HippiesLand.json"
    );
    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
    landEnabled_ = true;
    HSafeVault = payable(address(0x3396207ec7aabc7D76FCA9E7c6364864D1b1F03B)); //
    specialBlock = 10949308; //
    CryptoHippiesAddress = address(0xc7EF8B763e6969f643558C91D0A7313577c1481f);
    hippieContract = address(0x972d281CE9cdd191A3390851f0ae96B6b3013A2b);
    jobsContract = address(0xB348456eb1e11f6d75c11945Bd5BBbC1C76d6163);
    specialStartBlockTime = 1631750400;
    specialEndBlockTime = 1632441600;
    salaryFactor = 3;
  }
  function setSpecialSalary(uint256 startBlockTime, uint256 endBlockTime, uint256 rewFactor) public onlyOwner{
    specialStartBlockTime = startBlockTime;
    specialEndBlockTime = endBlockTime;
    salaryFactor = rewFactor;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public onlyOwner {
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  // custom setters
  function setLandEnabled(bool val) public onlyOwner {
    landEnabled_ = val;
  }

  function setHSafeVault(address val) public onlyOwner {
    HSafeVault = payable(address(val));
  }
  function setJobsContract(address val) public onlyOwner {
    jobsContract = val;
  }
  function setHippieContract(address val) public onlyOwner {
    hippieContract = val;
  }
  function setSpecialBlock(uint256 blockNumber) public onlyOwner {
    specialBlock = blockNumber;
  }
  function setCRyptoHippiesAddr(address val) public onlyOwner {
    CryptoHippiesAddress = val;
  }
  function setJobsBaseSalaries(uint256 busSalary, uint256 healershouseSalary, uint256 weedfarmSalary) public onlyOwner {
    jobTypeBaseSalaries[1] = busSalary;
    jobTypeBaseSalaries[2] = healershouseSalary;
    jobTypeBaseSalaries[3] = weedfarmSalary;
  }
  function setHippiesBaseSalaries(uint256 activistSalary, uint256 healerSalary, uint256 stonerSalary) public onlyOwner {
    hippieTypeBaseSalaries[1] = activistSalary;
    hippieTypeBaseSalaries[2] = healerSalary;
    hippieTypeBaseSalaries[3] = stonerSalary;
  }
  
  // contract logic
  function addaJob(uint256 jobNftID) public {
    address sender = address(msg.sender);
    IHippieJob hippieJob = IHippieJob(jobsContract);
    require(hippieJob.ownerOf(jobNftID) == sender, "You're not the owner of this job");
    require(buildsAtAddress[jobNftID] == address(0x000), "Job already added");
    // if there are jobs with hippies of this kind at stack, make a claim without un-stacking
    uint256 genericType = hippieJob.getTypeIDByNftID(jobNftID);
    // TODO: Revisar creo que no debería hacer esto dado que cuando va haciendo el claim lo haría 2 veces
    // if (addressToJobsType[sender][genericType].length > 0 && addressToHippiesType[sender][genericType].length > 0) {
    //   claimSalariesWithoutUnJob(genericType, sender);
    // }
    buildsAtAddress[jobNftID] = sender;
    addressToJobsType[sender][genericType].push(jobNftID);
    hippieJob.transferFrom(sender, address(this), jobNftID);
  }
  function workHippie(uint256 hippieNftId) public {
    address sender = address(msg.sender);
    IHippies hippiesInstance = IHippies(hippieContract);
    require(hippiesInstance.ownerOf(hippieNftId) == sender, "You're not the owner of this hippie");
    require(hippiesAtAddress[hippieNftId] == address(0x000), "Hippie already Stacked");
    uint256 genericType = hippiesInstance.getTypeIdByNftId(hippieNftId);
    uint256 hippiesByType = addressToHippiesType[sender][genericType].length;
    uint256 maxSlots = addressToJobsType[sender][genericType].length * 3;
    uint256 freeSlots = maxSlots - hippiesByType;
    require(freeSlots > 0, "Not free slots");

    addressToHippiesType[sender][hippiesInstance.getTypeIdByNftId(hippieNftId)].push(hippieNftId);
    hippiesAtAddress[hippieNftId] = sender;
    hippiesInstance.transferFrom(sender, address(this), hippieNftId);
    // claimSalaries(); => Ya no se hace dado que solo se puede hacer cuando no generó nada
    hippieStartWorkingTimestamp[hippieNftId] = block.timestamp;
  }
  function unaddaJob(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToHippiesType[sender][genericType].length == 0, "make claim instead");
    IHippieJob hippieJob = IHippieJob(jobsContract);
    require(addressToJobsType[sender][genericType].length > 0, "not stacked of this type");
    uint256 nftId = addressToJobsType[sender][genericType][addressToJobsType[sender][genericType].length - 1];
    require(buildsAtAddress[nftId] == sender, "not the stacker");
    // Como va a sacar un edificio tiene que haber al menos 3 slots libres
    uint256 hippiesByType = addressToHippiesType[sender][genericType].length;
    uint256 maxSlots = addressToJobsType[sender][genericType].length * 3;
    uint256 freeSlots = maxSlots - hippiesByType;
    require(freeSlots >= 3, "still hippies on job");
    addressToJobsType[sender][genericType].pop();
    buildsAtAddress[nftId] = address(0x000);
    hippieJob.transferFrom(address(this), sender, nftId);
  }
  function unWorkHippies(uint256 genericType) public {
    address sender = address(msg.sender);
    require(addressToJobsType[sender][genericType].length == 0, "make claim instead");
    IHippies hippiesInstance = IHippies(hippieContract);
    require(addressToHippiesType[sender][genericType].length > 0, "not hippies of this type");
    uint256 nftId = addressToHippiesType[sender][genericType][addressToHippiesType[sender][genericType].length];
    addressToHippiesType[sender][genericType].pop();
    require(hippiesAtAddress[nftId] == sender, "not the stacker");
    hippiesAtAddress[nftId] = address(0x000); 
    hippiesInstance.transferFrom(address(this), sender, nftId);
  }
  /*
    With each claim call it withdraw all the profits collected by the last hippie of beeing stack and un-stack it.
    If that hippie was the only one in a job, also claim and un-stack the gold collected by the job.
  */
  function claimSalaries(uint256 genericType) public {
    address sender = address(msg.sender);
    uint256 currentTimestamp = block.timestamp;
    require(addressToJobsType[sender][genericType].length > 0, "no buildings of this type");
    require(addressToHippiesType[sender][genericType].length > 0, "no hippies of this type");
    IHCryptoHippies CryptoHippies = IHCryptoHippies(CryptoHippiesAddress);
    IHippies hippiesInstance = IHippies(hippieContract);
    IHippieJob hippieJob = IHippieJob(jobsContract);
    uint256 totalHippiesByType = addressToHippiesType[sender][genericType].length;
    // Add hippie profits
    uint256 totalSalaries = 0;
    // uint256 hippieDelta = currentTimestamp - hippieStartWorkingTimestamp[addressToHippiesType[sender][genericType][totalHippiesByType - 1]];
    totalSalaries += (currentTimestamp - hippieStartWorkingTimestamp[addressToHippiesType[sender][genericType][totalHippiesByType - 1]])
      * hippieTypeBaseSalaries[genericType];
    // Add job profits and un-stack it if applies
    if (((totalHippiesByType - 1) % 3) == 0) {
      totalSalaries += (currentTimestamp - hippieStartWorkingTimestamp[addressToHippiesType[sender][genericType][totalHippiesByType - 1]])
        * jobTypeBaseSalaries[genericType];

      hippieJob.transferFrom(
        address(this),
        sender,
        addressToJobsType[sender][genericType][addressToJobsType[sender][genericType].length - 1]
      );
      buildsAtAddress[addressToJobsType[sender][genericType][addressToJobsType[sender][genericType].length - 1]] = address(0x000);
      addressToJobsType[sender][genericType].pop();
    }
    // Un-stack hippie
    hippiesInstance.transferFrom(
      address(this),
      sender,
      addressToHippiesType[sender][genericType][totalHippiesByType - 1]
    );
    hippiesAtAddress[addressToHippiesType[sender][genericType][totalHippiesByType - 1]] = address(0x000);
    addressToHippiesType[sender][genericType].pop();
    // adjust salaries
    totalSalaries = totalSalaries / 86400;
    // transfer the salaries
    CryptoHippies.transfer(sender, totalSalaries);
  }
  function claimSalariesWithoutUnJob(uint256 genericType, address sender) private {
    uint256 currentTimestamp = block.timestamp;
    require(addressToJobsType[sender][genericType].length > 0, "no buildings of this type");
    require(addressToHippiesType[sender][genericType].length > 0, "no hippies of this type");
    IHCryptoHippies CryptoHippies = IHCryptoHippies(CryptoHippiesAddress);
    uint256 totalHippiesByType = addressToHippiesType[sender][genericType].length;
    // Add hippie profits
    uint256 totalSalaries = 0;
    uint256 hippieDelta = currentTimestamp - hippieStartWorkingTimestamp[addressToHippiesType[sender][genericType][totalHippiesByType - 1]];
    totalSalaries += hippieDelta * hippieTypeBaseSalaries[genericType];
    // Add job profits
    if (((totalHippiesByType - 1) % 3) == 0) {
      uint256 buildingDelta = currentTimestamp - hippieStartWorkingTimestamp[addressToHippiesType[sender][genericType][totalHippiesByType - 1]];
      totalSalaries += buildingDelta * jobTypeBaseSalaries[genericType];
    }
    // adjust salaries
    totalSalaries = totalSalaries / 86400;
    // transfer the salaries
    CryptoHippies.transfer(sender, totalSalaries);
  }
  function getWorkingHippiesIdsByType(address owner, uint256 genericType) public view returns(uint256[] memory) {
    return addressToHippiesType[owner][genericType];
  }
  function getWorkingJobsIdsByType(address owner,uint256 genericType) public view returns(uint256[] memory) {
    return addressToJobsType[owner][genericType];
  }
  function currentJobAccumulatorByHippie(uint256 hippieId) public view returns(uint256) {
    address owner = hippiesAtAddress[hippieId];
    uint256 currentTimestamp = block.timestamp;
    IHippies hippiesInstance = IHippies(hippieContract);
    uint256 genericType = hippiesInstance.getTypeIdByNftId(hippieId);
    uint256 totalSalaries = 0;
    if (addressToJobsType[owner][genericType].length <= 0) {
      totalSalaries = 0;
    } else {
      uint256 hippieDelta = currentTimestamp - hippieStartWorkingTimestamp[hippieId];
      totalSalaries += hippieDelta * hippieTypeBaseSalaries[genericType];
    }
     // adjust salaries
    totalSalaries = totalSalaries / 86400;

    return totalSalaries;
  }
  function getHippieAge(uint256 hippieNftId) internal view returns (uint256){
    IHippies hippieInstance = IHippies(hippieContract);
    (
  	  uint256 idx,
	    uint256 id,
	    uint8 level,
	    uint256 age,
	    string memory edition,
	    uint256 bornAt,
	    bool onSale,
	    uint256 price
    ) = hippieInstance.hippies(hippieNftId - 1);
    return bornAt;
  }

  function claimSpecialSalaries(uint256 hippieNftID) public returns (uint256){
    IHippies hippieInstance = IHippies(hippieContract);
    bool isOwner = hippieInstance.ownerOf(hippieNftID) == address(msg.sender);
    require(NftIDClaimed[hippieNftID] < 1, "This Hippie has already claimed its salary");
    require(isOwner, "You aren't the owner of this Hippie NFT"); 
    require(hippieInstance.getTypeIdByNftId(hippieNftID) > 0, "Basic Hippie doesn't generate salaries");
    IHCryptoHippies aGoldInstance = IHCryptoHippies(CryptoHippiesAddress);
    uint256 hippieAge = getHippieAge(hippieNftID);
    if(hippieAge <= specialStartBlockTime)
    {
      uint256 totalSalaries = (specialEndBlockTime - specialStartBlockTime) / 3600 * salaryFactor; //Delta Hours
      aGoldInstance.transfer(address(msg.sender), totalSalaries);
      NftIDClaimed[hippieNftID] = 1;
      emit SpecialSalaryClaimed(hippieNftID, totalSalaries);
      return totalSalaries;
    }
    else
    {
      uint256 totalSalaries = (specialEndBlockTime - hippieAge) / 3600 * salaryFactor;
      aGoldInstance.transfer(address(msg.sender), totalSalaries);
      NftIDClaimed[hippieNftID] = 1;
      emit SpecialSalaryClaimed(hippieNftID, totalSalaries);
      return totalSalaries;
    }
  }
  function calculateSpecialSalaries(uint256 hippieNftID) public view returns (uint256) {
    IHippies hippieInstance = IHippies(hippieContract);
    if (hippieInstance.getTypeIdByNftId(hippieNftID) == 0 || NftIDClaimed[hippieNftID] >= 1) {
      return 0;
    }
    uint256 hippieAge = getHippieAge(hippieNftID);
    if (hippieAge <= specialStartBlockTime) {
      uint256 totalSalaries = (specialEndBlockTime - specialStartBlockTime) / 3600 * salaryFactor;
      return totalSalaries;
    } else {
      uint256 totalSalaries = (specialEndBlockTime - hippieAge) / 3600 * salaryFactor;
      return totalSalaries;
    }
  }

  //FIGHT Section
  function createEnemy(uint256 typeNum,uint256 bait,uint256 salary,uint256 winningProv) public onlyOwner{
    Enemy memory _toCreate = Enemy(typeNum, bait, salary, winningProv);
    enemies_[typeNum] = _toCreate;
  }
  function fightAgainst(uint256 hippieNftID, uint256 enemy) public returns (bool) {
    address sender = address(msg.sender);
    IHippies hippieInstance = IHippies(hippieContract);
    bool isOwner = hippieInstance.ownerOf(hippieNftID) == sender;
    bool isStoner = hippieInstance.getTypeIdByNftId(hippieNftID) == 3;
    require(isOwner, "This HIPPIE doesn't belong to you");
    require(isStoner, "Only Stoner Hippie can fight");
    IHCryptoHippies aGoldInstance = IHCryptoHippies(CryptoHippiesAddress);
    require(aGoldInstance.balanceOf(sender) >= enemies_[enemy].bait, "Insufficient CryptoHippies to fight");
    require(aGoldInstance.allowance(sender, address(this)) >= enemies_[enemy].salary, "Insufficient allowance");

    bool won = fight(enemies_[enemy].winningProb);
    if(won){
      aGoldInstance.transfer(sender, (enemies_[enemy].salary));
      winsByNftId[hippieNftID] += 1;
      totalFightsByNftId[hippieNftID] += 1;
      emit FightFinished(sender, hippieNftID, true, (enemies_[enemy].salary));
      return true;
    }
    else
    {
      aGoldInstance.transferFrom(sender, address(this), enemies_[enemy].bait);
      totalFightsByNftId[hippieNftID] += 1;
      emit FightFinished(sender, hippieNftID, false, (enemies_[enemy].bait));
      return false;
    }
  }
  function fight(uint percent) private view returns(bool) {
    uint256 spinResult = (block.gaslimit + block.timestamp) % 10; //Random 1 digit between 0-9
    uint256 adjPercent = (percent / 10) - 1;
    if (spinResult >= 0 && spinResult <= adjPercent) {
      return true;
    } 
    else 
    {
      return false;
    }
  }
}