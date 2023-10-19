use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, ClassHash};

// define the interface
#[starknet::interface]
trait IActions<TContractState> {
    fn attack(self: @TContractState, game_id: felt252, list: Array<u8>);
}

#[dojo::contract]
mod actions {
    use starknet::{ContractAddress, get_caller_address};
    use core::debug::PrintTrait;

    use super::IActions;

    use battleship_game::models::common::{Square, Ship, Game, GameStatus};

    // declaring custom event struct
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Hit: Hit,
        Missed: Missed,
        Sinked: Sinked
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct Hit {
        player: ContractAddress,
        square: Square
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct Missed {
        player: ContractAddress,
        square: Square
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct Sinked {
        player: ContractAddress,
        ship: Ship
    }

    // impl: implement functions specified in trait
    #[external(v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn attack(self: @ContractState, game_id: felt252, list: Array<u8>) {
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            let game: Game = get!(world, (game_id), (Game));
            assert(game.status == GameStatus::Battle, 'game not ready');
        // game.print(); // sozo build throws error, but sozo test - no
        }
    }
}

#[cfg(test)]
mod tests {
    use core::option::OptionTrait;
    use core::debug::PrintTrait;
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use core::traits::Into;
    use core::array::SpanTrait;
    use starknet::class_hash::Felt252TryIntoClassHash;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import actions
    use super::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    // import models
    use battleship_game::models::common::{
        Game, game, GameTurn, game_turn, GameStatus, Team, Ship, Square, TeamIntoFelt
    };
    use battleship_game::models::blueteam::{BlueFleet, BlueGrid};

    fn get_first() -> ContractAddress {
        starknet::contract_address_const::<0x01>()
    }
    fn get_second() -> ContractAddress {
        starknet::contract_address_const::<0x02>()
    }
    fn game_id() -> felt252 {
        pedersen::pedersen(get_first().into(), get_second().into())
    }

    fn init() -> (IWorldDispatcher, IActionsDispatcher) {
        let first = get_first();
        let second = get_second();

        // models
        let mut models = array::ArrayTrait::new();
        models.append(game::TEST_CLASS_HASH);
        models.append(game_turn::TEST_CLASS_HASH);

        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        (world, actions_system)
    }

    fn get_ready(world: IWorldDispatcher) {}

    #[test]
    #[should_panic]
    #[available_gas(20000000000000)]
    fn game_not_ready() {
        let (world, actions_system) = init();
        let first = get_first();
        let second = get_second();
        let id = game_id();

        actions_system.attack(id, array![1, 1, 1, 1, 1]);
    }
}
