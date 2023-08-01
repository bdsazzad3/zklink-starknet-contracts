#[starknet::contract]
mod ReentrancyGuard {
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        entered: bool
    }

    fn start(ref self: ContractState) {
        assert(!self.entered.read(), 'ReentrancyGuard: reentrant call');
        self.entered.write(true);
    }

    fn end(ref self: ContractState) {
        self.entered.write(false);
    }
}