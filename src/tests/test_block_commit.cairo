use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use clone::Clone;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;

use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::contracts::zklink::Zklink::{
    createSyncHash, createBlockCommitmentForSync, buildOnchainOperationPubdataHashs
};
use zklink::utils::data_structures::DataStructures::{
    CommitBlockInfo, OnchainOperationData, StoredBlockInfo, CompressedBlockExtraInfo
};
use zklink::utils::constants::{EMPTY_STRING_KECCAK, CHUNK_BYTES};
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::operations::Operations::{OpType, U8TryIntoOpType};
use zklink::utils::utils::concatHash;
use zklink::tests::utils;
use debug::PrintTrait;


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_length1() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    let onchainOperations: Array<OnchainOperationData> = array![];
    // 1 bytes
    publicData.append_u8(0x01);

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_length2() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    let onchainOperations: Array<OnchainOperationData> = array![];
    // 13 bytes
    publicData.append_u128_packed(0x01010101010101010101010101, 13);

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_collectOnchainOps_no_pubdata() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    // 0 bytes
    let onchainOperations: Array<OnchainOperationData> = array![];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash, priorityOperationsProcessed, currentnchainOperationPubdataHash
    ) =
        dispatcher
        .testCollectOnchainOps(block);

    assert(processableOperationsHash == EMPTY_STRING_KECCAK, 'invalid value 0');
    assert(priorityOperationsProcessed == 0, 'invalid value 1');
    assert(currentnchainOperationPubdataHash == EMPTY_STRING_KECCAK, 'invalid value 3');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset1() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData { publicDataOffset: publicData.size() };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset2() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData { publicDataOffset: 1 };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset3() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData { publicDataOffset: CHUNK_BYTES - 2 };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('k2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_op_type() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u16(0x0001);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData { publicDataOffset: 0 };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

// calculate pubData from Python
// from eth_abi.packed import encode_packed
// def cal():
//     data = encode_packed(encode_format, example)
//     size = len(data)
//     data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]
//     print(data[:-1])
//     print(data[-1])
//     print(size % 16)

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('i1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_chain_id1() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    // chain_id = MIN_CHAIN_ID - 1
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 0, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1329227995786124801101358576590389248, 549787120963470, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11

    let mut publicData = Bytes {
        data: array![
            1329227995786124801101358576590389248,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };

    utils::paddingChunk(ref publicData, utils::OP_DEPOSIT_CHUNKS);

    let onchainOperation = OnchainOperationData { publicDataOffset: 0 };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('i1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_chain_id2() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    // chain_id = MAX_CHAIN_ID + 1
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 5, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1355189480078798939244011058236489728, 549787120963470, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11

    let mut publicData = Bytes {
        data: array![
            1355189480078798939244011058236489728,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    utils::paddingChunk(ref publicData, utils::OP_DEPOSIT_CHUNKS);

    let onchainOperation = OnchainOperationData { publicDataOffset: 0 };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_collectOnchainOps_success() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let mut dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut pubdatas: Bytes = BytesTrait::new();
    let mut ops: Array<OnchainOperationData> = array![];
    let mut onchainOpPubdataHash: u256 = EMPTY_STRING_KECCAK;
    let mut publicDataOffset: usize = 0;
    let mut priorityOperationsProcessed: u64 = 0;
    let mut processableOpPubdataHash: u256 = EMPTY_STRING_KECCAK;

    // deposit of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1334420292644659628729889072919609344, 549787120963470, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            1334420292644659628729889072919609344,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1334420292643450702910274443744903168, 549787120963470, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11
    let opOfWrite = Bytes {
        data: array![
            1334420292643450702910274443744903168,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    dispatcher.testAddPriorityRequest(utils::OP_DEPOSIT.try_into().unwrap(), opOfWrite);
    utils::paddingChunk(ref op, utils::OP_DEPOSIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash = concatHash(onchainOpPubdataHash, @op);
    ops.append(OnchainOperationData { publicDataOffset: publicDataOffset });
    publicDataOffset += op.size();
    priorityOperationsProcessed += 1;

    // withdraw of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8","uint8"]
    // example = [3, 1, 5, 0, 34, 34, 900, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 1, 0]
    //
    // data = [3992876284219327077888020403728678912, 989561019029737, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792]
    // pending_data = 60132819200
    // pending_data_size = 5
    let mut op = Bytes {
        data: array![
            3992876284219327077888020403728678912,
            989561019029737,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792
        ],
        pending_data: 60132819200,
        pending_data_size: 5
    };
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash = concatHash(onchainOpPubdataHash, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops.append(OnchainOperationData { publicDataOffset: publicDataOffset });
    publicDataOffset += op.size();

    // full exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 15, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 33, 33, 14]
    //
    // data = [6651332275801257632038764928014324732, 42577624153754863967194330481103536495, 278544165408887043319498300732072787968]
    // pending_data = 14
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            6651332275801257632038764928014324732,
            42577624153754863967194330481103536495,
            278544165408887043319498300732072787968
        ],
        pending_data: 14,
        pending_data_size: 11
    };
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 15, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 33, 33, 0]
    //
    // data = [6651332275801257632038764928014324732, 42577624153754863967194330481103536495, 278544165408887043319498300732072787968]
    // pending_data = 0
    // pending_data_size = 11
    let opOfWrite = Bytes {
        data: array![
            6651332275801257632038764928014324732,
            42577624153754863967194330481103536495,
            278544165408887043319498300732072787968
        ],
        pending_data: 0,
        pending_data_size: 11
    };
    dispatcher.testAddPriorityRequest(utils::OP_FULL_EXIT.try_into().unwrap(), opOfWrite);
    utils::paddingChunk(ref op, utils::OP_FULL_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash = concatHash(onchainOpPubdataHash, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops.append(OnchainOperationData { publicDataOffset: publicDataOffset });
    publicDataOffset += op.size();
    priorityOperationsProcessed += 1;

    // force exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint8","uint256"]
    // example = [7, 1, 13, 4, 0, 23, 2, 34, 34, 2450, 0, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [9309788267368680863076101576143673090, 176540786947709624357515055687794688, 194109006972105966049986423199426, 289329750748365178750230095700027442326]
    // pending_data = 980898985773
    // pending_data_size = 5
    let mut op = Bytes {
        data: array![
            9309788267368680863076101576143673090,
            176540786947709624357515055687794688,
            194109006972105966049986423199426,
            289329750748365178750230095700027442326
        ],
        pending_data: 980898985773,
        pending_data_size: 5
    };
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash = concatHash(onchainOpPubdataHash, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops.append(OnchainOperationData { publicDataOffset: publicDataOffset });
    publicDataOffset += op.size();

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: pubdatas,
        timestamp: 1652422395,
        onchainOperations: ops,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        actual_processableOperationsHash,
        actual_priorityOperationsProcessed,
        actual_currentOnchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
    assert(actual_processableOperationsHash == processableOpPubdataHash, 'invaid value1');
    assert(actual_priorityOperationsProcessed == priorityOperationsProcessed, 'invaid value2');
    assert(actual_currentOnchainOperationPubdataHashs == onchainOpPubdataHash, 'invaid value7');
}


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('g0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_testCommitOneBlock_invalid_block_number() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let preBlock = StoredBlockInfo {
        blockNumber: 10,
        priorityOperations: 0,
        pendingOnchainOperationsHash: 1,
        timestamp: 1652422395,
        stateHash: 2,
        commitment: 3,
        syncHash: 4
    };

    let mut commitBlock = CommitBlockInfo {
        newStateHash: 5,
        publicData: BytesTrait::new(),
        timestamp: 1652422395,
        onchainOperations: array![],
        blockNumber: 11,
        feeAccount: 0
    };

    let extraBlock = CompressedBlockExtraInfo {
        publicDataHash: 0, offsetCommitmentHash: 0, onchainOperationPubdataHashs: array![]
    };

    commitBlock.blockNumber = 12;

    dispatcher.testCommitOneBlock(preBlock, commitBlock, extraBlock);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('g2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_testCommitOneBlock_invalid_timestamp() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut preBlock = StoredBlockInfo {
        blockNumber: 10,
        priorityOperations: 0,
        pendingOnchainOperationsHash: 1,
        timestamp: 1652422395,
        stateHash: 2,
        commitment: 3,
        syncHash: 4
    };

    let mut commitBlock = CommitBlockInfo {
        newStateHash: 5,
        publicData: BytesTrait::new(),
        timestamp: 1652422395,
        onchainOperations: array![],
        blockNumber: 11,
        feeAccount: 0
    };

    let extraBlock = CompressedBlockExtraInfo {
        publicDataHash: 0, offsetCommitmentHash: 0, onchainOperationPubdataHashs: array![]
    };

    commitBlock.timestamp = preBlock.timestamp - 1;
    preBlock.timestamp = preBlock.timestamp + 1;

    dispatcher.testCommitOneBlock(preBlock, commitBlock, extraBlock);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_testCommitOneBlock_commit_compressed_block() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    // build test block
    let mut pubdatas: Bytes = BytesTrait::new();
    let mut pubdatasOfChain1: Bytes = BytesTrait::new();
    let mut opsOfChain1: Array<OnchainOperationData> = array![];
    let mut onchainOpPubdataHash1: u256 = EMPTY_STRING_KECCAK;
    let mut publicDataOffsetOfChain1: usize = 0;
    let mut priorityOperationsProcessed: u64 = 0;
    let mut processableOpPubdataHash: u256 = EMPTY_STRING_KECCAK;
    let mut offsetsCommitment: Bytes = BytesTrait::new();

    // deposit of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1334420292644659628729889072919609344, 549787120963470, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            1334420292644659628729889072919609344,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1334420292643450702910274443744903168, 549787120963470, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11
    let opOfWrite = Bytes {
        data: array![
            1334420292643450702910274443744903168,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    dispatcher.testAddPriorityRequest(utils::OP_DEPOSIT.try_into().unwrap(), opOfWrite);
    utils::paddingChunk(ref op, utils::OP_DEPOSIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    opsOfChain1.append(OnchainOperationData { publicDataOffset: publicDataOffsetOfChain1 });
    publicDataOffsetOfChain1 += op.size();
    priorityOperationsProcessed += 1;
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // withdraw of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8","uint8"]
    // example = [3, 1, 5, 0, 34, 34, 900, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 1, 0]
    //
    // data = [3992876284219327077888020403728678912, 989561019029737, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792]
    // pending_data = 60132819200
    // pending_data_size = 5
    let mut op = Bytes {
        data: array![
            3992876284219327077888020403728678912,
            989561019029737,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792
        ],
        pending_data: 60132819200,
        pending_data_size: 5
    };
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    opsOfChain1.append(OnchainOperationData { publicDataOffset: publicDataOffsetOfChain1 });
    publicDataOffsetOfChain1 += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // full exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 15, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 33, 33, 14]
    //
    // data = [6651332275801257632038764928014324732, 42577624153754863967194330481103536495, 278544165408887043319498300732072787968]
    // pending_data = 14
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            6651332275801257632038764928014324732,
            42577624153754863967194330481103536495,
            278544165408887043319498300732072787968
        ],
        pending_data: 14,
        pending_data_size: 11
    };
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 15, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 33, 33, 0]
    //
    // data = [6651332275801257632038764928014324732, 42577624153754863967194330481103536495, 278544165408887043319498300732072787968]
    // pending_data = 0
    // pending_data_size = 11
    let opOfWrite = Bytes {
        data: array![
            6651332275801257632038764928014324732,
            42577624153754863967194330481103536495,
            278544165408887043319498300732072787968
        ],
        pending_data: 0,
        pending_data_size: 11
    };
    dispatcher.testAddPriorityRequest(utils::OP_FULL_EXIT.try_into().unwrap(), opOfWrite);
    utils::paddingChunk(ref op, utils::OP_FULL_EXIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    opsOfChain1.append(OnchainOperationData { publicDataOffset: publicDataOffsetOfChain1 });
    publicDataOffsetOfChain1 += op.size();
    priorityOperationsProcessed += 1;
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // force exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint8","uint256"]
    // example = [7, 1, 13, 4, 0, 23, 2, 34, 34, 2450, 0, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [9309788267368680863076101576143673090, 176540786947709624357515055687794688, 194109006972105966049986423199426, 289329750748365178750230095700027442326]
    // pending_data = 980898985773
    // pending_data_size = 5
    let mut op = Bytes {
        data: array![
            9309788267368680863076101576143673090,
            176540786947709624357515055687794688,
            194109006972105966049986423199426,
            289329750748365178750230095700027442326
        ],
        pending_data: 980898985773,
        pending_data_size: 5
    };
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    opsOfChain1.append(OnchainOperationData { publicDataOffset: publicDataOffsetOfChain1 });
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    let preBlock = StoredBlockInfo {
        blockNumber: 10,
        priorityOperations: 0,
        pendingOnchainOperationsHash: 1,
        timestamp: 1652422395,
        stateHash: 2,
        commitment: 3,
        syncHash: 4
    };

    let blockNumber = 11;
    let timestamp = 1652422396;
    let newStateHash = 5;
    let compressedBlock = CommitBlockInfo {
        newStateHash: newStateHash,
        publicData: pubdatasOfChain1,
        timestamp: timestamp,
        onchainOperations: opsOfChain1,
        blockNumber: blockNumber,
        feeAccount: 0
    };

    let extraBlock = CompressedBlockExtraInfo {
        publicDataHash: pubdatas.keccak(),
        offsetCommitmentHash: offsetsCommitment.keccak(),
        onchainOperationPubdataHashs: array![
            0, onchainOpPubdataHash1, EMPTY_STRING_KECCAK, EMPTY_STRING_KECCAK, EMPTY_STRING_KECCAK
        ]
    };

    let commitmentForSync = createBlockCommitmentForSync(@preBlock, @compressedBlock, @extraBlock);
    let onchainOpPubdataHashs: Array<u256> = buildOnchainOperationPubdataHashs(
        onchainOpPubdataHash1, @extraBlock.onchainOperationPubdataHashs
    );
    let syncHash = createSyncHash(4, commitmentForSync, @onchainOpPubdataHashs);

    let r1: StoredBlockInfo = dispatcher.testCommitOneBlock(preBlock, compressedBlock, extraBlock);

    assert(r1.blockNumber == blockNumber, 'invaid value1');
    assert(r1.priorityOperations == priorityOperationsProcessed, 'invaid value2');
    assert(r1.pendingOnchainOperationsHash == processableOpPubdataHash, 'invaid value3');
    assert(r1.timestamp == timestamp, 'invaid value4');
    assert(r1.stateHash == newStateHash, 'invaid value5');
    assert(r1.commitment == 0, 'invaid value6');
    assert(r1.syncHash == syncHash, 'invaid value7');
}
