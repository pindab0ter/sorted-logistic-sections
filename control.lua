local inventory = require("scripts/inventory")

--- @param player LuaPlayer
--- @param enabled boolean?
local function set_sorting_enabled(player, enabled)
    enabled = enabled or false
    storage.sorting_enabled[player.index] = enabled
    player.set_shortcut_toggled("sorted-logistic-sections-toggle", enabled)
end

--- @param player LuaPlayer
--- @return boolean
local function toggle_sorting_enabled(player)
    local sorting_enabled = not storage.sorting_enabled[player.index]

    set_sorting_enabled(player, sorting_enabled)

    return sorting_enabled
end

--- @param player LuaPlayer
--- @param entity LuaEntity?
local function apply_sorting_if_enabled(player, entity)
    if not storage.sorting_enabled[player.index] then
        return
    end

    -- entity can be nil, e.g. player.character in remote view, the map editor or as a spectator
    if not player.valid or entity == nil or not entity.valid then
        return
    end

    inventory.sort_logistic_sections(entity)
end

--- @param player LuaPlayer
local function configure_player(player)
    set_sorting_enabled(player)
    apply_sorting_if_enabled(player, player.character)
end

--- For some reason the event is always triggered twice, so we ignore the second one
--- @param entity LuaEntity
--- @return boolean
local function was_sorted_this_tick(entity)
    if storage.last_sorted_on_tick == nil then
        storage.last_sorted_on_tick = {}
    end

    if not (storage.last_sorted_on_tick[entity.unit_number] == game.tick) then
        storage.last_sorted_on_tick[entity.unit_number] = game.tick
        return false
    end

    return true
end


--------------------
-- Event Handlers --
--------------------

local function on_configuration_changed()
    if storage.sorting_enabled == nil then
        storage.sorting_enabled = {}
    end
    storage.last_sorted_on_tick = {}

    for _, player in pairs(game.players) do
        if storage.sorting_enabled[player.index] == nil then
            configure_player(player)
        end
    end
end

--- @param event EventData.on_player_created
local function on_player_created(event)
    local player = game.players[event.player_index] or error("Player " .. event.player_index .. " not found")
    configure_player(player)
end

--- @param event EventData.on_player_removed
local function on_player_removed(event)
    storage.sorting_enabled[event.player_index] = nil
end

--- @param event EventData.on_entity_logistic_slot_changed
local function on_entity_logistic_slot_changed(event)
    if was_sorted_this_tick(event.entity) or event.player_index == nil then
        return
    end

    local player = game.get_player(event.player_index) or error("Player " .. event.player_index .. " not found")

    apply_sorting_if_enabled(player, event.entity)
end

--- @param event EventData.on_lua_shortcut
local function on_lua_shortcut(event)
    if event.prototype_name ~= "sorted-logistic-sections-toggle" then
        return
    end

    local player = game.get_player(event.player_index) or error("Player " .. event.player_index .. " not found")

    toggle_sorting_enabled(player)

    apply_sorting_if_enabled(player, player.character)
end

--- @param event EventData.CustomInputEvent
local function on_sorted_logistic_section_hotkey(event)
    local player = game.get_player(event.player_index) or error("Player " .. event.player_index .. " not found")

    toggle_sorting_enabled(player)

    apply_sorting_if_enabled(player, player.character)
end


-------------------
-- Event Binding --
-------------------

script.on_init(on_configuration_changed)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)
script.on_event(defines.events.on_player_removed, on_player_removed)
script.on_event(defines.events.on_entity_logistic_slot_changed, on_entity_logistic_slot_changed)
script.on_event(defines.events.on_lua_shortcut, on_lua_shortcut)
script.on_event("sorted-logistic-sections-hotkey", on_sorted_logistic_section_hotkey)
