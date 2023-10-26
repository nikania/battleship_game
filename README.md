# battleship_game
Battleship game with [Dojo engine](https://github.com/dojoengine/dojo)

"battleship" game (where 2 people make their secret battle maps and fight each other, revealing their maps step by step [wiki](https://en.wikipedia.org/wiki/Battleship_(game)) ) - with [Dojo engine](https://www.dojoengine.org/en/) - because this game definitely needs proofs.

# The first iteration with simpler map and rules.
Map 4x4.
Each player can place 1 ship of choice on their map.

# how to start
Terminal 1 - Katana:
```cd game && katana --disable-fee```
Terminal 2 - Contracts:
```cd game && sozo build && sozo migrate```

// Basic Auth - This will allow burner Accounts to interact with the contracts
sh ./dojo-starter/scripts/default_auth.sh


Terminal 4 - Torii:
Uncomment the 'world_address' parameter in dojo-starter/Scarb.toml then:

```cd game && torii --world <WORLD_ADDRESS>```

