#[system]
mod preparation_system {
    use core::option::OptionTrait;
    use dojo::world::Context;
    use starknet::ContractAddress;

    use battleship_game::components::common::{
        Game, GameTurn, Team, GameStatus, Ship, S, TeamIntoFelt
    };
    use battleship_game::components::blueteam::{BlueFleet, BlueGrid};

    fn execute(
        ctx: Context,
        game_id: felt252,
        team: Team,
        addr: ContractAddress,
        ship: Ship,
        init_coord: (u8, u8),
        fin_coord: (u8, u8)
    ) {
        let game: Game = get!(ctx.world, (game_id), (Game));
        initial_checks(@team, @game, @addr);

        let mut coord = check_coordinates(ship, init_coord, fin_coord);

        loop {
            let opt = coord.pop_front();
            if opt == Option::None {
                break;
            }
            let (x, y) = opt.unwrap();
            set!(ctx.world, (BlueGrid { square: S { game_id, x, y }, ship: Option::Some(ship) }));
        }
    }

    fn initial_checks(team: @Team, game: @Game, addr: @ContractAddress) {
        match team {
            Team::Blue => {
                assert(game.blue == addr, 'wrong caller');
            },
            Team::Red => {
                assert(game.red == addr, 'wrong caller');
            },
        }
    }

    use array::ArrayTrait;
    fn check_coordinates(ship: Ship, init_coord: (u8, u8), fin_coord: (u8, u8)) -> Array<(u8, u8)> {
        let mut a = ArrayTrait::new();
        a.append((1, 1));
        a.append((1, 2));
        a
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
        Game, game, GameTurn, game_turn, Square, square, GameStatus, Team, Ship, S, TeamIntoFelt
    };
    use battleship_game::components::blueteam::{BlueFleet, BlueGrid};
    use battleship_game::systems::{initiate_system, preparation_system};

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
        components.append(square::TEST_CLASS_HASH);

        //systems
        let mut systems = array::ArrayTrait::new();
        systems.append(initiate_system::TEST_CLASS_HASH);
        systems.append(preparation_system::TEST_CLASS_HASH);
        let world = spawn_test_world(components, systems);

        let mut calldata = array::ArrayTrait::<core::felt252>::new();
        calldata.append(first.into());
        calldata.append(second.into());
        world.execute('initiate_system'.into(), calldata);
        world
    }

    #[test]
    #[available_gas(20000000000000000)]
    fn ship_placement_correct() {
        let world = init();
        let first = first();
        let second = second();
        let id = game_id();

        let mut calldata = array::ArrayTrait::<core::felt252>::new();
        calldata.append(id);
        calldata.append(Team::Blue.into());
        calldata.append(first.into());
        calldata.append(Ship::Submarine.into());
        calldata.append(1);
        calldata.append(1);
        calldata.append(1);
        calldata.append(2);
        // array![id, Team::Blue.into(), first.into(), Ship::Submarine.into(), (1,1).into(), (1,2).into()];
        world.execute('preparation_system'.into(), calldata);

        let b2: BlueGrid = get!(world, (S { game_id: id, x: 1, y: 1 }), (BlueGrid));
        let b3: BlueGrid = get!(world, (S { game_id: id, x: 1, y: 2 }), (BlueGrid));
        assert(b2.ship.unwrap() == Ship::Submarine, '(1,1) not submarine');
        assert(b3.ship.unwrap() == Ship::Submarine, '(1,2) not submarine');
    }
}
