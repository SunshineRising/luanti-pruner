-- Pruner Mod for Luanti
-- Clears connected leaves from trees via BFS

-- Section A: Configuration Constants

local MAX_LEAVES = 100
local WEAR_PER_LEAF = math.ceil(65535 / 200)

-- Section B: BFS Function

local function find_connected_leaves(start_pos)
    local queue = {{x = start_pos.x, y = start_pos.y, z = start_pos.z}}
    local head = 1
    local visited = {}
    local result = {}

    local key = start_pos.x .. ":" .. start_pos.y .. ":" .. start_pos.z
    visited[key] = true

    local directions = {
        {x = 0, y = 1, z = 0},
        {x = 0, y = -1, z = 0},
        {x = 1, y = 0, z = 0},
        {x = -1, y = 0, z = 0},
        {x = 0, y = 0, z = 1},
        {x = 0, y = 0, z = -1},
    }

    while head <= #queue do
        local pos = queue[head]
        head = head + 1

        local node = core.get_node(pos)
        local def = core.registered_nodes[node.name]

        if def and def.groups and def.groups.leaves and def.groups.leaves > 0 then
            result[#result + 1] = {pos = pos, node = node}
            if #result >= MAX_LEAVES then
                break
            end

            for _, dir in ipairs(directions) do
                local neighbor = {
                    x = pos.x + dir.x,
                    y = pos.y + dir.y,
                    z = pos.z + dir.z,
                }
                local nkey = neighbor.x .. ":" .. neighbor.y .. ":" .. neighbor.z
                if not visited[nkey] then
                    visited[nkey] = true
                    queue[#queue + 1] = neighbor
                end
            end
        end
    end

    return result
end

-- Section C: on_use Callback

local function pruner_on_use(itemstack, user, pointed_thing)
    if pointed_thing.type ~= "node" then
        return
    end

    local pos = pointed_thing.under
    local node = core.get_node(pos)
    local def = core.registered_nodes[node.name]

    if not def or not def.groups or not def.groups.leaves or def.groups.leaves == 0 then
        return
    end

    local leaves = find_connected_leaves(pos)

    for _, leaf in ipairs(leaves) do
        local drops = core.get_node_drops(leaf.node.name, "")
        core.remove_node(leaf.pos)
        core.handle_node_drops(leaf.pos, drops, user)

        itemstack:add_wear(WEAR_PER_LEAF)
        if itemstack:is_empty() then
            break
        end
    end

    return itemstack
end

-- Section D: Tool and Craft Registration

core.register_tool("pruner:pruner", {
    description = "Steel Pruner — punch leaves to clear the canopy",
    inventory_image = "pruner_pruner.png",
    wield_image = "pruner_pruner.png",
    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level = 0,
        groupcaps = {
            leaves = {times = {[1] = 0.5}, uses = 200, maxlevel = 1},
        },
    },
    on_use = pruner_on_use,
})

core.register_craft({
    output = "pruner:pruner",
    recipe = {
        {"", "default:steel_ingot", ""},
        {"default:steel_ingot", "", ""},
        {"", "", "group:stick"},
    },
})
