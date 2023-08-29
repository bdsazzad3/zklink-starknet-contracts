use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_contract_address, set_block_number};

use zklink::contracts::zklink::Zklink;
use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::tests::mocks::standard_token::StandardToken;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcher;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcherTrait;
use zklink::tests::mocks::non_standard_token::NonStandardToken;
use zklink::tests::mocks::non_standard_token::INonStandardTokenDispatcher;
use zklink::tests::mocks::non_standard_token::INonStandardTokenDispatcherTrait;
use zklink::tests::mocks::standard_decimals_token::StandardDecimalsToken;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcher;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcherTrait;
use zklink::tests::mocks::verifier_test::IVerifierMock;
use zklink::tests::mocks::verifier_test::IVerifierMockDispatcher;
use zklink::tests::mocks::verifier_test::IVerifierMockDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::Token;
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::data_structures::DataStructures::StoredBlockInfo;

fn getStoredBlockTemplate() -> StoredBlockInfo {
    StoredBlockInfo {
        blockNumber: 5,
        priorityOperations: 7,
        pendingOnchainOperationsHash: 0xcf2ef9f8da5935a514cc25835ea39be68777a2674197105ca904600f26547ad2,
        timestamp: 1652422395,
        stateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        commitment: 0x6104d07f7c285404dc58dd0b37894b20c4193a231499a20e4056d119fc2c1184,
        syncHash: 0xab04d07f7c285404dc58dd0b37894b20c4193a231499a20e4056d119fc2c1184
    }
}


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_performExodus_when_active() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let owner = defaultSender;
    let accountId = 245;
    let subAccountId = 2;
    let tokenId = 58;
    let amount = 1560000000000000000; // 1.56 Ether
    let proof = array![3, 0, 9, 5];
    let storedBlock = getStoredBlockTemplate();

    set_contract_address(defaultSender);
    zklink_dispatcher
        .performExodus(
            storedBlock,
            utils::extendAddress(owner),
            accountId,
            subAccountId,
            tokenId,
            tokenId,
            amount,
            proof
        );
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_cancelOutstandingDepositsForExodusMode_when_active() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let owner = defaultSender;
    let accountId = 245;
    let subAccountId = 2;
    let tokenId = 58;
    let amount = 1560000000000000000; // 1.56 Ether
    let proof = array![3, 0, 9, 5];
    let storedBlock = getStoredBlockTemplate();

    set_contract_address(defaultSender);
    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(3, array![]);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_activateExodusMode_twice() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether

    // expire block is zero in unit test environment
    // cairo-test defualt block number is 0
    set_block_number(5);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);

    zklink_dispatcher.activateExodusMode();
    utils::assert_event_ExodusMode(zklink);

    // active agian should failed
    zklink_dispatcher.activateExodusMode();
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('y1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_performExodus_not_last_block() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let block5 = getStoredBlockTemplate();
    let mut block6 = getStoredBlockTemplate();
    block6.blockNumber = 6;

    // active exodus mode
    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether
    set_block_number(5);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);

    zklink_dispatcher.activateExodusMode();

    // mock exec block
    zklink_dispatcher.mockExecBlock(block5);
    zklink_dispatcher.mockExecBlock(block6);

    let owner = utils::extendAddress(defaultSender);
    let accountId = 245;
    let subAccountId = 2;
    let tokenId = 58;
    let amount = 1560000000000000000; // 1.56 Ether
    let proof = array![3, 0, 9, 5];

    zklink_dispatcher
        .performExodus(block5, owner, accountId, subAccountId, tokenId, tokenId, amount, proof);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('y2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_performExodus_verify_failed() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let verifier = *addrs[7];
    let verifier_dispatcher = IVerifierMockDispatcher { contract_address: verifier };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let block5 = getStoredBlockTemplate();
    let mut block6 = getStoredBlockTemplate();
    block6.blockNumber = 6;

    // active exodus mode
    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether
    set_block_number(6);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);

    zklink_dispatcher.activateExodusMode();

    // mock exec block
    zklink_dispatcher.mockExecBlock(block5);
    zklink_dispatcher.mockExecBlock(block6);

    let owner = utils::extendAddress(defaultSender);
    let accountId = 245;
    let subAccountId = 2;
    let tokenId = 58;
    let amount = 1560000000000000000; // 1.56 Ether
    let proof = array![3, 0, 9, 5];

    // verify failed
    verifier_dispatcher.setVerifyResult(false);

    zklink_dispatcher
        .performExodus(block6, owner, accountId, subAccountId, tokenId, tokenId, amount, proof);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('y0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_performExodus_twice() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let verifier = *addrs[7];
    let verifier_dispatcher = IVerifierMockDispatcher { contract_address: verifier };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let block5 = getStoredBlockTemplate();
    let mut block6 = getStoredBlockTemplate();
    block6.blockNumber = 6;

    // active exodus mode
    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether
    set_block_number(6);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);

    zklink_dispatcher.activateExodusMode();
    utils::drop_event(zklink);

    // mock exec block
    zklink_dispatcher.mockExecBlock(block5);
    zklink_dispatcher.mockExecBlock(block6);

    let owner = utils::extendAddress(defaultSender);
    let accountId = 245;
    let subAccountId = 2;
    let tokenId = 58;
    let amount = 1560000000000000000; // 1.56 Ether
    let proof = array![3, 0, 9, 5];

    zklink_dispatcher
        .performExodus(
            block6, owner, accountId, subAccountId, tokenId, tokenId, amount, proof.clone()
        );
    utils::assert_event_WithdrawalPending(zklink, tokenId, owner, amount);

    let balance = zklink_dispatcher.getPendingBalance(owner, tokenId);
    assert(amount == balance, 'getPendingBalance');

    // duplicate perform should be failed
    zklink_dispatcher
        .performExodus(block6, owner, accountId, subAccountId, tokenId, tokenId, amount, proof);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_performExodus_diff_subaccountId_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let verifier = *addrs[7];
    let verifier_dispatcher = IVerifierMockDispatcher { contract_address: verifier };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let block5 = getStoredBlockTemplate();
    let mut block6 = getStoredBlockTemplate();
    block6.blockNumber = 6;

    // active exodus mode
    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether
    set_block_number(6);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);

    zklink_dispatcher.activateExodusMode();
    utils::drop_event(zklink);

    // mock exec block
    zklink_dispatcher.mockExecBlock(block5);
    zklink_dispatcher.mockExecBlock(block6);

    let owner = utils::extendAddress(defaultSender);
    let accountId = 245;
    let subAccountId = 2;
    let tokenId = 58;
    let amount = 1560000000000000000; // 1.56 Ether
    let proof = array![3, 0, 9, 5];

    zklink_dispatcher
        .performExodus(
            block6, owner, accountId, subAccountId, tokenId, tokenId, amount, proof.clone()
        );
    utils::drop_event(zklink);

    // diff subAccount should success
    let subAccountId1 = 3;
    let amount1 = 500000000000000000; // 0.5 Ether

    zklink_dispatcher
        .performExodus(block6, owner, accountId, subAccountId1, tokenId, tokenId, amount1, proof);
    utils::assert_event_WithdrawalPending(zklink, tokenId, owner, amount1);

    let balance = zklink_dispatcher.getPendingBalance(owner, tokenId);
    assert(balance == amount1 + amount, 'getPendingBalance');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('A0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_cancelOutstandingDepositsForExodusMode_no_priority_request() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    // active exodus mode
    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether
    set_block_number(6);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);
    zklink_dispatcher.activateExodusMode();
    utils::drop_event(zklink);

    // there should be priority requests exist
    zklink_dispatcher.setTotalOpenPriorityRequests(0);
    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(3, array![]);
}

