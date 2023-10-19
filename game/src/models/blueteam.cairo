use array::ArrayTrait;
use core::debug::PrintTrait;
use starknet::ContractAddress;
use dojo::database::schema::{
    Enum, Member, Ty, Struct, SchemaIntrospection, serialize_member, serialize_member_type
};

#[derive(Model, Drop, Serde, Copy, Print)]
struct BlueFleet {
    #[key]
    game_id: felt252,
    carrier: u8,
    battleship: u8,
    submarine: u8,
    boat: u8,
}

use battleship_game::models::common::{Shot, ShotPrintTrait, Square, Ship, ShipPrintTrait};

#[derive(Model, Drop, Serde, Copy, Print)]
struct BlueGrid {
    #[key]
    square: Square,
    ship: Ship,
}

#[derive(Model, Drop, Serde, Copy, Print)]
struct BlueOpponentGrid {
    #[key]
    square: Square,
    shot: Shot
}

#[derive(Model, Drop, Serde, Copy, Print)]
struct BlueReady {
    #[key]
    game_id: felt252,
    ready: bool,
}

