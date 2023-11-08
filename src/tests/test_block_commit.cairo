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
    let zklink = *addrs[6];
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

    dispatcher.testCollectOnchainOps(block, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_length2() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
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

    dispatcher.testCollectOnchainOps(block, true);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_collectOnchainOps_no_pubdata() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
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

    let (processableOperationsHash, priorityOperationsProcessed, offsetsCommitment,
    onchainOperationPubdataHashs) =
        dispatcher
        .testCollectOnchainOps(block, true);

    assert(processableOperationsHash == EMPTY_STRING_KECCAK, 'invalid value 0');
    assert(priorityOperationsProcessed == 0, 'invalid value 1');
    assert(offsetsCommitment.size() == 0, 'invalid value 2');
    assert(*onchainOperationPubdataHashs[0] == 0, 'invalid value 3');
    assert(*onchainOperationPubdataHashs[1] == EMPTY_STRING_KECCAK, 'invalid value 3');
    assert(*onchainOperationPubdataHashs[2] == EMPTY_STRING_KECCAK, 'invalid value 4');
    assert(*onchainOperationPubdataHashs[3] == EMPTY_STRING_KECCAK, 'invalid value 5');
    assert(*onchainOperationPubdataHashs[4] == EMPTY_STRING_KECCAK, 'invalid value 6');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset1() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new(), publicDataOffset: publicData.size()
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset2() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new(), publicDataOffset: 1
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset3() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new(), publicDataOffset: CHUNK_BYTES - 2
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('k2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_op_type() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut publicData: Bytes = BytesTrait::new();
    publicData.append_u16(0x0001);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new(), publicDataOffset: 0
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block, true);
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
    let zklink = *addrs[6];
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

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new(), publicDataOffset: 0
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('i1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_chain_id2() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
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

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new(), publicDataOffset: 0
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_duplicate_pubdata_offset() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    // depositData0 and depositData1
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 2, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1339612589503194456358419569248829440, 549787120963470, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11

    let mut depositData0 = Bytes {
        data: array![
            1339612589503194456358419569248829440,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    let mut depositData1 = Bytes {
        data: array![
            1339612589503194456358419569248829440,
            549787120963470,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };

    utils::paddingChunk(ref depositData0, utils::OP_DEPOSIT_CHUNKS);
    utils::paddingChunk(ref depositData1, utils::OP_DEPOSIT_CHUNKS);

    depositData0.concat(@depositData1);

    let onchainOperations: Array<OnchainOperationData> = array![
        OnchainOperationData { ethWitness: BytesTrait::new(), publicDataOffset: 0 },
        OnchainOperationData { ethWitness: BytesTrait::new(), publicDataOffset: 0 }
    ];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: depositData0,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block, false);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_collectOnchainOps_success() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
    let mut dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let mut pubdatas: Bytes = BytesTrait::new();
    let mut pubdatasOfChain1: Bytes = BytesTrait::new();
    let mut ops: Array<OnchainOperationData> = array![];
    let mut opsOfChain1: Array<OnchainOperationData> = array![];
    // no op of chain 2
    let mut onchainOpPubdataHash1: u256 = EMPTY_STRING_KECCAK;
    let mut onchainOpPubdataHash3: u256 = EMPTY_STRING_KECCAK;
    let mut onchainOpPubdataHash4: u256 = EMPTY_STRING_KECCAK;
    let mut publicDataOffset: usize = 0;
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
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
    publicDataOffsetOfChain1 += op.size();
    priorityOperationsProcessed += 1;
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // change pubkey of chain 3
    // encode_format = ["uint8","uint8","uint32","uint8","uint160","uint256","uint32","uint16","uint16"]
    // example = [6, 3, 2, 0, 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d, 32, 37, 145]
    //
    // data = [7990944865287520720191985022115949226, 226854911280625642308916404252811464590, 179892997260459296479640320015568236610, 3577810954935998486498406173769736192]
    // pending_data = 2424977
    // pending_data_size = 3
    let mut op = Bytes {
        data: array![
            7990944865287520720191985022115949226,
            226854911280625642308916404252811464590,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769736192
        ],
        pending_data: 2424977,
        pending_data_size: 3
    };
    utils::paddingChunk(ref op, utils::OP_CHANGE_PUBKEY_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash3 = concatHash(onchainOpPubdataHash3, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // transfer of chain 4
    // encode_format = ["uint8","uint32","uint8","uint16","uint40","uint32","uint8","uint16"]
    // example = [4, 1, 0, 33, 456, 4, 3, 34]
    //
    // data = [5316911983449149110179127749911773184]
    // pending_data = 67305506
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![5316911983449149110179127749911773184],
        pending_data: 67305506,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_TRANSFER_CHUNKS);
    pubdatas.concat(@op);
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, false);

    // deposit of chain4
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 4, 3, 6, 35, 35, 345, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1349997183222710297597724425227075584, 379362818658190, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            1349997183222710297597724425227075584,
            379362818658190,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    utils::paddingChunk(ref op, utils::OP_DEPOSIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // full exit of chain4
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 4, 43, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 35, 35, 245]
    //
    // data = [6666909166410712037873566033893757948, 42577624153754863967194330481103536495, 278544165408887043319642418119171899392]
    // pending_data = 245
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            6666909166410712037873566033893757948,
            42577624153754863967194330481103536495,
            278544165408887043319642418119171899392
        ],
        pending_data: 245,
        pending_data_size: 11
    };
    utils::paddingChunk(ref op, utils::OP_FULL_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // mock Noop
    // encode_format = ["uint8"]
    // example = [0]
    //
    // data = []
    // pending_data_size = 1
    let mut op = Bytes { data: array![], pending_data: 1, pending_data_size: 1 };
    utils::paddingChunk(ref op, utils::OP_NOOP_CHUNKS);
    pubdatas.concat(@op);
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, false);

    // force exit of chain3
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [7, 3, 30, 7, 3, 43, 2, 35, 35, 245, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [9320172861106316424366063172242647810, 181733163034406966250383145560965120, 19413155728529532836176956146393, 227142569737839188506614686513323349732]
    // pending_data = 1646442285
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            9320172861106316424366063172242647810,
            181733163034406966250383145560965120,
            19413155728529532836176956146393,
            227142569737839188506614686513323349732
        ],
        pending_data: 1646442285,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash3 = concatHash(onchainOpPubdataHash3, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // withdraw of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8"]
    // example = [3, 1, 5, 0, 34, 34, 900, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 1]
    //
    // data = [3992876284219327077888020403728678912, 989561019029737, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792]
    // pending_data = 234893825
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            3992876284219327077888020403728678912,
            989561019029737,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792
        ],
        pending_data: 234893825,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
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
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
    publicDataOffsetOfChain1 += op.size();
    priorityOperationsProcessed += 1;
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // force exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [7, 1, 13, 4, 0, 23, 2, 35, 35, 2450, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [9309788267368680863076101576143673090, 181733163034406966250383145560965120, 194111254072482397229941366637273, 227142569737839188506614686513323349732]
    // pending_data = 1646442285
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            9309788267368680863076101576143673090,
            181733163034406966250383145560965120,
            194111254072482397229941366637273,
            227142569737839188506614686513323349732
        ],
        pending_data: 1646442285,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // withdraw of chain 4
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8"]
    // example = [3, 4, 15, 5, 34, 34, 1000, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 0]
    //
    // data = [4008453174807044430802172532689469440, 1099512181807337, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792]
    // pending_data = 234893824
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            4008453174807044430802172532689469440,
            1099512181807337,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792
        ],
        pending_data: 234893824,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

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
        actual_offsetsCommitment,
        actual_onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block, false);

    assert(actual_processableOperationsHash == processableOpPubdataHash, 'invaid value1');
    assert(actual_priorityOperationsProcessed == priorityOperationsProcessed, 'invaid value2');
    assert(actual_offsetsCommitment.size() == offsetsCommitment.size(), 'invaid value3');
    assert(*actual_offsetsCommitment.data[0] == *offsetsCommitment.data[0], 'invaid value4');
    assert(
        actual_offsetsCommitment.pending_data == offsetsCommitment.pending_data, 'invaid value5'
    );
    assert(*actual_onchainOperationPubdataHashs[0] == 0, 'invaid value6');
    assert(*actual_onchainOperationPubdataHashs[1] == onchainOpPubdataHash1, 'invaid value7');
    assert(*actual_onchainOperationPubdataHashs[2] == EMPTY_STRING_KECCAK, 'invaid value8');
    assert(*actual_onchainOperationPubdataHashs[3] == onchainOpPubdataHash3, 'invaid value9');
    assert(*actual_onchainOperationPubdataHashs[4] == onchainOpPubdataHash4, 'invaid value10');
}


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('g0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_testCommitOneBlock_invalid_block_number() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
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

    dispatcher.testCommitOneBlock(preBlock, commitBlock, false, extraBlock);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('g2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_testCommitOneBlock_invalid_timestamp() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
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

    dispatcher.testCommitOneBlock(preBlock, commitBlock, false, extraBlock);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_testCommitOneBlock_commit_compressed_block() {
    let (addrs, _) = utils::prepare_test_deploy();
    let zklink = *addrs[6];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    // build test block
    let mut pubdatas: Bytes = BytesTrait::new();
    let mut pubdatasOfChain1: Bytes = BytesTrait::new();
    let mut ops: Array<OnchainOperationData> = array![];
    let mut opsOfChain1: Array<OnchainOperationData> = array![];
    // no op of chain 2
    let mut onchainOpPubdataHash1: u256 = EMPTY_STRING_KECCAK;
    let mut onchainOpPubdataHash3: u256 = EMPTY_STRING_KECCAK;
    let mut onchainOpPubdataHash4: u256 = EMPTY_STRING_KECCAK;
    let mut publicDataOffset: usize = 0;
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
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
    publicDataOffsetOfChain1 += op.size();
    priorityOperationsProcessed += 1;
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // change pubkey of chain 3
    // encode_format = ["uint8","uint8","uint32","uint8","uint160","uint256","uint32","uint16","uint16"]
    // example = [6, 3, 2, 0, 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d, 32, 37, 145]
    //
    // data = [7990944865287520720191985022115949226, 226854911280625642308916404252811464590, 179892997260459296479640320015568236610, 3577810954935998486498406173769736192]
    // pending_data = 2424977
    // pending_data_size = 3
    let mut op = Bytes {
        data: array![
            7990944865287520720191985022115949226,
            226854911280625642308916404252811464590,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769736192
        ],
        pending_data: 2424977,
        pending_data_size: 3
    };
    utils::paddingChunk(ref op, utils::OP_CHANGE_PUBKEY_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash3 = concatHash(onchainOpPubdataHash3, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // transfer of chain 4
    // encode_format = ["uint8","uint32","uint8","uint16","uint40","uint32","uint8","uint16"]
    // example = [4, 1, 0, 33, 456, 4, 3, 34]
    //
    // data = [5316911983449149110179127749911773184]
    // pending_data = 67305506
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![5316911983449149110179127749911773184],
        pending_data: 67305506,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_TRANSFER_CHUNKS);
    pubdatas.concat(@op);
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, false);

    // deposit of chain4
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 4, 3, 6, 35, 35, 345, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [1349997183222710297597724425227075584, 379362818658190, 179892997260459296479640320015568236610]
    // pending_data = 3254000107459431534606125
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            1349997183222710297597724425227075584,
            379362818658190,
            179892997260459296479640320015568236610
        ],
        pending_data: 3254000107459431534606125,
        pending_data_size: 11
    };
    utils::paddingChunk(ref op, utils::OP_DEPOSIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // full exit of chain4
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 4, 43, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 35, 35, 245]
    //
    // data = [6666909166410712037873566033893757948, 42577624153754863967194330481103536495, 278544165408887043319642418119171899392]
    // pending_data = 245
    // pending_data_size = 11
    let mut op = Bytes {
        data: array![
            6666909166410712037873566033893757948,
            42577624153754863967194330481103536495,
            278544165408887043319642418119171899392
        ],
        pending_data: 245,
        pending_data_size: 11
    };
    utils::paddingChunk(ref op, utils::OP_FULL_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // mock Noop
    // encode_format = ["uint8"]
    // example = [0]
    //
    // data = []
    // pending_data_size = 1
    let mut op = Bytes { data: array![], pending_data: 1, pending_data_size: 1 };
    utils::paddingChunk(ref op, utils::OP_NOOP_CHUNKS);
    pubdatas.concat(@op);
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, false);

    // force exit of chain3
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [7, 3, 30, 7, 3, 43, 2, 35, 35, 245, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [9320172861106316424366063172242647810, 181733163034406966250383145560965120, 19413155728529532836176956146393, 227142569737839188506614686513323349732]
    // pending_data = 1646442285
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            9320172861106316424366063172242647810,
            181733163034406966250383145560965120,
            19413155728529532836176956146393,
            227142569737839188506614686513323349732
        ],
        pending_data: 1646442285,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash3 = concatHash(onchainOpPubdataHash3, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // withdraw of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8"]
    // example = [3, 1, 5, 0, 34, 34, 900, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 1]
    //
    // data = [3992876284219327077888020403728678912, 989561019029737, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792]
    // pending_data = 234893825
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            3992876284219327077888020403728678912,
            989561019029737,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792
        ],
        pending_data: 234893825,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
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
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
    publicDataOffsetOfChain1 += op.size();
    priorityOperationsProcessed += 1;
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // force exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [7, 1, 13, 4, 0, 23, 2, 35, 35, 2450, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // data = [9309788267368680863076101576143673090, 181733163034406966250383145560965120, 194111254072482397229941366637273, 227142569737839188506614686513323349732]
    // pending_data = 1646442285
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            9309788267368680863076101576143673090,
            181733163034406966250383145560965120,
            194111254072482397229941366637273,
            227142569737839188506614686513323349732
        ],
        pending_data: 1646442285,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    publicDataOffset += op.size();
    utils::createOffsetCommitment(ref offsetsCommitment, @op, true);

    // withdraw of chain 4
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8"]
    // example = [3, 4, 15, 5, 34, 34, 1000, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 0]
    //
    // data = [4008453174807044430802172532689469440, 1099512181807337, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792]
    // pending_data = 234893824
    // pending_data_size = 4
    let mut op = Bytes {
        data: array![
            4008453174807044430802172532689469440,
            1099512181807337,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792
        ],
        pending_data: 234893824,
        pending_data_size: 4
    };
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new(), publicDataOffset: publicDataOffset
            }
        );
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

    let extraBlock = CompressedBlockExtraInfo {
        publicDataHash: 0, offsetCommitmentHash: 0, onchainOperationPubdataHashs: array![]
    };

    let mut commitBlock = CommitBlockInfo {
        newStateHash: 5,
        publicData: BytesTrait::new(),
        timestamp: 1652422395,
        onchainOperations: array![],
        blockNumber: 11,
        feeAccount: 0
    };
    commitBlock.timestamp = preBlock.timestamp + 1;
    commitBlock.publicData = pubdatas.clone();
    commitBlock.onchainOperations = ops;

    let r0: StoredBlockInfo = dispatcher
        .testCommitOneBlock(preBlock, commitBlock, false, extraBlock);

    let compressedBlock = CommitBlockInfo {
        newStateHash: 5,
        publicData: pubdatasOfChain1,
        timestamp: 1652422396,
        onchainOperations: opsOfChain1,
        blockNumber: 11,
        feeAccount: 0
    };

    let extraBlock = CompressedBlockExtraInfo {
        publicDataHash: pubdatas.keccak(),
        offsetCommitmentHash: offsetsCommitment.keccak(),
        onchainOperationPubdataHashs: array![
            0,
            onchainOpPubdataHash1,
            EMPTY_STRING_KECCAK,
            onchainOpPubdataHash3,
            onchainOpPubdataHash4
        ]
    };

    let r1: StoredBlockInfo = dispatcher
        .testCommitOneBlock(preBlock, compressedBlock, true, extraBlock);

    assert(r1.blockNumber == r0.blockNumber, 'invaid value1');
    assert(r1.priorityOperations == r0.priorityOperations, 'invaid value2');
    assert(r1.pendingOnchainOperationsHash == r0.pendingOnchainOperationsHash, 'invaid value3');
    assert(r1.timestamp == r0.timestamp, 'invaid value4');
    assert(r1.stateHash == r0.stateHash, 'invaid value5');
    assert(r1.commitment == r0.commitment, 'invaid value6');
    assert(r1.syncHash == r0.syncHash, 'invaid value7');
}
