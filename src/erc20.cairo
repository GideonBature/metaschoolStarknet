#[starknet::contract]
mod cairo_token {

    use starknet::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        decimal: u8,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>, 
    }

    #[constructor]
    fn constructor(ref self: ContractState, _owner:ContractAddress, _name: felt252, _symbol: felt252, _decimal: u8, _total_supply: u256) {
        self.name.write(_name);
        self.symbol.write(_symbol);
        self.decimal.write(_decimal);
        self.owner.write(_owner);

    }

    #[external(v0)]
    #[generate_trait]
    impl CairoTokenTraitImpl of CairoTokenTrait {

        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn totalSupply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            assert(get_caller_address() == self.owner.read(), 'Invalid caller');
            let new_total_supply = self.total_supply.read() + amount;
            self.total_supply.write(new_total_supply);
            let new_balance = self.balances.read(to) + amount;
            self.balances.write(to, new_balance);
        }

        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256){
            let caller: ContractAddress = get_caller_address();
            self._transfer(caller, to, amount);
        }

        fn transferFrom(ref self: ContractState, sender: ContractAddress, to: ContractAddress, amount: u256){
            let caller = get_caller_address();
            assert(self.allowances.read((sender, caller)) >= amount, 'No allowance');
            self.allowances.write((sender, caller), self.allowances.read((sender, caller)) - amount);
            self._transfer(sender, to, amount);
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let caller: ContractAddress = get_caller_address();
            let mut prev_allowance: u256 = self.allowances.read((caller, spender));
            self.allowances.write((caller, spender), prev_allowance + amount);
        }

        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.allowances.read((owner, spender))
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }
    }

    #[generate_trait]
    impl PrivateFunctions of CairoTokenPrivateFunctionsTrait {

        fn _transfer(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) {
            assert(self.balances.read(sender) >= amount, 'Insufficient bal');
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            self.balances.write(sender, self.balances.read(sender) - amount)
        }

    }

}