// calculate pubData from Python
// from eth_abi.packed import encode_abi_packed
// def cal():
//     data = encode_abi_packed(encode_format, example)
//     size = len(data)
//     data += b'\x00' * (16 - size % 16)
//     data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]
//     print(size)
//     print(data)

#[test]
#[available_gas(20000000000)]
fn test_zklink_cancelOutstandingDepositsForExodusMode_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let token3: Token = *tokens[2];

    set_contract_address(defaultSender);
    token2_dispatcher.mint(1000000000000000000000); // 1000 Ether
    token2_dispatcher.approve(zklink, 1000000000000000000000); // 1000 Ether
    let amount0 = 4000000000000000000; // 4 Ether
    let amount1 = 10000000000000000000; // 10 Ether
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, amount0, utils::extendAddress(defaultSender), 0, false);

    set_contract_address(alice);
    zklink_dispatcher.requestFullExit(14, 2, token3.tokenId, false);

    set_contract_address(defaultSender);
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, amount1, utils::extendAddress(alice), 1, false);

    // active exodus mode
    zklink_dispatcher.setExodus(true);

    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 34, 34, 4000000000000000000, 0x64656661756c7453656e646572]
    //
    // size 59
    // data = [1334420292643450702982333137294458880, 4398046511104000000000000000000, 25701, 136087289999905557079838814080235208704]
    let pubdata0: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450702982333137294458880,
            4398046511104000000000000000000,
            25701,
            136087289999905557079838814080235208704
        ]
    );

    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 1, 34, 34, 10000000000000000000, 0x616c696365]
    //
    // size 59
    // data = [1334420292643455425348816006939672576, 10995116277760000000000000000000, 0, 460069391222763568496640]
    let pubdata1: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643455425348816006939672576,
            10995116277760000000000000000000,
            0,
            460069391222763568496640
        ]
    );

    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(3, array![pubdata0, pubdata1]);
    let balance0 = zklink_dispatcher
        .getPendingBalance(utils::extendAddress(defaultSender), token2.tokenId);
    let balance1 = zklink_dispatcher.getPendingBalance(utils::extendAddress(alice), token2.tokenId);

    assert(balance0 == amount0, 'getPendingBalance0');
    assert(balance1 == amount1, 'getPendingBalance1');
}