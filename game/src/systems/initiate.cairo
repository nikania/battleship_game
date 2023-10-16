#[system]
mod initiate_system {
    use dojo::world::Context;
    use starknet::ContractAddress;
    use debug::PrintTrait;

    use battleship_game::components::common::{Game, GameTurn, Team, GameStatus, Square};

    fn execute(ctx: Context, blue: ContractAddress, red: ContractAddress) {
        let game_id = pedersen::pedersen(blue.into(), red.into());

        set!(
            ctx.world,
            Game { game_id, winner: Option::None, status: GameStatus::Preparation, blue, red }
        );

        set!(ctx.world, GameTurn { game_id, attacker: Team::Blue });

        let mut y: u8 = 0;
        //fill battlefield with empty squares 10x10
        loop {
            if y > 9 {
                break;
            }
            set!(
                ctx.world,
                (
                    Square { game_id, x: 0, y, ship: Option::None },
                    Square { game_id, x: 1, y, ship: Option::None },
                    Square { game_id, x: 2, y, ship: Option::None },
                    Square { game_id, x: 3, y, ship: Option::None },
                    Square { game_id, x: 4, y, ship: Option::None },
                    Square { game_id, x: 5, y, ship: Option::None },
                    Square { game_id, x: 6, y, ship: Option::None },
                    Square { game_id, x: 7, y, ship: Option::None },
                    Square { game_id, x: 8, y, ship: Option::None },
                    Square { game_id, x: 9, y, ship: Option::None },
                )
            );
            y += 1;
        };
    }
}

#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::ContractAddress;
    use dojo::test_utils::spawn_test_world;
    use battleship_game::components::common::{
        Game, game, GameTurn, game_turn, Square, square, GameStatus, Team
    };

    use battleship_game::systems::initiate_system;
    use array::ArrayTrait;
    use core::traits::Into;
    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};
    use core::array::SpanTrait;

    #[test]
    #[available_gas(200000000000000000)]
    fn create_game() {
        let first = starknet::contract_address_const::<0x01>();
        let second = starknet::contract_address_const::<0x02>();

        // components
        let mut components = array::ArrayTrait::new();
        components.append(game::TEST_CLASS_HASH);
        components.append(game_turn::TEST_CLASS_HASH);
        components.append(square::TEST_CLASS_HASH);

        //systems
        let mut systems = array::ArrayTrait::new();
        systems.append(initiate_system::TEST_CLASS_HASH);
        let world = spawn_test_world(components, systems);

        let mut calldata = array::ArrayTrait::<core::felt252>::new();
        calldata.append(first.into());
        calldata.append(second.into());
        world.execute('initiate_system'.into(), calldata);

        let game_id = pedersen::pedersen(first.into(), second.into());

        let game: Game = get!(world, (game_id), (Game));
        assert(game.status == GameStatus::Preparation, 'status should be prep');
        assert(game.winner == Option::None, 'should be no winner');
        assert(game.blue == first, 'should be first');
        assert(game.red == second, 'should be second');

        let game_turn = get!(world, (game_id), (GameTurn));
        assert(game_turn.attacker == Team::Blue, 'Blue player first turn');
    }
}
