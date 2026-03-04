# Implementation Plan: Pruner Mod for Luanti

## Architecture

The mod is a single-directory Luanti mod with three files. All game logic lives in `init.lua`, organized into four clear sections. No external dependencies beyond the `default` mod.

```
building/pruner/
├── mod.conf                    # Mod metadata
├── init.lua                    # All logic (config, BFS, callback, registration)
└── textures/
    └── pruner_pruner.png       # 16x16 placeholder texture
```

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Activation | `on_use` (left-click) | Standard "break" interaction pattern |
| Max leaves per use | 100 nodes | Covers most trees (~40-60 leaves), prevents lag |
| Durability | ~200 leaf breaks (~5 trees) | Per-leaf wear via `add_wear()` |
| BFS adjacency | 6 cardinal directions | Tree leaves are placed cardinally; no diagonals |
| Namespace | `core` (not `minetest`) | Modern Luanti convention |
| Queue implementation | Array + head index | O(1) dequeue vs O(n) for `table.remove` |
| Tool description | Name + usage hint | "Steel Pruner — punch leaves to clear the canopy" |

## Implementation Sections (init.lua)

### Section A: Configuration Constants
- `MAX_LEAVES = 100` — BFS cap
- `WEAR_PER_LEAF = math.ceil(65535 / 200)` — ~328 wear per leaf, ~200 total breaks

### Section B: BFS Function `find_connected_leaves(start_pos)`
- Queue-based BFS using array + head index pointer
- Explores 6 cardinal directions: `{0,1,0}, {0,-1,0}, {1,0,0}, {-1,0,0}, {0,0,1}, {0,0,-1}`
- Visited set uses string keys `x..":"..y..":"..z`
- Checks `core.registered_nodes[node.name]` for `leaves` group membership
- Returns list of `{pos=pos, node=node}` entries, capped at `MAX_LEAVES`
- Naturally handles unloaded chunks (`ignore` nodes have no groups)

### Section C: `on_use` Callback `pruner_on_use(itemstack, user, pointed_thing)`
- Guard: return if `pointed_thing.type ~= "node"`
- Get target position from `pointed_thing.under`
- Guard: return if target node not in `leaves` group
- Call BFS to get connected leaves list
- Loop through leaves:
  1. `core.get_node_drops(node.name, "")` for drop table
  2. `core.remove_node(pos)` to break the leaf
  3. `core.handle_node_drops(pos, drops, user)` to give drops
  4. `itemstack:add_wear(WEAR_PER_LEAF)` to apply wear
  5. Break if `itemstack:is_empty()` (tool broke)
- Return modified `itemstack`

### Section D: Registration
- `core.register_tool("pruner:pruner", {...})` with:
  - `description = "Steel Pruner — punch leaves to clear the canopy"`
  - `inventory_image = "pruner_pruner.png"`
  - `wield_image = "pruner_pruner.png"`
  - `tool_capabilities` with minimal groupcap (for wear bar display)
  - `on_use = pruner_on_use`
- `core.register_craft({...})` with diagonal shears-on-stick pattern

## mod.conf Structure

```
name = pruner
description = Adds a pruner tool that clears connected leaves from trees
depends = default
```

## Texture (pruner_pruner.png)
- 16x16 pixel PNG, transparent background
- Generated programmatically as a minimal valid placeholder
- Simple representation: steel blades (upper) + brown handle (lower)

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| PNG generation produces invalid file | Low | Use known-good minimal PNG byte sequence |
| BFS explores too many nodes | None | Hard cap at 100 |
| Wear calculation off by one | Low | `math.ceil` ensures tool breaks at or before 200 uses |
| `on_use` overrides all dig behavior | Expected | Documented — pruner only prunes |
