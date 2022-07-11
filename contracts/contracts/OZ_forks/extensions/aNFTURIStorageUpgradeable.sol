pragma solidity ^0.8.0;


import "../aNFT.sol";
import "../../../interfaces/IBrain.sol";


/**
 * @dev     aNFT token with storage based token URI management. It allows the URI
 *          to change in response to a changing version, which can be triggered
 *          by arbitrary logic in the brain of the aNFT. For example a new URI/image
 *          can be returned based on changing conditions such as the price of ETH,
 *          how much liquidity is in some lending protocol, or the balance of the
 *          owner etc.
 *          
 * @notice  It's a tradeoff whether to read an external contract (the brain)
 *          in order to get the version, or for it to be explicitly updated
 *          by the brain in a state-changing tx. In the case of reading, it allows
 *          the version to be changed for free in response to certain conditions
 *          and the assumption is that wallets/marketplaces will load the URI fresh
 *          every time the user opens their wallet. This assumption, however, may
 *          not be true where a wallet locally caches an image, or in a game that
 *          is played over a period of time where the condition is changing in real
 *          time and therefore the image should update as soon as the URI changes - the
 *          game isn't aware of when this happens and so would need to frequently
 *          query the chain to see if it's changed. In the case of using a
 *          state-changing tx, it would be able to provide an event that a game/wallet
 *          can listen out for and therefore would be much better for wallets and games
 *          that implement aNFTs. However, since it requires a tx, it would cost money,
 *          especially on ETH mainnet, which is particularly unappealing in the case of
 *          in-game item aNFTs since you typically don't interact with an item directly
 *          in the same way you do with a character and therefore it's less likely it
 *          would make sense for players to give funds to the aNFT so it can fuel its
 *          own updates.
 *          The problem is that, since I only just invented aNFTs, no wallets or games
 *          support aNFTs and therefore don't support listening to events, so for
 *          now, we'll go with the reading case since the state-changing tx case
 *          have the same benefits for the foreseeable future but the reading is cheaper.
 */
abstract contract aNFTURIStorageUpgradeable is aNFT {
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    // This could be a mapping to a mapping, but then it wouldn't be
    // deletable in `_burn`
    mapping(uint256 => string[]) private _tokenIdToVerToURI;

    /**
     * @dev See {IaNFTMetadataUpgradeable-tokenURI}.
     */
    function _tokenURI(uint256 tokenId, uint256 version) internal view returns (string memory) {
        uint verLen = _tokenIdToVerToURI[tokenId].length;
        if (verLen > 0) {
            require(version < verLen, "aNFTURIStorageUpgradeable: version out of bounds");

            string memory _tokenURI = _tokenIdToVerToURI[tokenId][version];
            string memory base = _baseURI();

            // If there is no base URI, return the token URI.
            if (bytes(base).length == 0) {
                return _tokenURI;
            }
            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            if (bytes(_tokenURI).length > 0) {
                return string(abi.encodePacked(base, _tokenURI));
            }
        }

        return super.tokenURI(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "aNFTURIStorageUpgradeable: URI query for nonexistent token");
        return _tokenURI(tokenId, IBrain(aNFT.brainOf(tokenId)).getURIVersion(tokenId));
    }

    function tokenURI(uint256 tokenId, uint256 version) public view virtual returns (string memory) {
        require(_exists(tokenId), "aNFTURIStorageUpgradeable: URI query for nonexistent token");
        return _tokenURI(tokenId, version);
    }

    function _setTokenURIs(uint256 tokenId, string[] memory tokenURIs) internal virtual {
        require(_exists(tokenId), "aNFTURIStorageUpgradeable: URI set of nonexistent token");
        _tokenIdToVerToURI[tokenId] = tokenURIs;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        delete _tokenIdToVerToURI[tokenId];
    }
}
