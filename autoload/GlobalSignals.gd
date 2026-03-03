extends Node

## Emitted by the active game scene when dungeon gameplay begins.
## ExplorationHUD listens to this to show itself.
@warning_ignore("unused_signal")
signal gameplay_started()

## Emitted when gameplay ends (e.g. player dies, run ends, meta screen opens).
## ExplorationHUD listens to this to hide itself.
@warning_ignore("unused_signal")
signal gameplay_ended()

## Emitted by Main.gd whenever the HubRoom is instantiated and the player is in the hub.
## Fires at game start and each time the player returns from a run.
@warning_ignore("unused_signal")
signal hub_entered()
