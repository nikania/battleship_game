#[system]
mod attack_system {
    use core::debug::PrintTrait;
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use dojo::world::Context;
    use starknet::ContractAddress;

    use battleship_game::components::common::{
        Game, GameTurn, Team, GameStatus, Ship, Square, TeamIntoFelt
    };
    use battleship_game::components::blueteam::{BlueFleet, BlueGrid};

    fn execute(
        ctx: Context, //game_id: felt252, player: ContractAddress, 
         ref list: Array<u8>
    ) { // let game: Game = get!(ctx.world, (game_id), (Game));
        '1'.print();
        let mut len = list.len();
        len.print();
        '2'.print();
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

    use dojo::test_utils::spawn_test_world;
    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};

    use battleship_game::components::common::{
        Game, game, GameTurn, game_turn, GameStatus, Team, Ship, Square, TeamIntoFelt
    };
    use battleship_game::components::blueteam::{BlueFleet, BlueGrid};
    use battleship_game::systems::{initiate_system, preparation_system, attack_system};

    fn first() -> ContractAddress {
        starknet::contract_address_const::<0x01>()
    }
    fn second() -> ContractAddress {
        starknet::contract_address_const::<0x02>()
    }
    fn game_id() -> felt252 {
        pedersen::pedersen(first().into(), second().into())
    }

    fn init() -> IWorldDispatcher {
        let first = first();
        let second = second();

        // components
        let mut components = array::ArrayTrait::new();
        components.append(game::TEST_CLASS_HASH);
        components.append(game_turn::TEST_CLASS_HASH);

        //systems
        let mut systems = array::ArrayTrait::new();
        systems.append(initiate_system::TEST_CLASS_HASH);
        systems.append(preparation_system::TEST_CLASS_HASH);
        systems.append(attack_system::TEST_CLASS_HASH);
        let world = spawn_test_world(components, systems);

        let mut calldata = array::ArrayTrait::<core::felt252>::new();
        calldata.append(first.into());
        calldata.append(second.into());
        world.execute('initiate_system'.into(), calldata);
        world
    }

    #[test]
    #[available_gas(20000000000000)]
    fn testttt() {
        let world = init();
        let first = first();
        let second = second();
        let id = game_id();

        let mut calldata = array::ArrayTrait::<core::felt252>::new();
        //array![id, first.into()];

        calldata.append(1.into());
        calldata.append(1.into());
        // calldata.append(1.into());
        // calldata.append(1.into());

        'calldata'.print();
        world.execute('attack_system'.into(), calldata);
        'atacck called'.print();
    }
}
