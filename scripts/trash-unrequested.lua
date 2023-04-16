--- @type defines.inventory[]
local inventories_to_check = {
  defines.inventory.character_ammo,
  defines.inventory.character_armor, -- TODO: Don't check this?
  defines.inventory.character_guns,
  defines.inventory.character_main,
}

--- @param character LuaEntity
local function update_character_requests(character)
  local requests = global.character_requests[character.unit_number]
  if not requests then
    return
  end

  for _, inventory_id in pairs(inventories_to_check) do
    local inventory = character.get_inventory(inventory_id)
    if inventory then
      -- FIXME: This won't work because we need to check against the total count in all inventories
      for name, count in pairs(inventory.get_contents()) do
        local requested_count = requests[name] or 0
        if requested_count < count then
          game.print("TRASH " .. count - requested_count .. " " .. name)
        end
      end
    end
  end
end

--- @param character LuaEntity
local function schedule_character_requests_update(character)
  local unit_number = character.unit_number --[[@as uint]]
  global.pending_requests_update[unit_number] = character
end

--- @alias CharacterRequests table<string, uint>

--- @param character LuaEntity
--- @return CharacterRequests
local function rebuild_character_requests(character)
  --- @type CharacterRequests
  local requests = {}
  for i = 1, character.request_slot_count do
    --- @cast i uint
    local request = character.get_request_slot(i)
    if request then
      requests[request.name] = request.count
    end
  end
  global.character_requests[character.unit_number] = requests
  return requests
end

--- @param e EventData.on_entity_logistic_slot_changed
local function on_entity_logistic_slot_changed(e)
  local entity = e.entity
  if not entity.valid or entity.type ~= "character" then
    return
  end
  local unit_number = entity.unit_number --[[@as uint]]
  local request = entity.get_request_slot(e.slot_index)
  if request then
    local requests = global.character_requests[unit_number]
    requests[request.name] = request.count
  else
    rebuild_character_requests(entity)
  end
  schedule_character_requests_update(entity)
end

--- @param e EventData.CustomInputEvent|EventData.on_lua_shortcut
local function on_trash_unrequested_toggled(e)
  if e.prototype_name and e.prototype_name ~= "ple-trash-unrequested" then
    return
  end
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local character = player.character
  if not character then
    return
  end
  local unit_number = character.unit_number --[[@as uint]]
  local is_toggled = not global.trash_unrequested[unit_number]
  global.trash_unrequested[unit_number] = is_toggled
  player.set_shortcut_toggled("ple-trash-unrequested", is_toggled)
  if is_toggled then
    schedule_character_requests_update(character)
  end
end

--- @param e EventData.on_player_main_inventory_changed
local function on_player_inventory_changed(e)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local character = player.character
  if not character then
    return
  end
  local unit_number = character.unit_number --[[@as uint]]
  if not global.trash_unrequested[unit_number] then
    return
  end
  update_character_requests(character)
end

local function on_tick()
  for unit_number, character in pairs(global.pending_requests_update or {}) do
    update_character_requests(character)
    global.pending_requests_update[unit_number] = nil
  end
end

local function initialize()
  --- @type table<uint, CharacterRequests>
  global.character_requests = {}
  --- @type table<uint, LuaEntity>
  global.pending_requests_update = {}
  --- @type table<uint, boolean>
  global.trash_unrequested = {}

  for _, surface in pairs(game.surfaces) do
    for _, character in pairs(surface.find_entities_filtered({ type = "character" })) do
      rebuild_character_requests(character)
    end
  end
end

local trash_unrequested = {}

trash_unrequested.on_init = initialize
trash_unrequested.on_configuration_changed = initialize

trash_unrequested.events = {
  [defines.events.on_entity_logistic_slot_changed] = on_entity_logistic_slot_changed,
  [defines.events.on_lua_shortcut] = on_trash_unrequested_toggled,
  [defines.events.on_player_ammo_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_player_armor_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_player_gun_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_player_main_inventory_changed] = on_player_inventory_changed,
  [defines.events.on_tick] = on_tick,
  ["ple-trash-unrequested"] = on_trash_unrequested_toggled,
}

return trash_unrequested
