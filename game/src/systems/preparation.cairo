#[system]
mod preparation_system {
    use dojo::world::Context;
    use starknet::ContractAddress;

    use battleship_game::components::{Game, GameTurn, Player, GameStatus};

    fn execute(ctx: Context) {}
}
