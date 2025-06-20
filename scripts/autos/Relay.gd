extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal challenged(initials : String)
signal challenge_ended()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func challenge(initials : String) -> void:
	challenged.emit(initials)

func announce_challenge_ended() -> void:
	challenge_ended.emit()
