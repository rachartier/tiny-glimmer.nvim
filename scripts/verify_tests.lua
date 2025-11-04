-- Simple test verification script
-- Checks if test files can be loaded without errors

local test_files = {
  "tests/test_config_defaults.lua",
  "tests/test_config_highlights.lua",
  "tests/test_api.lua",
  "tests/test_setup.lua",
  "tests/test_init.lua",
}

print("Verifying test files can be loaded...")
print("")

local errors = {}
local success_count = 0

for _, file in ipairs(test_files) do
  local status, result = pcall(dofile, file)
  if status then
    if type(result) == "table" then
      success_count = success_count + 1
      print(string.format("✓ %s", file))
    else
      table.insert(errors, string.format("✗ %s - doesn't return a test set", file))
    end
  else
    table.insert(errors, string.format("✗ %s - %s", file, result))
  end
end

print("")
print(string.format("Loaded %d/%d test files successfully", success_count, #test_files))

if #errors > 0 then
  print("\nErrors:")
  for _, err in ipairs(errors) do
    print("  " .. err)
  end
  os.exit(1)
else
  print("\nAll test files verified!")
  os.exit(0)
end
