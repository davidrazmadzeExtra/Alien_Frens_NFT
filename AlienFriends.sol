pragma solidity ^0.8.0;

contract ALIENFRENS is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant ALIENFRENS_PUBLIC = 10000;
    uint256 public constant ALIENFRENS_MAX = ALIENFRENS_PUBLIC;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 20_000_000_000_000_000; // 0.02 ETH
    uint256 public allowListMaxMint = 10;
    string private _contractURI = "";
    string private _tokenBaseURI = "";
    bool private _isActive = false;
    bool public isAllowListActive = false;

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;

    Counters.Counter private _publicALIENFRENS;

    constructor() ERC721("ALIENFRENS", "ALIENFRENS") {}

    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string memory URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // owner minting
    function ownerMinting(address to, uint256 numberOfTokens)
        external
        payable
        onlyOwner
    {
        require(
            _publicALIENFRENS.current() < ALIENFRENS_PUBLIC,
            "Purchase would exceed ALIENFRENS_PUBLIC"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _publicALIENFRENS.current();

            if (_publicALIENFRENS.current() < ALIENFRENS_PUBLIC) {
                _publicALIENFRENS.increment();
                _safeMint(to, tokenId);
            }
        }
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowListMaxMint(uint256 maxMint) external onlyOwner {
        allowListMaxMint = maxMint;
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;

            /**
             * @dev We don't want to reset _allowListClaimed count
             * if we try to add someone more than once.
             */
            _allowListClaimed[addresses[i]] > 0
                ? _allowListClaimed[addresses[i]]
                : 0;
        }
    }

    function allowListClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address not on Allow List");

        return _allowListClaimed[owner];
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            /// @dev We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }

    function purchaseAllowList(uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "Can only mint up to 10 token"
        );

        require(isAllowListActive, "Allow List is not active");
        require(_allowList[msg.sender], "You are not on the Allow List");
        require(
            _publicALIENFRENS.current() < ALIENFRENS_PUBLIC,
            "Purchase would exceed max"
        );
        require(
            numberOfTokens <= allowListMaxMint,
            "Cannot purchase this many tokens"
        );
        require(
            _allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );
        require(
            _publicALIENFRENS.current() < ALIENFRENS_PUBLIC,
            "Purchase would exceed ALIENFRENS_PUBLIC"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _publicALIENFRENS.current();

            if (_publicALIENFRENS.current() < ALIENFRENS_PUBLIC) {
                _publicALIENFRENS.increment();
                _allowListClaimed[msg.sender] += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchase(uint256 numberOfTokens) external payable nonReentrant {
        require(_isActive, "Contract is not active");
        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "Can only mint up to 10 tokens"
        );
        require(
            _publicALIENFRENS.current() < ALIENFRENS_PUBLIC,
            "Purchase would exceed ALIENFRENS_PUBLIC"
        );
        require(
            PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _publicALIENFRENS.current();

            if (_publicALIENFRENS.current() < ALIENFRENS_PUBLIC) {
                _publicALIENFRENS.increment();
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}
