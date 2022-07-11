export interface UserState {
  appNetwork: Network;

  /** Current user wallet address, if `undefined` the user is not connected */
  address?: string;
  /**
   * Current user wallet network, if `undefined` the user is not connected,
   *
   * **most of the time we shouldn't use this and use `appNetwork` instead**.
   *
   * This is use to check if the wallet as the same network as the app,
   * to sync the app network when the user change the network on it's wallet
   * and to warn the user if he selected an unsupported network on it's wallet.
   */
  walletNetwork?: Network;

  /**
   * The current selected hero, if `undefined` there is not selected hero
   * Since heroes could come from multiple contracts the id should be formatted like this
   * @example
   * '<contract-address>:<nft-id>'
   */
  selectedHero?: string;
  /**
   * The current selected power up, if `undefined` there is no selected power up
   * Since power ups could come from multiple contracts the id should be formatted like this
   * @example
   * '<contract-address>:<nft-id>'
   */
  selectedPowerUp?: string;
  /**
   * The current selected boss, if `undefined` there is no selected boss
   * Since bosses could come from multiple contracts the id should be formatted like this
   * @example
   * '<contract-address>:<nft-id>'
   */
  selectedBoss?: string;

  selectedTeam?: Team;
}

/** Standard NFT attribute from OpenSea */
export interface NftAttribute {
  traitType: string;
  value: string | number;
}

/** Standard NFT metadata from OpenSea */
export interface NftMetadata {
  name: string;
  description: string;
  image: string;
  attributes: NftAttribute[];
}

export interface Nft {
  id: string;
  contractAddress: string;
  metadataUri: string;

  /** Standard NFT metadata, if `undefined` we need to fetch it, or it's already loading */
  metadata?: NftMetadata;
}

export interface Hero extends Nft {
  /**
   * Last time this hero fought a Boss, if `undefined`, we should fetch the data, if null the hero never fought
   *
   * `BossId -> last fight date`
   * @example
   * {
   *  '0': 2022-7-8, // this hero fought the boss '0'
   *  '1': null, // this hero never fought the boss '1'
   *  // we don't know for the boss '2', we should fetch the data
   * }
   */
  lastFight: Record<string, Date | null>;
}

export interface PowerUp extends Nft {}

export interface Boss extends Nft {
  ownerAddress: string;
  nftLoot: Nft[];
  tokenLoot: Token[];
}

export interface Token {
  /** ERC20 contract address */
  contractAddress: string;
  /**
   * The amount of token
   * @dev be careful, it's better to always use vanilla `number` instead of `ethers.BigNumber`,
   * because BigNumber can throw overflow error when parsing/formatting whereas js number can be arbitrarily large
   */
  amount: number;
}

/** Current holders of Hero NFTs*/
export interface Player {
  ownerAddress: string;
  nftId: string;
  twitter?: string;
}

/** Current Team Pool for user */
export interface TeamPool {
  poolId: string;
  members: Player[];
  fighter?: UserState;
}

/** User Team Selection */
export interface Team extends TeamPool {
  selectedMembers?: Player[];
  password?: string;
}

export interface Result {
  result: boolean /** true for win, false for lose */;
  user: UserState;
  boss: Boss;
  nftReward: Nft[];
  tokenReward: Token[];
}

export interface GlobalState {
  user: UserState;
  heroes?: Hero[];
  powerUps?: PowerUp[];
  bosses?: Boss[];
  mode?: string /** Used to control the game flow/routes */;
  team?: Team;
}
