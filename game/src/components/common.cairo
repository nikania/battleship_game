use starknet::ContractAddress;
use dojo::database::storage::StorageSize;
use debug::PrintTrait;

/// Coordinates of square of battlefield
#[derive(SerdeLen, Drop, Serde, Copy)]
struct Square {
    game_id: felt252,
    x: u8, // 1 to 15, should be less than 16
    y: u8,
}

impl SquarePrintTrait of PrintTrait<Square> {
    fn print(self: Square) {
        'Square'.print();
        self.x.print();
        self.y.print();
    }
}

#[derive(Component, SerdeLen, Drop, Serde, Copy)]
enum Shot {
    Unnkown,
    Missed,
    Hit
}

impl ShotPrintTrait of PrintTrait<Shot> {
    fn print(self: Shot) {
        match self {
            Shot::Unnkown => 'Unnkown'.print(),
            Shot::Missed => 'Missed'.print(),
            Shot::Hit => 'Hit'.print(),
        }
    }
}

impl OptionShotPrintTrait of PrintTrait<Option<Shot>> {
    fn print(self: Option<Shot>) {
        match self {
            Option::Some(s) => s.print(),
            Option::None => 'None'.print()
        }
    }
}

impl ShotStorageSizeTrait of StorageSize<Shot> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        8
    }
}

impl OptionShotStorageSizeTrait of StorageSize<Option<Shot>> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        8
    }
}

#[derive(Component, SerdeLen, Drop, Serde, Copy, PartialEq)]
enum Ship {
    Carrier, //1x4
    Battleship, //1x3
    Submarine, //1x2
    PatrolBoat //1x1
}

impl ShipIntoFelf of Into<Ship, felt252> {
    fn into(self: Ship) -> felt252 {
        match self {
            Ship::Carrier => 0,
            Ship::Battleship => 1,
            Ship::Submarine => 2,
            Ship::PatrolBoat => 3
        }
    }
}

impl ShipPrintTrait of PrintTrait<Ship> {
    fn print(self: Ship) {
        match self {
            Ship::Carrier => 'Carrier'.print(),
            Ship::Battleship => 'Battleship'.print(),
            Ship::Submarine => 'Submarine'.print(),
            Ship::PatrolBoat => 'PatrolBoat'.print()
        }
    }
}

impl OptionShipPrintTrait of PrintTrait<Option<Ship>> {
    fn print(self: Option<Ship>) {
        match self {
            Option::Some(ship) => ship.print(),
            Option::None => 'None'.print()
        }
    }
}

impl ShipStorageSizeTrait of StorageSize<Ship> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        8
    }
}

impl OptionShipStorageSizeTrait of StorageSize<Option<Ship>> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        8
    }
}

#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct Game {
    #[key]
    game_id: felt252,
    winner: Option<Team>,
    status: GameStatus,
    blue: ContractAddress,
    red: ContractAddress
}

#[derive(Component, SerdeLen, Drop, Serde, Copy, PartialEq)]
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

impl GameStatusStorageSizeTrait of StorageSize<GameStatus> {
    fn unpacked_size() -> usize {
        32
    }
    fn packed_size() -> usize {
        32
    }
}

#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct GameTurn {
    #[key]
    game_id: felt252,
    attacker: Team,
}

#[derive(Component, SerdeLen, Drop, Serde, Copy, PartialEq)]
enum Team {
    Blue,
    Red
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
        }
    }
}

impl PlayersStorageSizeTrait of StorageSize<Team> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        2
    }
}

impl OptionPlayersStorageSizeTrait of StorageSize<Option<Team>> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        2
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
        }
    }
}

impl OptionPlayersPrintTrait of PrintTrait<Option<Team>> {
    fn print(self: Option<Team>) {
        match self {
            Option::Some(p) => {
                p.print()
            },
            Option::None => {
                'None'.print()
            },
        }
    }
}
