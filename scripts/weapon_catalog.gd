extends RefCounted
## Initial weapon data only; the existing combat prototype is not rebalanced here.
const DAGGER_ID := "simple_dagger"
const UNARMED_DAMAGE := 1
const DAGGER := {"name": "Простой кинжал", "description": "Короткий стальной клинок с обмотанной кожей рукоятью. Надёжная вещь для первой вылазки.", "price": 24, "base_damage": 6}

static func base_damage(id: String) -> int:
	return DAGGER.base_damage if id == DAGGER_ID else UNARMED_DAMAGE
