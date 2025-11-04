local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local namespace_id_pool = require("tiny-glimmer.namespace_id_pool")

T["namespace_id_pool"] = MiniTest.new_set()

T["namespace_id_pool"]["get_free_ns_id returns incremental IDs"] = function()
  namespace_id_pool.reset_pool()
  local id1 = namespace_id_pool.get_free_ns_id()
  local id2 = namespace_id_pool.get_free_ns_id()
  local id3 = namespace_id_pool.get_free_ns_id()

  MiniTest.expect.equality(type(id1), "number")
  MiniTest.expect.equality(type(id2), "number")
  MiniTest.expect.equality(type(id3), "number")
  MiniTest.expect.equality(id2, id1 + 1)
  MiniTest.expect.equality(id3, id2 + 1)

  namespace_id_pool.release_ns_id(id1)
  namespace_id_pool.release_ns_id(id2)
  namespace_id_pool.release_ns_id(id3)
end

T["namespace_id_pool"]["release_ns_id returns true for used ID"] = function()
  namespace_id_pool.reset_pool()
  local id = namespace_id_pool.get_free_ns_id()
  local released = namespace_id_pool.release_ns_id(id)

  MiniTest.expect.equality(released, true)
end

T["namespace_id_pool"]["release_ns_id returns false for already released ID"] = function()
  namespace_id_pool.reset_pool()
  local id = namespace_id_pool.get_free_ns_id()
  namespace_id_pool.release_ns_id(id)
  local released_again = namespace_id_pool.release_ns_id(id)

  MiniTest.expect.equality(released_again, false)
end

T["namespace_id_pool"]["reuses released IDs"] = function()
  namespace_id_pool.reset_pool()
  local id1 = namespace_id_pool.get_free_ns_id()
  local id2 = namespace_id_pool.get_free_ns_id()

  namespace_id_pool.release_ns_id(id1)
  namespace_id_pool.release_ns_id(id2)

  local reused1 = namespace_id_pool.get_free_ns_id()
  local reused2 = namespace_id_pool.get_free_ns_id()

  MiniTest.expect.equality(reused1, id2)
  MiniTest.expect.equality(reused2, id1)

  namespace_id_pool.release_ns_id(reused1)
  namespace_id_pool.release_ns_id(reused2)
end

T["namespace_id_pool"]["reserve_ns_ids reserves multiple IDs"] = function()
  namespace_id_pool.reset_pool()
  local ids = namespace_id_pool.reserve_ns_ids(5)

  MiniTest.expect.equality(type(ids), "table")
  MiniTest.expect.equality(#ids, 5)

  for i = 1, 5 do
    MiniTest.expect.equality(type(ids[i]), "number")
  end

  for i = 2, 5 do
    MiniTest.expect.equality(ids[i], ids[i - 1] + 1)
  end

  namespace_id_pool.release_ns_ids(ids)
end

T["namespace_id_pool"]["release_ns_ids releases multiple IDs"] = function()
  namespace_id_pool.reset_pool()
  local ids = namespace_id_pool.reserve_ns_ids(3)
  namespace_id_pool.release_ns_ids(ids)

  local stats = namespace_id_pool.get_pool_stats()
  MiniTest.expect.equality(stats.free_count >= 3, true)
end

T["namespace_id_pool"]["get_pool_stats returns valid statistics"] = function()
  namespace_id_pool.reset_pool()
  local initial_stats = namespace_id_pool.get_pool_stats()

  local id1 = namespace_id_pool.get_free_ns_id()
  local id2 = namespace_id_pool.get_free_ns_id()

  local stats_after_alloc = namespace_id_pool.get_pool_stats()
  MiniTest.expect.equality(stats_after_alloc.used_count, initial_stats.used_count + 2)

  namespace_id_pool.release_ns_id(id1)

  local stats_after_release = namespace_id_pool.get_pool_stats()
  MiniTest.expect.equality(stats_after_release.used_count, initial_stats.used_count + 1)
  MiniTest.expect.equality(stats_after_release.free_count, initial_stats.free_count + 1)

  namespace_id_pool.release_ns_id(id2)
end

T["namespace_id_pool"]["get_pool_stats has correct structure"] = function()
  namespace_id_pool.reset_pool()
  local stats = namespace_id_pool.get_pool_stats()

  MiniTest.expect.equality(type(stats), "table")
  MiniTest.expect.equality(type(stats.next_id), "number")
  MiniTest.expect.equality(type(stats.free_count), "number")
  MiniTest.expect.equality(type(stats.used_count), "number")
  MiniTest.expect.equality(stats.next_id > 0, true)
  MiniTest.expect.equality(stats.free_count >= 0, true)
  MiniTest.expect.equality(stats.used_count >= 0, true)
end

return T
