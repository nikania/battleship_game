#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

# sozo auth writer Moves <ACTIONS_ADDRESS> --world <WORLD_ADDRESS>
export WORLD_ADDRESS="0x2612a9e9d2ef04806688e59186aa2e050b254004118f11baa37e4fb372e2d08";
export INIT_ADDRESS="0x65b2bb78ad53bf0469fbb8e6372b403baa328a1c83fcbd3c172efcece332cb7";

# enable system -> component authorizations
COMPONENTS=("Game" "GameTurn" )

for component in ${COMPONENTS[@]}; do
    sozo auth writer $component $INIT_ADDRESS --world $WORLD_ADDRESS
done

for component in ${COMPONENTS[@]}; do
    sozo auth writer $component $INIT_ADDRESS --world $WORLD_ADDRESS
done

echo "Default authorizations have been successfully set."