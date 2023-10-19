use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, ClassHash};

use battleship_game::models::common::{Team, Ship};

// define the interface
#[starknet::interface]
trait IPrepare<TContractState> {
    fn place_ship(
        self: @TContractState,
        game_id: felt252,
        team: Team,
        addr: ContractAddress,
        ship: Ship,
        init_coord: (u8, u8),
        fin_coord: (u8, u8),
    );
}


#[dojo::contract]
mod preparation {
    use starknet::{ContractAddress, get_caller_address};
    use core::debug::PrintTrait;

    use super::IPrepare;

    use battleship_game::models::common::{
        Game, GameTurn, Team, GameStatus, Ship, Square, TeamIntoFelt
    };
    use battleship_game::models::blueteam::{BlueFleet, BlueGrid, BlueReady};

    // impl: implement functions specified in trait
    #[external(v0)]
    impl ActionsImpl of IPrepare<ContractState> {
        fn place_ship(
            self: @ContractState,
            game_id: felt252,
            team: Team,
            addr: ContractAddress,
            ship: Ship,
            init_coord: (u8, u8),
            fin_coord: (u8, u8),
        ) {
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();
            // assert(player == addr, ''); // how check this in tests

            let game: Game = get!(world, (game_id), (Game));
            initial_checks(@team, @game, @addr);

            let mut coord = check_coordinates(ship, init_coord, fin_coord);

            match team {
                Team::None => assert(false, 'should be some team'),
                Team::Blue => {
                    check_unoccupied(Team::Blue, @coord);
                    loop {
                        let opt_coord = coord.pop_front();
                        if opt_coord == Option::None {
                            break;
                        }
                        let (x, y) = opt_coord.unwrap();
                        set!(world, (BlueGrid { square: Square { game_id, x, y }, ship }));
                    };
                    set!(world, (BlueReady { game_id, ready: true }));
                },
                Team::Red => {
                    check_unoccupied(Team::Red, @coord);
                }
            };
        }
    }

    fn initial_checks(team: @Team, game: @Game, addr: @ContractAddress) {
        assert(*game.status == GameStatus::Preparation, 'Not allowed');

        match team {
            Team::None => assert(false, 'should be some team'),
            Team::Blue => {
                assert(game.blue == addr, 'wrong caller');
            // let mut fleet = get!(world, (game.game_id), (BlueFleet));
            // match ship {
            //     // todo make possible replacements
            //     Carrier => assert(fleet.carrier != 0, 'already placed'), //1x4
            //     Battleship => assert(fleet.battleship != 0, 'already placed'), //1x3
            //     Submarine => assert(fleet.submarine != 0, 'already placed'), //1x2
            //     PatrolBoat => assert(fleet.boat != 0, 'already placed')
            // }
            },
            Team::Red => {
                assert(game.red == addr, 'wrong caller');
            },
        };
    }

    use array::ArrayTrait;
    fn check_coordinates(ship: Ship, init_coord: (u8, u8), fin_coord: (u8, u8)) -> Array<(u8, u8)> {
        let (x1, y1) = init_coord;
        assert(x1 >= 0 && x1 < 4, 'init x coord wrong');
        assert(y1 >= 0 && y1 < 4, 'init x coord wrong');
        let (x2, y2) = fin_coord;
        assert(x2 >= 0 && x2 < 4, 'x coord wrong');
        assert(y2 >= 0 && y2 < 4, 'x coord wrong');

        assert(x1 == x2 || y1 == y2, 'ship is bended');
        let mut a = ArrayTrait::new();
        if x1 == x2 {
            let mut len = check_ship_len(ship, y1, y2);

            loop {
                let y = if y1 < y2 {
                    y1 + len
                } else {
                    y2 + len
                };
                a.append((x1, y));
                if len == 0 {
                    break;
                }
                len -= 1;
            };
        }
        if y1 == y2 {
            let mut len = check_ship_len(ship, x1, x2);

            loop {
                let x = if x1 < x2 {
                    x1 + len
                } else {
                    x2 + len
                };
                a.append((x, y1));
                if len == 0 {
                    break;
                }
                len -= 1;
            };
        }
        a
    }

