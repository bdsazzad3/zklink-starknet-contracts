use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IZklinkUpgradeV2<TContractState> {
    fn getMaster(self: @TContractState) -> ContractAddress;
    fn transferMastership(self: @TContractState, _newMaster: ContractAddress);
    fn upgrade(self: @TContractState, impl_hash: ClassHash);
    fn getNoticePeriod(self: @TContractState) -> u256;
    fn isReadyForUpgrade(self: @TContractState) -> bool;
    fn setExodus(self: @TContractState, _exodusMode: bool);
    fn set_value1(ref self: TContractState, value: felt252);
    fn get_value1(self: @TContractState) -> felt252;
    fn set_value2(ref self: TContractState, value: felt252);
    fn get_value2(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod ZklinkUpgradeV2 {
    use starknet::{ContractAddress, ClassHash};
    use zklink::contracts::zklink::Zklink;
    use zklink::contracts::zklink::Zklink::{
        masterContractMemberStateTrait, exodusModeContractMemberStateTrait
    };

    #[storage]
    struct Storage {
        _governor: ContractAddress,
        value1: felt252,
        value2: felt252
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _master: ContractAddress,
        _verifierAddress: ContractAddress,
        _networkGovernor: ContractAddress,
        _blockNumber: u64,
        _timestamp: u64,
        _stateHash: u256,
        _commitment: u256,
        _syncHash: u256
    ) {
        self._governor.write(_networkGovernor);
        let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
        Zklink::constructor(
            ref state,
            _master,
            _verifierAddress,
            _networkGovernor,
            _blockNumber,
            _timestamp,
            _stateHash,
            _commitment,
            _syncHash
        );
    }

    #[external(v0)]
    impl ZklinkUpgradeV1Impl of super::IZklinkUpgradeV2<ContractState> {
        fn getMaster(self: @ContractState) -> ContractAddress {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.master.read()
        }

        fn transferMastership(self: @ContractState, _newMaster: ContractAddress) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::transferMastership(ref state, _newMaster);
        }

        fn upgrade(self: @ContractState, impl_hash: ClassHash) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::upgrade(ref state, impl_hash);
        }

        fn setExodus(self: @ContractState, _exodusMode: bool) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.exodusMode.write(_exodusMode);
        }

        fn getNoticePeriod(self: @ContractState) -> u256 {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::getNoticePeriod(@state)
        }

        fn isReadyForUpgrade(self: @ContractState) -> bool {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::isReadyForUpgrade(@state)
        }

        fn set_value1(ref self: ContractState, value: felt252) {
            self.value1.write(value);
        }

        fn get_value1(self: @ContractState) -> felt252 {
            self.value1.read()
        }

        fn set_value2(ref self: ContractState, value: felt252) {
            self.value2.write(value);
        }

        fn get_value2(self: @ContractState) -> felt252 {
            self.value2.read()
        }
    }
}
