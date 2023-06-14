use array::ArrayTrait;
use zklink::utils::keccak::keccak_u128s_be;


#[test]
#[available_gas(2000000)]
fn test_keccak_u128s_be() {
    let mut array: Array<u128> = ArrayTrait::<u128>::new();
    array.append(0);
    array.append(1);

    // 0x0000000000000000000000000000000000000000000000000000000000000001
    let res: u256 = keccak_u128s_be(array.span());
    let hash: u256 = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;

    assert(res == hash, 'keccak_1_wrong');

    array.append(0);
    array.append(2);
    array.append(0);
    array.append(3);
    array.append(0);
    array.append(4);

    // 0x0000000000000000000000000000000000000000000000000000000000000001
    // 0x0000000000000000000000000000000000000000000000000000000000000002
    // 0x0000000000000000000000000000000000000000000000000000000000000003
    // 0x0000000000000000000000000000000000000000000000000000000000000004
    let res: u256 = keccak_u128s_be(array.span());
    let hash: u256 = 0x392791df626408017a264f53fde61065d5a93a32b60171df9d8a46afdf82992d;
    assert(res == hash, 'keccak_2_wrong');
}