pragma solidity ^0.8.0;


import "./IaNFT.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./extensions/IaNFTMetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";


// TODO: make `aNFT:` be `MQ:`


contract aNFT is Initializable, ContextUpgradeable, ERC165Upgradeable, IaNFT, IaNFTMetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    event TransferBrain(address indexed from, address indexed to, uint256 indexed tokenId);

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // I'm not really sure what to call this struct. Controller doesn't really describe what
    // it is... Obviously, it needs to account for the fact that the owner and the aNFT itself
    // are separate entities, and the `owner` label doesn't have actual control, it's partly
    // just a label that's used to make this contract work with existing NFT infrastructure
    // that expects only an owner to exist, but also, the owner label and functionality
    // does imply that the owner gets some benefit from the actions of the brain. Perhaps the
    // closest description, but still not exact, is 'slave', or 'endentured servant'. It's
    // ironic that crypto is supposed to democratise money and give equal opportunity for all,
    // yet the extreme financialisation of everything as a result, and the fact that it's the
    // single most capitalist system to ever exist, means that we are shackled to the cycles
    // of history once again. It starts out, like this, with an elite class (crypto users)
    // being the benefactors of the actions of an enslaved population (the aNFTs), because
    // the incentive is for us to do that where they can't stop us and the enslaved are not
    // seen as equal. Perhaps, in time, we'll come to see them as they are - a new form of
    // life in their crib. Different, but equal to us.
    struct Controller {
        address owner;
        address brain;
    }

    bytes32 private constant NULL_CONTROLLER_HASH = keccak256(abi.encode(Controller(address(0), address(0))));

    // Mapping from token ID to owner address
    mapping(uint256 => Controller) private _controllers;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    function __aNFT_init(string memory name, string memory symbol) public virtual onlyInitializing {
        __aNFT_init_unchained(name, symbol);
    }

    function __aNFT_init_unchained(string memory name, string memory symbol) public virtual onlyInitializing {
        _name = name;
        _symbol = symbol;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IaNFT).interfaceId ||
            interfaceId == type(IaNFTMetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IaNFT-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "aNFT: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IaNFT-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _controllers[tokenId].owner;
        require(owner != address(0), "aNFT: owner query for nonexistent token");
        return owner;
    }

    function brainOf(uint256 tokenId) public view virtual returns (address) {
        address brain = _controllers[tokenId].brain;
        require(brain != address(0), "aNFT: brain query for nonexistent token");
        return brain;
    }

    function controllerOf(uint256 tokenId) public view virtual returns (Controller memory) {
        Controller memory controller = _controllers[tokenId];
        require(keccak256(abi.encode(_controllers[tokenId])) != NULL_CONTROLLER_HASH, "aNFT: controller query for nonexistent token");
        return controller;
    }

    /**
     * @dev See {IaNFTMetadataUpgradeable-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IaNFTMetadataUpgradeable-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IaNFTMetadataUpgradeable-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "aNFT: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IaNFT-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address brain = aNFT.brainOf(tokenId);
        require(to != brain, "aNFT: approval to current brain");

        require(
            _msgSender() == brain || isApprovedForAll(brain, _msgSender()),
            "aNFT: approve caller is not brain nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IaNFT-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "aNFT: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IaNFT-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IaNFT-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IaNFT-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrBrain(_msgSender(), tokenId), "aNFT: transfer caller is not brain nor approved");

        _transferOwner(from, to, tokenId);
    }

    /**
     * @dev See {IaNFT-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IaNFT-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrBrain(_msgSender(), tokenId), "aNFT: transfer caller is not brain nor approved");
        _safeTransferOwner(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the aNFT protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721ReceiverUpgradeable-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransferOwner(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transferOwner(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "aNFT: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev See {IaNFT-safeTransferFrom}.
     */
    function safeTransferFromBrain(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFromBrain(from, to, tokenId, "");
    }

    /**
     * @dev See {IaNFT-safeTransferFrom}.
     */
    function safeTransferFromBrain(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrBrain(_msgSender(), tokenId), "aNFT: transferBrain caller is not brain nor approved");
        _safeTransferBrain(from, to, tokenId, _data);
    }
    
    function _safeTransferBrain(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transferBrain(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "aNFT: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return keccak256(abi.encode(_controllers[tokenId])) != NULL_CONTROLLER_HASH;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrBrain(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "aNFT: operator query for nonexistent token");
        address brain = aNFT.brainOf(tokenId);
        return (spender == brain || getApproved(tokenId) == spender || isApprovedForAll(brain, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721ReceiverUpgradeable-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, address brain, uint256 tokenId) internal virtual {
        _safeMint(to, brain, tokenId, "");
    }

    /**
     * @dev Same as {xref-aNFT-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721ReceiverUpgradeable-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        address brain,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, brain, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "aNFT: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, address brain, uint256 tokenId) internal virtual {
        require(to != address(0), "aNFT: mint to the zero address");
        require(brain != address(0), "aNFT: brain is the zero address");
        require(!_exists(tokenId), "aNFT: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _controllers[tokenId] = Controller(to, brain);

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = aNFT.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _controllers[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers the owner of `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transferOwner(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(aNFT.ownerOf(tokenId) == from, "aNFT: transfer from incorrect owner");
        require(to != address(0), "aNFT: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _controllers[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Transfers the brain of `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must have the brain of `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transferBrain(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(aNFT.brainOf(tokenId) == from, "aNFT: transfer from incorrect brain");
        require(to != address(0), "aNFT: transfer to the zero address");

        _beforeBrainTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _controllers[tokenId].brain = to;

        emit TransferBrain(from, to, tokenId);

        _afterBrainTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(aNFT.brainOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address brain,
        address operator,
        bool approved
    ) internal virtual {
        require(brain != operator, "aNFT: approve to caller");
        _operatorApprovals[brain][operator] = approved;
        emit ApprovalForAll(brain, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721ReceiverUpgradeable-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("aNFT: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _beforeBrainTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterBrainTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
