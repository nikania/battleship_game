use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, ClassHash};

// define the interface
#[starknet::interface]
trait IActions<TContractState> {
    fn attack(self: @TContractState, game_id: felt252, coord: (u8, u8));
}

#[dojo::contract]
mod actions {
    use starknet::{ContractAddress, get_caller_address};
    use core::debug::PrintTrait;
    use core::traits::Into;

    use super::IActions;

    use battleship_game::models::common::{Square, Shot, Ship, Game, GameTurn, Team, GameStatus};
    use battleship_game::models::blueteam::{BlueGrid, BlueOpponentGrid};
    use battleship_game::models::redteam::{RedGrid, RedOpponentGrid};

    // declaring custom event struct
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Hit: Hit,
        Missed: Missed,
        Sinked: Sinked,
        GameEnd: GameEnd,
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
        square: Square,
        ship: Ship
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct GameEnd {
        game: Game,
    }

    // impl: implement functions specified in trait
    #[external(v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn attack(self: @ContractState, game_id: felt252, coord: (u8, u8)) {
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            let mut game: Game = get!(world, (game_id), (Game));

            // assert turn is correct
            let game_turn: GameTurn = get!(world, (game_id), (GameTurn));
            assert(game.status == GameStatus::Battle, 'game not ready');
            match game_turn.attacker {
                Team::None => assert(false, 'wrong turn'),
                Team::Blue => assert(player == game.blue, 'not your turn'),
                Team::Red => assert(player == game.red, 'not your turn')
            }

            check_coord_correct(coord);

            // attack: check opponent grid, then edit it and player's opponent grid
            let (x, y) = coord;
            let square = Square { game_id, x, y };
            match game_turn.attacker {
                Team::None => assert(false, 'wrong turn'),
                Team::Blue => {
                    let red_grid: RedGrid = get!(world, (square), (RedGrid));
                    match red_grid.ship {
                        Ship::None => {
                            set!(world, (BlueOpponentGrid { square, shot: Shot::Missed }));
                            emit!(world, Missed { player, square });
                        },
                        Ship::Carrier => {
                            if ship_sunk(world, square, 4, Team::Blue) {
                                emit!(world, Sinked { player, square, ship: red_grid.ship });
                                game.status = GameStatus::Final;
                                game.winner = Team::Blue;
                                emit!(world, GameEnd { game });
                                return;
                            } else {
                                emit!(world, Hit { player, square });
                            }
                        },
                        Ship::Battleship => { //todo
                        }, //1x3
                        Ship::Submarine => { //todo
                        }, //1x2
                        Ship::PatrolBoat => { //todo
                        }, //1x1
                    }
                },
                Team::Red => { //todo
                },
            }

            // change turn
            match game_turn.attacker {
                Team::None => assert(false, 'wrong turn'),
                Team::Blue => {
                    set!(world, (GameTurn { game_id, attacker: Team::Red }));
                },
                Team::Red => {
                    set!(world, (GameTurn { game_id, attacker: Team::Blue }));
                },
            }
        }
    }

    fn ship_sunk(world: IWorldDispatcher, square: Square, ship_size: u8, team: Team) -> bool {
        match team {
            Team::None => assert(false, 'wrong sunk check'),
            Team::Blue => {
                // todo: check if all squares of ship are hit
                let red_grid: RedGrid = get!(world, (square), (RedGrid));
            },
            Team::Red => {},
        }
        false
    }

    fn check_coord_correct(coord: (u8, u8)) {
        let (x, y) = coord;
        assert(x < 5, 'x coord out of range');
        assert(y < 5, 'y coord out of range');
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
    use battleship_game::models::blueteam::{BlueGrid};

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

        actions_system.attack(id, (0, 0));
    }
}
