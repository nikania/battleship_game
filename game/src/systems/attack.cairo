#[system]
mod attack_system {
    use dojo::world::Context;
    use starknet::ContractAddress;

    use battleship_game::components::common::{Square, Ship};

    fn execute(ctx: Context, player: ContractAddress, square: Square) {}
}
