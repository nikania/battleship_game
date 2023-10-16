#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct BlueFleet {
    #[key]
    game_id: felt252,
    Carrier: u8,
    Battleship: u8,
    Submarine: u8,
    PatrolBoat: u8,
}

use battleship_game::components::common::{
    Shot, ShotPrintTrait, OptionShotPrintTrait, ShotStorageSizeTrait, OptionShotStorageSizeTrait,
    Square, Ship, ShipPrintTrait, ShipStorageSizeTrait, OptionShipPrintTrait,
    OptionShipStorageSizeTrait
};
#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct BlueGrid {
    #[key]
    square: Square,
    ship: Option<Ship>
}

#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct BlueOpponentGrid {
    #[key]
    square: Square,
    shot: Shot
}
