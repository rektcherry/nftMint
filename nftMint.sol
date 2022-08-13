// SPDX-License-Identifier: MIT
// !!!CAUTION TEST VERSION, DO NOT DEPLOY ON LIVE NET!!! ///
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract yourNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string baseURI;
  string public hiddenUri = "ipfs://CID/hidden.json";
  string public baseExtension = ".json";
  uint256 public cost = 0.00005 ether;
  uint256 public teamCost = 0 ether;
  uint256 public maxSupply = 6500;
  uint256 public maxMintAmount = 2;
  bool public paused = false;
  bool public revealed = false;
  uint256 public REVEAL_TIMESTAMP;
  uint256 public startingIndex;
  uint256 public preMintOpeningTime;
  uint256 public preMintClosingTime;
  uint256 public publicMintStart;

  constructor(
    uint256 saleStart,
    string memory _initBaseURI,
    string memory _initHiddenURI 

  ) ERC721("tokenName", "tokenSymbol") {
    REVEAL_TIMESTAMP = saleStart + (86400 * 7); 
    preMintOpeningTime = saleStart + (900);
    preMintClosingTime = saleStart + (4500);
    publicMintStart =  saleStart + (4560);
    setBaseURI(_initBaseURI);
    setHiddenURI(_initHiddenURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
     return baseURI;
  }

mapping(address => bool) whitelist;

function addUser(address _addressToWhitelist) public onlyOwner {
    whitelist[_addressToWhitelist] = true;
}

function verifyUser(address _whitelistedAddress) public view returns(bool) {
    bool userIsWhitelisted = whitelist[_whitelistedAddress];
    return userIsWhitelisted;
}

function addManyToWhitelist(address[] memory _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

enum Stage {locked, presale, publicsale}  

modifier isPresale {
    require(checkStage() == Stage.presale);
    _;
    }

function checkStage() public view returns (Stage stage){
      if(block.timestamp < preMintOpeningTime) {
        stage = Stage.locked;
        return stage;
      }
      else if(block.timestamp >= preMintOpeningTime && block.timestamp <= preMintClosingTime) {
        stage = Stage.presale;
        return stage;
      }
      else if(block.timestamp >= preMintClosingTime) {
        stage = Stage.publicsale;
        return stage;
        }
    }

     function iswhitelisted(address xyz) public view isPresale returns (bool) {
      if(whitelist[xyz]) return true;
      else return false;
    }

    modifier buffer(address abc) {
      require(preMintOpeningTime != 0);
      require(checkStage() != Stage.locked);
      require((checkStage() == Stage.publicsale || iswhitelisted(abc)));
      _;
    }   

  function mint(uint256 _mintAmount) public payable buffer(msg.sender) {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }
    if (msg.sender == owner()) {
      require(msg.value >= teamCost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return hiddenUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function reveal() public onlyOwner {
      revealed = true;
  }

      function reserveNFT() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 50; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    maxSupply = _newMaxSupply;
  }
  
  function setHiddenURI(string memory _hiddenUri) public onlyOwner {
    hiddenUri = _hiddenUri;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}