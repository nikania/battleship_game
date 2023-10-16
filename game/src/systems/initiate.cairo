#[system]
mod initiate_system {
    use dojo::world::Context;
    use starknet::ContractAddress;
    use debug::PrintTrait;

    use battleship_game::components::common::{Game, GameTurn, Team, GameStatus, Square, Shot};
    use battleship_game::components::blueteam::{BlueGrid, BlueOpponentGrid, BlueFleet};

    fn execute(ctx: Context, blue: ContractAddress, red: ContractAddress) {
        let game_id = pedersen::pedersen(blue.into(), red.into());

        set!(
            ctx.world,
            Game { game_id, winner: Option::None, status: GameStatus::Preparation, blue, red }
        );

        set!(ctx.world, GameTurn { game_id, attacker: Team::Blue });

        // TODO prepare empty waters
        let mut y: u8 = 0;
        loop {
            if y > 9 {
                break;
            }
            set!(
                ctx.world,
                (
                    BlueGrid { square: Square { game_id, x: 0, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 1, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 2, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 3, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 4, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 5, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 6, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 7, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 8, y }, ship: Option::None },
                    BlueGrid { square: Square { game_id, x: 9, y }, ship: Option::None },
                )
            );
            y += 1;
        };
        // TODO prepare unnown opponent waters
        let mut y: u8 = 0;
        loop {
            if y > 9 {
                break;
            }
            set!(
                ctx.world,
                (
                    BlueOpponentGrid { square: Square { game_id, x: 0, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 1, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 2, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 3, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 4, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 5, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 6, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 7, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 8, y }, shot: Shot::Unknown },
                    BlueOpponentGrid { square: Square { game_id, x: 9, y }, shot: Shot::Unknown }
                )
            );
            y += 1;
        };

        // todo set fleets
        set!(ctx.world, (BlueFleet { game_id, carrier: 1, battleship: 2, submarine: 3, boat: 4 }));
    }
}

#[cfg(test)]
mod tests {
    use core::debug::PrintTrait;
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use core::traits::Into;
    use core::array::SpanTrait;

    use dojo::test_utils::spawn_test_world;
    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};

    use battleship_game::components::common::{
        Game, game, GameTurn, game_turn, Square, GameStatus, Team, Shot
    };
    use battleship_game::systems::initiate_system;
    use battleship_game::components::blueteam::{BlueGrid, BlueOpponentGrid, BlueFleet};

    #[test]
    #[available_gas(200000000000000000)]
    fn create_game_correct() {
        let first = starknet::contract_address_const::<0x01>();
        let second = starknet::contract_address_const::<0x02>();

        // components
        let mut components = array::ArrayTrait::new();
        components.append(game::TEST_CLASS_HASH);
        components.append(game_turn::TEST_CLASS_HASH);

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

        let bluegrid78 = get!(world, (Square { game_id, x: 7, y: 8 }), (BlueGrid));
        assert(bluegrid78.ship == Option::None, 'square not empty');

        let blueoppgrid49 = get!(world, (Square { game_id, x: 7, y: 8 }), (BlueOpponentGrid));
        assert(blueoppgrid49.shot == Shot::Unknown, 'square not unnknown');

        let bluefleet: BlueFleet = get!(world, (game_id), (BlueFleet));
        assert(bluefleet.carrier == 1, 'carrier wrong count');
        assert(bluefleet.battleship == 2, 'battleship wrong count');
        assert(bluefleet.submarine == 3, 'submarine wrong count');
        assert(bluefleet.boat == 4, 'boat wrong count');
    }
}
