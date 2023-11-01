use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, ClassHash};

// define the interface
#[starknet::interface]
trait IStart<TContractState> {
    /// There are 2 players in the game. Each Player has 2 grids: their own and unknown opponent. Starting game creates 2 empty grids for each player.
    fn start_game(self: @TContractState, player: ContractAddress, opponent: ContractAddress);
}

#[dojo::contract]
mod initiate {
    use starknet::{ContractAddress, get_caller_address};
    use core::debug::PrintTrait;
    use core::traits::Into;

    use super::IStart;

    use battleship_game::models::common::{Game, GameTurn, Team, GameStatus, Square, Shot, Ship};
    use battleship_game::models::blueteam::{BlueGrid, BlueOpponentGrid, BlueReady};
    use battleship_game::models::redteam::{RedGrid, RedOpponentGrid, RedReady};

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        GameCreated: GameCreated,
    }

    #[derive(Drop, starknet::Event)]
    struct GameCreated {
        game: Game,
    }

    // impl: implement functions specified in trait
    #[external(v0)]
    impl StartImpl of IStart<ContractState> {
        fn start_game(self: @ContractState, player: ContractAddress, opponent: ContractAddress) {
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();

            // Get the address of the current caller, possibly the player's address.
            let caller = get_caller_address();
            assert(caller == player, 'caller not player');

            let game_id = pedersen::pedersen(player.into(), opponent.into());
            let game = Game {
                game_id,
                winner: Team::None,
                status: GameStatus::Preparation,
                blue: player,
                red: opponent
            };

            set!(world, (game));

            set!(world, GameTurn { game_id, attacker: Team::Blue });

            // prepare own waters
            let mut y: u8 = 0;
            loop {
                if y > 3 {
                    break;
                }
                set!(
                    world,
                    (
                        BlueGrid { square: Square { game_id, x: 0, y }, ship: Ship::None },
                        BlueGrid { square: Square { game_id, x: 1, y }, ship: Ship::None },
                        BlueGrid { square: Square { game_id, x: 2, y }, ship: Ship::None },
                        BlueGrid { square: Square { game_id, x: 3, y }, ship: Ship::None },
                        RedGrid { square: Square { game_id, x: 0, y }, ship: Ship::None },
                        RedGrid { square: Square { game_id, x: 1, y }, ship: Ship::None },
                        RedGrid { square: Square { game_id, x: 2, y }, ship: Ship::None },
                        RedGrid { square: Square { game_id, x: 3, y }, ship: Ship::None },
                    )
                );
                y += 1;
            };
            // prepare unnown opponent waters
            let mut y: u8 = 0;
            loop {
                if y > 3 {
                    break;
                }
                set!(
                    world,
                    (
                        BlueOpponentGrid {
                            square: Square { game_id, x: 0, y }, shot: Shot::Unknown
                        },
                        BlueOpponentGrid {
                            square: Square { game_id, x: 1, y }, shot: Shot::Unknown
                        },
                        BlueOpponentGrid {
                            square: Square { game_id, x: 2, y }, shot: Shot::Unknown
                        },
                        BlueOpponentGrid {
                            square: Square { game_id, x: 3, y }, shot: Shot::Unknown
                        },
                        RedOpponentGrid {
                            square: Square { game_id, x: 0, y }, shot: Shot::Unknown
                        },
                        RedOpponentGrid {
                            square: Square { game_id, x: 1, y }, shot: Shot::Unknown
                        },
                        RedOpponentGrid {
                            square: Square { game_id, x: 2, y }, shot: Shot::Unknown
                        },
                        RedOpponentGrid {
                            square: Square { game_id, x: 3, y }, shot: Shot::Unknown
                        },
                    )
                );
                y += 1;
            };

            // todo set fleets
            // set!(world, (BlueFleet { game_id, carrier: 1, battleship: 2, submarine: 3, boat: 4 }));

            // not ready for battle
            set!(world, (BlueReady { game_id, ready: false }));
            set!(world, (RedReady { game_id, ready: false }));

            emit!(world, GameCreated { game });
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
    use starknet::testing::set_contract_address;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import actions
    use super::{initiate, IStartDispatcher, IStartDispatcherTrait};

    use battleship_game::models::common::{
        Game, game, GameTurn, game_turn, Square, GameStatus, Team, Shot, Ship
    };
    use battleship_game::models::blueteam::{BlueGrid, BlueOpponentGrid, BlueReady};

    #[test]
    #[available_gas(200000000000000000)]
    fn create_game_correct() {
        let first = starknet::contract_address_const::<0x01>();
        let second = starknet::contract_address_const::<0x02>();

        // components
        let mut models = array::ArrayTrait::new();
        models.append(game::TEST_CLASS_HASH);
        models.append(game_turn::TEST_CLASS_HASH);

        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', initiate::TEST_CLASS_HASH.try_into().unwrap());
        let start_system = IStartDispatcher { contract_address };
        // to call contract from first address
        set_contract_address(first);
        start_system.start_game(first, second);

        let game_id = pedersen::pedersen(first.into(), second.into());

        let game: Game = get!(world, (game_id), (Game));
        // game.print();
        assert(game.status == GameStatus::Preparation, 'status should be prep');
        assert(game.winner == Team::None, 'should be no winner');
        assert(game.blue == first, 'should be first');
        assert(game.red == second, 'should be second');

        let game_turn = get!(world, (game_id), (GameTurn));
        assert(game_turn.attacker == Team::Blue, 'Blue player first turn');

        let bluegrid78 = get!(world, (Square { game_id, x: 3, y: 0 }), (BlueGrid));
        assert(bluegrid78.ship == Ship::None, 'square not empty');

        let blueoppgrid49 = get!(world, (Square { game_id, x: 3, y: 3 }), (BlueOpponentGrid));
        assert(blueoppgrid49.shot == Shot::Unknown, 'square not unnknown');

        let blueready: BlueReady = get!(world, (game_id), (BlueReady));
        assert(!blueready.ready, 'should be not ready');
    // let bluefleet: BlueFleet = get!(world, (game_id), (BlueFleet));
    // assert(bluefleet.carrier == 1, 'carrier wrong count');
    // assert(bluefleet.battleship == 2, 'battleship wrong count');
    // assert(bluefleet.submarine == 3, 'submarine wrong count');
    // assert(bluefleet.boat == 4, 'boat wrong count');
    }

    #[test]
    #[available_gas(2000000000000)]
    fn test_caller() {
        let first = starknet::contract_address_const::<0x01>();
        let second = starknet::contract_address_const::<0x02>();

        // components
        let mut models = array::ArrayTrait::new();
        models.append(game::TEST_CLASS_HASH);
        models.append(game_turn::TEST_CLASS_HASH);

        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', initiate::TEST_CLASS_HASH.try_into().unwrap());
        let start_system = IStartDispatcher { contract_address };
        // to call contract from first address
        set_contract_address(first);

        start_system.start_game(first, second);
    }
}

