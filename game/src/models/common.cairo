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

#[derive(Model, Drop, Serde, Copy, PartialEq, Introspect, Print)]
enum Ship {
    None, // no ship
    Carrier, //1x4
    Battleship, //1x3
    Submarine, //1x2
    PatrolBoat, //1x1
}

impl ShipIntoFelf of Into<Ship, felt252> {
    fn into(self: Ship) -> felt252 {
        match self {
            Ship::None => 0,
            Ship::Carrier => 1,
            Ship::Battleship => 2,
            Ship::Submarine => 3,
            Ship::PatrolBoat => 4,
        }
    }
}

impl ShipPrintTrait of PrintTrait<Ship> {
    fn print(self: Ship) {
        match self {
            Ship::None => 'No ship'.print(),
            Ship::Carrier => 'Carrier'.print(),
            Ship::Battleship => 'Battleship'.print(),
            Ship::Submarine => 'Submarine'.print(),
            Ship::PatrolBoat => 'PatrolBoat'.print(),
        }
    }
}


#[derive(Model, Drop, Serde, Copy, Print)]
struct Game {
    #[key]
    game_id: felt252,
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
    None,
    Blue,
    Red,
}

impl TeamIntoFelt of Into<Team, felt252> {
    fn into(self: Team) -> felt252 {
        match self {
            Team::None => {
                0
            },
            Team::Blue => {
                1
            },
            Team::Red => {
                2
            },
        }
    }
}

impl PlayersPrintTrait of PrintTrait<Team> {
    fn print(self: Team) {
        match self {
            Team::None => {
                'None player'.print();
            },
            Team::Blue => {
                'Blue player'.print();
            },
            Team::Red => {
                'Red player'.print();
            },
        }
    }
}

