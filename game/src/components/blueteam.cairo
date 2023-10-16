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
    S, Shot, ShotPrintTrait, OptionShotPrintTrait, ShotStorageSizeTrait, OptionShotStorageSizeTrait,
    Square, Ship, ShipPrintTrait, ShipStorageSizeTrait, OptionShipPrintTrait,
    OptionShipStorageSizeTrait
};
#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct BlueGrid {
    #[key]
    square: S,
    ship: Option<Ship>
}

#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct BlueOpponentGrid {
    #[key]
    square: S,
    shot: Shot
}
