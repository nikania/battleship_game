use starknet::ContractAddress;
use dojo::database::storage::StorageSize;
use debug::PrintTrait;

/// Coordinates of square of battlefield
#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct Square {
    #[key]
    game_id: felt252,
    #[key]
    x: u8, // 1 to 15, should be less than 16
    #[key]
    y: u8,
    ship: Option<Ship>
}

#[derive(Component, SerdeLen, Drop, Serde, Copy)]
enum Ship {
    Carrier, //1x4
    Battleship, //1x3
    Submarine, //1x2
    PatrolBoat //1x1
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
    winner: Option<Player>,
    status: GameStatus,
    first: ContractAddress,
    second: ContractAddress
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
    attacker: Player,
}

#[derive(Component, SerdeLen, Drop, Serde, Copy, PartialEq)]
enum Player {
    First,
    Second
}

impl PlayersStorageSizeTrait of StorageSize<Player> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        2
    }
}

impl OptionPlayersStorageSizeTrait of StorageSize<Option<Player>> {
    fn unpacked_size() -> usize {
        2
    }
    fn packed_size() -> usize {
        2
    }
}

impl PlayersPrintTrait of PrintTrait<Player> {
    fn print(self: Player) {
        match self {
            Player::First => {
                'First player'.print();
            },
            Player::Second => {
                'Second player'.print();
            },
        }
    }
}

impl OptionPlayersPrintTrait of PrintTrait<Option<Player>> {
    fn print(self: Option<Player>) {
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
