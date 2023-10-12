/// Coordinates of square of battlefield
#[derive(Component, SerdeLen, Drop, Serde, Copy)]
struct Square {
    #[key]
    game_id: felt252,
    x: u8, // 1 to 15, should be less than 16
    y: u8,
}
