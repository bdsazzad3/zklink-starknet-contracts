use core::traits::Into;
use core::array::ArrayTrait;
use core::traits::TryInto;
use option::OptionTrait;
use zklink::utils::math::{
    u128_split,
    felt252_fast_pow2
};
use zklink::utils::bytes::{
    Bytes,
    BytesTrait
};
use zklink::utils::keccak::keccak_u128s_be;
use zklink::utils::array_ext::ArrayTraitExt;


// https://github.com/keep-starknet-strange/alexandria/blob/main/alexandria/data_structures/src/data_structures.cairo
/// Returns the slice of an array.
/// * `arr` - The array to slice.
/// * `begin` - The index to start the slice at.
/// * `end` - The index to end the slice at (not included).
/// # Returns
/// * `Array<u128>` - The slice of the array.
fn u128_array_slice(src: @Array<u128>, mut begin: usize, end: usize) -> Array<u128> {
    let mut slice = ArrayTrait::new();
    let len = begin + end;
    loop {
        if begin >= len {
            break ();
        }
        if begin >= src.len() {
            break ();
        }

        slice.append(*src[begin]);
        begin += 1;
    };
    slice
}

// new_hash = hash(old_hash + bytes)
fn concatHash(_hash: u256, _bytes: @Bytes) -> u256 {
    let mut hash_data: Array<u128> = ArrayTrait::new();

    // append _hash
    hash_data.append(_hash.high);
    hash_data.append(_hash.low);

    // process _bytes
    let (last_data_index, last_element_size) = BytesTrait::locate(*_bytes.size);
    let mut bytes_data = u128_array_slice(_bytes.data, 0, last_data_index);
    // To cumpute hash, we should remove 0 padded
    let (last_element_value, _) = u128_split(*_bytes.data[last_data_index], 16, last_element_size);
    
    // append _bytes
    hash_data.append_all(ref bytes_data);
    hash_data.append(last_element_value);
    keccak_u128s_be(hash_data.span())
}