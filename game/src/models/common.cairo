use array::ArrayTrait;
use core::debug::PrintTrait;
use starknet::ContractAddress;
use dojo::database::schema::{
    Enum, Member, Ty, Struct, SchemaIntrospection, serialize_member, serialize_member_type
};

/// Coordinates of square of battlefield
#[derive(Drop, Serde, Copy, Print, Introspect)]
struct Square {
    game_id: felt252,
    x: u8, // 1 to 15, should be less than 16
    y: u8,
}

#[derive(Model, Drop, Serde, Copy, PartialEq, Introspect, Print)]
enum Shot {
    Unknown,
    Missed,
    Hit
}

impl ShotPrintTrait of PrintTrait<Shot> {
    fn print(self: Shot) {
        match self {
            Shot::Unknown => 'Unknown'.print(),
            Shot::Missed => 'Missed'.print(),
            Shot::Hit => 'Hit'.print(),
        }
    }
}

// impl OptionShotPrintTrait of PrintTrait<Option<Shot>> {
//     fn print(self: Option<Shot>) {
//         match self {
//             Option::Some(s) => s.print(),
//             Option::None => 'None'.print()
//         }
//     }
// }

#[derive(Model, Drop, Serde, Copy, PartialEq, Introspect, Print)]
enum Ship {
    Carrier, //1x4
    Battleship, //1x3
    Submarine, //1x2
    PatrolBoat, //1x1
    None // no ship
}

impl ShipIntoFelf of Into<Ship, felt252> {
    fn into(self: Ship) -> felt252 {
        match self {
            Ship::Carrier => 0,
            Ship::Battleship => 1,
            Ship::Submarine => 2,
            Ship::PatrolBoat => 3,
            Ship::None => 4,
        }
    }
}

impl ShipPrintTrait of PrintTrait<Ship> {
    fn print(self: Ship) {
        match self {
            Ship::Carrier => 'Carrier'.print(),
            Ship::Battleship => 'Battleship'.print(),
            Ship::Submarine => 'Submarine'.print(),
            Ship::PatrolBoat => 'PatrolBoat'.print(),
            Ship::None => 'No ship'.print()
        }
    }
}


#[derive(Model, Drop, Serde, Copy, Print)]
struct Game {
    #[key]
    game_id: felt252,
    // winner: Option<Team>,
    winner: Team,
    status: GameStatus,
    blue: ContractAddress,
    red: ContractAddress
}

#[derive(Model, Drop, Serde, Copy, PartialEq, Introspect, Print)]
enum GameStatus {
    Preparation,
    Battle,
    Final
}

impl GameStatusPrintTrait of PrintTrait<GameStatus> {
    fn print(self: GameStatus) {
        match self {
            GameStatus::Preparation => 'Preparation'.print(),
            GameStatus::Battle => 'Battle'.print(),
            GameStatus::Final => 'Final'.print()
        }
    }
}


#[derive(Model, Drop, Serde, Copy, Print)]
struct GameTurn {
    #[key]
    game_id: felt252,
    attacker: Team,
}

#[derive(Model, Drop, Serde, Copy, PartialEq, Introspect, Print)]
enum Team {
    Blue,
    Red,
    None
}

impl TeamIntoFelt of Into<Team, felt252> {
    fn into(self: Team) -> felt252 {
        match self {
            Team::Blue => {
                0
            },
            Team::Red => {
                1
            },
            Team::None => {
                2
            }
        }
    }
}

impl PlayersPrintTrait of PrintTrait<Team> {
    fn print(self: Team) {
        match self {
            Team::Blue => {
                'Blue player'.print();
            },
            Team::Red => {
                'Red player'.print();
            },
            Team::None => {
                'None player'.print();
            },
        }
    }
}
// impl OptionPlayersPrintTrait of PrintTrait<Option<Team>> {
//     fn print(self: Option<Team>) {
//         match self {
//             Option::Some(p) => {
//                 p.print()
//             },
//             Option::None => {
//                 'None'.print()
//             },
//         }
//     }
// }

// impl OptionTeamSchemaIntrospection of SchemaIntrospection<Option<Team>> {
//     fn size() -> usize {
//         1
//     }
//     fn layout(ref layout: Array<u8>) {
//         layout.append(8);
//     }
//     fn ty() -> Ty {
//         Ty::Enum(
//             Enum {
//                 name: 'OptionTeam',
//                 attrs: array![].span(),
//                 children: array![
//                     ('Goalkeeper', serialize_member_type(@Ty::Tuple(array![].span()))),
//                     ('Defender', serialize_member_type(@Ty::Tuple(array![].span()))),
//                     ('Midfielder', serialize_member_type(@Ty::Tuple(array![].span()))),
//                     ('Attacker', serialize_member_type(@Ty::Tuple(array![].span()))),
//                 ]
//                     .span(),
//             }
//         )
//     }
// }

