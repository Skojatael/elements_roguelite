extends GutTest

const MetaManager = preload("res://scripts/managers/MetaManager.gd")
const base_divisor = 3

func test_essence_to_shards_basic():
	var shards = MetaManager.compute_endless_shards(90, base_divisor)
	assert_eq(shards, 30, "90 essence should convert to 30 shards")

func test_essence_to_shards_rounding():
	var shards = MetaManager.compute_endless_shards(100, base_divisor)
	assert_eq(shards, 33, "Conversion should floor the result")

func test_zero_essence():
	var shards = MetaManager.compute_endless_shards(0, base_divisor)
	assert_eq(shards, 0, "0 essence should produce 0 shards")

func test_small_values():
	assert_eq(MetaManager.compute_endless_shards(1,base_divisor), 0)
	assert_eq(MetaManager.compute_endless_shards(2,base_divisor), 0)
	assert_eq(MetaManager.compute_endless_shards(3,base_divisor), 1)
