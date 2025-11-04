---@class NamespacePool
---@field private next_id number The next ID to assign when no free IDs are available
---@field private free_ids table<number, number> Table of released and reusable IDs
---@field private used_ids table<number, boolean> Table of currently used IDs
---@field private last_free_index number Index of the last free ID for O(1) insertion

---@class PoolStats
---@field next_id number The next ID that would be assigned
---@field free_count number Number of free IDs available for reuse
---@field used_count number Number of IDs currently in use

local M = {}

local ns_pool = {
  next_id = 1,
  free_ids = {},
  used_ids = {},
  last_free_index = 0,
}

---Retrieves a new namespace ID from the pool.
---This function implements an O(1) allocation strategy by either:
--- - Reusing a previously released ID from the free_ids pool
--- - Generating a new ID if no free IDs are available
---@return number namespace_id The allocated namespace ID
function M.get_free_ns_id()
  -- First check if there are any free IDs available
  if ns_pool.last_free_index > 0 then
    local id = ns_pool.free_ids[ns_pool.last_free_index]

    ns_pool.used_ids[id] = true
    ns_pool.free_ids[ns_pool.last_free_index] = nil
    ns_pool.last_free_index = ns_pool.last_free_index - 1

    return id
  else
    local id = ns_pool.next_id
    ns_pool.next_id = ns_pool.next_id + 1
    ns_pool.used_ids[id] = true
    return id
  end
end

---Reserves multiple namespace IDs at once.
---Useful when you need to allocate several IDs for batch operations.
---@param count number The number of IDs to reserve
---@return number[] Array of allocated namespace IDs
function M.reserve_ns_ids(count)
  local ids = {}
  for _ = 1, count do
    table.insert(ids, M.get_free_ns_id())
  end
  return ids
end

---Releases multiple namespace IDs back to the pool.
---@param ids number[] Array of namespace IDs to release
function M.release_ns_ids(ids)
  for _, id in ipairs(ids) do
    M.release_ns_id(id)
  end
end

---Releases a namespace ID back to the pool.
---This function implements an O(1) release strategy by:
--- - Verifying the ID is currently in use
--- - Marking it as unused
--- - Adding it to the free IDs pool for future reuse
---@param id number The namespace ID to release
---@return boolean success True if the ID was released, false if the ID wasn't in use
function M.release_ns_id(id)
  if ns_pool.used_ids[id] then
    ns_pool.used_ids[id] = nil

    ns_pool.last_free_index = ns_pool.last_free_index + 1
    ns_pool.free_ids[ns_pool.last_free_index] = id
    return true
  end
  return false
end

---Returns statistics about the current state of the namespace pool.
---Useful for monitoring and debugging purposes.
---@return PoolStats Statistics about the pool's current state
function M.get_pool_stats()
  local used_count = 0
  for _ in pairs(ns_pool.used_ids) do
    used_count = used_count + 1
  end

  return {
    next_id = ns_pool.next_id,
    free_count = ns_pool.last_free_index,
    used_count = used_count,
  }
end

---Resets the namespace pool to its initial state.
---This is primarily intended for testing purposes.
function M.reset_pool()
  ns_pool.next_id = 1
  ns_pool.free_ids = {}
  ns_pool.used_ids = {}
  ns_pool.last_free_index = 0
end

return M
