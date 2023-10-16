#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct BlueFleet {
    #[key]
    game_id: felt252,
    carrier: u8,
    battleship: u8,
    submarine: u8,
    boat: u8,
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
