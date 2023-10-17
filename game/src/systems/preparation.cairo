#[system]
mod preparation_system {
    use core::option::OptionTrait;
    use dojo::world::Context;
    use starknet::ContractAddress;

    use battleship_game::components::common::{
        Game, GameTurn, Team, GameStatus, Ship, Square, TeamIntoFelt
    };
    use battleship_game::components::blueteam::{BlueFleet, BlueGrid};

    fn execute(
        ctx: Context,
        game_id: felt252,
        team: Team,
        addr: ContractAddress,
        ship: Ship,
        init_coord: (u8, u8),
        fin_coord: (u8, u8),
    ) {
        let game: Game = get!(ctx.world, (game_id), (Game));
        initial_checks(@team, @game, @addr);

        let mut coord = check_coordinates(ship, init_coord, fin_coord);

        match team {
            Team::Blue => {
                check_unoccupied(Team::Blue, @coord);
                loop {
                    let opt_coord = coord.pop_front();
                    if opt_coord == Option::None {
                        break;
                    }
                    let (x, y) = opt_coord.unwrap();
                    set!(
                        ctx.world,
                        (BlueGrid { square: Square { game_id, x, y }, ship: Option::Some(ship) })
                    );
                }
            },
            Team::Red => {
                check_unoccupied(Team::Red, @coord);
            }
        }
    }

    fn initial_checks(team: @Team, game: @Game, addr: @ContractAddress) {
        match team {
            Team::Blue => {
                assert(game.blue == addr, 'wrong caller');
            // let mut fleet = get!(ctx.world, (game.game_id), (BlueFleet));
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
        }
    }

    use array::ArrayTrait;
    fn check_coordinates(ship: Ship, init_coord: (u8, u8), fin_coord: (u8, u8)) -> Array<(u8, u8)> {
        let (x1, y1) = init_coord;
        assert(x1 >= 0 && x1 < 10, 'init x coord wrong');
        assert(y1 >= 0 && y1 < 10, 'init x coord wrong');
        let (x2, y2) = fin_coord;
        assert(x2 >= 0 && x2 < 10, 'x coord wrong');
        assert(y2 >= 0 && y2 < 10, 'x coord wrong');

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
    fn ship_placement_boat_correct() {
        let world = init();
        let first = first();
        let second = second();
        let id = game_id();

        let mut calldata = array![
            id, Team::Blue.into(), first.into(), Ship::PatrolBoat.into(), 1, 1, 1, 1
        ];
        world.execute('preparation_system'.into(), calldata);

        let b2: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 1 }), (BlueGrid));
        let b3: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 2 }), (BlueGrid));
        assert(b2.ship.unwrap() == Ship::PatrolBoat, '(1,1) not boat');
        assert(b3.ship == Option::None, '(1,2) not empty');
    }

    #[test]
    #[available_gas(20000000000000000)]
    fn ship_placement_submarine_correct() {
        let world = init();
        let first = first();
        let second = second();
        let id = game_id();

        let mut calldata = array![
            id, Team::Blue.into(), first.into(), Ship::Submarine.into(), 1, 1, 0, 1
        ];
        world.execute('preparation_system'.into(), calldata);

        let a2: BlueGrid = get!(world, (Square { game_id: id, x: 0, y: 1 }), (BlueGrid));
        let b2: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 1 }), (BlueGrid));
        let b3: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 2 }), (BlueGrid));
        assert(a2.ship.unwrap() == Ship::Submarine, '(0,1) not submarine');
        assert(b2.ship.unwrap() == Ship::Submarine, '(1,1) not submarine');
        assert(b3.ship == Option::None, '(1,2) not empty');
    }

    #[test]
    #[available_gas(20000000000000000)]
    fn ship_placement_battleship_correct() {
        let world = init();
        let first = first();
        let second = second();
        let id = game_id();

        let mut calldata = array![
            id, Team::Blue.into(), first.into(), Ship::Battleship.into(), 2, 1, 0, 1
        ];
        world.execute('preparation_system'.into(), calldata);

        let a2: BlueGrid = get!(world, (Square { game_id: id, x: 0, y: 1 }), (BlueGrid));
        let b2: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 1 }), (BlueGrid));
        let c2: BlueGrid = get!(world, (Square { game_id: id, x: 2, y: 1 }), (BlueGrid));
        let b3: BlueGrid = get!(world, (Square { game_id: id, x: 1, y: 2 }), (BlueGrid));
        assert(a2.ship.unwrap() == Ship::Battleship, '(0,1) not battleship');
        assert(b2.ship.unwrap() == Ship::Battleship, '(1,1) not battleship');
        assert(c2.ship.unwrap() == Ship::Battleship, '(1,1) not battleship');
        assert(b3.ship == Option::None, '(1,2) not empty');
    }
}