    fn check_ship_len(ship: Ship, c1: u8, c2: u8) -> u8 {
        let len: u8 = if c1 > c2 {
            c1 - c2
        } else {
            c2 - c1
        };
        match ship {
            Ship::None => assert(false, 'should be some ship'),
            Ship::Carrier => assert(len == 3, 'incorrect size'), //1x4
            Ship::Battleship => assert(len == 2, 'incorrect size'), //1x3
            Ship::Submarine => assert(len == 1, 'incorrect size'), //1x2
            Ship::PatrolBoat => assert(len == 0, 'incorrect size') //1x1
        };
        len
    }

    fn check_unoccupied(team: Team, coord: @Array<(u8, u8)>) {
        //TODO
        assert(true, '');
    }
}
#[cfg(test)]
mod tests {
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
    use super::{preparation, IPrepareDispatcher, IPrepareDispatcherTrait};
    use battleship_game::systems::initiate::{start, IStartDispatcher, IStartDispatcherTrait};


    use battleship_game::models::common::{
        Game, game, GameTurn, game_turn, GameStatus, Team, Ship, Square, TeamIntoFelt
    };
    use battleship_game::models::blueteam::{BlueFleet, BlueGrid, BlueReady};

    fn first() -> ContractAddress {
        starknet::contract_address_const::<0x01>()
    }
    fn second() -> ContractAddress {
        starknet::contract_address_const::<0x02>()
    }
    fn game_id() -> felt252 {
        pedersen::pedersen(first().into(), second().into())
    }

    fn init() -> (IWorldDispatcher, IPrepareDispatcher) {
        let first = first();
        let second = second();

        // models
        let mut models = array::ArrayTrait::new();
        models.append(game::TEST_CLASS_HASH);
        models.append(game_turn::TEST_CLASS_HASH);

        // deploy world with models
        let world = spawn_test_world(models);

        // todo game should be created at first, how to check that
        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', start::TEST_CLASS_HASH.try_into().unwrap());
        let start_system = IStartDispatcher { contract_address };

        start_system.start_game(first, second);
        let contract_address = world
            .deploy_contract('salt', preparation::TEST_CLASS_HASH.try_into().unwrap());
        let prepare_system = IPrepareDispatcher { contract_address };

        (world, prepare_system)
    }

    #[test]
    #[available_gas(20000000000000000)]
    fn ship_placement_boat_correct() {
        let (world, prepare_system) = init();
        let first = first();
        let second = second();
        let id = game_id();

        prepare_system.place_ship(id, Team::Blue, first, Ship::PatrolBoat, (1, 1), (1, 1));

        let b2: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 1 }), (BlueGrid));
        let b3: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 2 }), (BlueGrid));
        assert(b2.ship == Ship::PatrolBoat, '(1,1) not boat');
        assert(b3.ship == Ship::None, '(1,2) not empty');

        let blueready: BlueReady = get!(world, (id), (BlueReady));
        assert(blueready.ready, 'should be ready');
    }

    #[test]
    #[available_gas(20000000000000000)]
    fn ship_placement_submarine_correct() {
        let (world, prepare_system) = init();
        let first = first();
        let second = second();
        let id = game_id();

        prepare_system.place_ship(id, Team::Blue, first, Ship::Submarine, (1, 1), (0, 1));

        let a2: BlueGrid = get!(world, (Square { game_id: id, x: 0, y: 1 }), (BlueGrid));
        let b2: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 1 }), (BlueGrid));
        let b3: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 2 }), (BlueGrid));
        assert(a2.ship == Ship::Submarine, '(0,1) not submarine');
        assert(b2.ship == Ship::Submarine, '(1,1) not submarine');
        assert(b3.ship == Ship::None, '(1,2) not empty');
    }

    #[test]
    #[available_gas(20000000000000000)]
    fn ship_placement_battleship_correct() {
        let (world, prepare_system) = init();
        let first = first();
        let second = second();
        let id = game_id();

        prepare_system.place_ship(id, Team::Blue, first, Ship::Battleship, (2, 1), (0, 1));

        let a2: BlueGrid = get!(world, (Square { game_id: id, x: 0, y: 1 }), (BlueGrid));
        let b2: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 1 }), (BlueGrid));
        let c2: BlueGrid = get!(world, (Square { game_id: id, x: 2, y: 1 }), (BlueGrid));
        let b3: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 2 }), (BlueGrid));
        assert(a2.ship == Ship::Battleship, '(0,1) not battleship');
        assert(b2.ship == Ship::Battleship, '(1,1) not battleship');
        assert(c2.ship == Ship::Battleship, '(1,1) not battleship');
        assert(b3.ship == Ship::None, '(1,2) not empty');
    }
}

