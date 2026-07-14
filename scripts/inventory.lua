local inventory_sort = {}

local comparator_order = {
    ["<"] = 1,
    ["≤"] = 2,
    ["<="] = 3,
    ["="] = 4,
    ["≠"] = 5,
    ["!="] = 6,
    [">="] = 7,
    ["≥"] = 8,
    [">"] = 9,
}

--- Maps SignalIDType to the corresponding table in `prototypes`
local prototype_table_names = {
    ["item"] = "item",
    ["fluid"] = "fluid",
    ["virtual"] = "virtual_signal",
    ["entity"] = "entity",
    ["recipe"] = "recipe",
    ["space-location"] = "space_location",
    ["asteroid-chunk"] = "asteroid_chunk",
    ["quality"] = "quality",
}

--- @param filter LogisticFilter
--- @return LuaPrototypeBase?
local function get_prototype(filter)
    local table_name = prototype_table_names[filter.value.type or "item"]

    return table_name and prototypes[table_name][filter.value.name] or nil
end

--- @param a LogisticFilter
--- @param b LogisticFilter
--- @return boolean
local function filter_comparator(a, b)
    local prototype_a = get_prototype(a)
    local prototype_b = get_prototype(b)

    -- Filters without a known prototype sort to the end, by type and name
    if prototype_a == nil or prototype_b == nil then
        if prototype_a ~= nil then
            return true
        end
        if prototype_b ~= nil then
            return false
        end

        local type_a = a.value.type or "item"
        local type_b = b.value.type or "item"
        if type_a ~= type_b then
            return type_a < type_b
        end

        return a.value.name < b.value.name
    end

    if prototype_a.group.order ~= prototype_b.group.order then
        return prototype_a.group.order < prototype_b.group.order
    end

    if prototype_a.subgroup.order ~= prototype_b.subgroup.order then
        return prototype_a.subgroup.order < prototype_b.subgroup.order
    end

    if prototype_a.order ~= prototype_b.order then
        return prototype_a.order < prototype_b.order
    end

    local quality_name_a = a.value.quality or "normal"
    local quality_name_b = b.value.quality or "normal"
    if quality_name_a ~= quality_name_b then
        local quality_a = prototypes.quality[quality_name_a]
        local quality_b = prototypes.quality[quality_name_b]

        if quality_a == nil or quality_b == nil then
            return quality_name_a < quality_name_b
        end

        return quality_a.order < quality_b.order
    end

    local comparator_a = comparator_order[a.value.comparator or "="] or 99
    local comparator_b = comparator_order[b.value.comparator or "="] or 99
    if comparator_a ~= comparator_b then
        return comparator_a < comparator_b
    end

    return false
end

--- Sorts the filter item order using a `LuaInventory` and then sorts the filters with the same items by quality and
--- comparator.
--- @param section LuaLogisticSection
local function sort_section(section)
    ---@type table<number, LogisticFilter>
    local filter_buffer = {}

    local filter_buffer_index = 1
    for _, filter in pairs(section.filters) do
        if filter == nil or not filter.value then
            goto continue
        end

        filter_buffer[filter_buffer_index] = filter
        filter_buffer_index = filter_buffer_index + 1

        ::continue::
    end

    table.sort(filter_buffer, filter_comparator)

    -- Clear all filters from the section so we can re-add them in the correct order without running into conflicts
    for index, _ in pairs(section.filters) do
        section.clear_slot(index)
    end

    -- Insert the filters back in, in the order of the sorted inventory
    local slot_index = 1
    for _, filter in pairs(filter_buffer) do
        section.set_slot(slot_index, filter)
        slot_index = slot_index + 1
    end
end

--- @param entity LuaEntity
inventory_sort.sort_logistic_sections = function(entity)
    if entity == nil or not entity.valid then
        return
    end

    local logistic_sections = entity.get_logistic_sections()

    if logistic_sections == nil then
        return
    end

    for _, section in pairs(logistic_sections.sections) do
        if section.is_manual then
            sort_section(section)
        end
    end
end

return inventory_sort
