# Feature Specification: Pruner Mod for Luanti

## Overview

A Luanti (formerly Minetest) mod that adds a **Pruner** tool. When a player uses the Pruner on a leaf block, it breaks all connected leaf blocks via breadth-first search, giving the player all normal drops (saplings, sticks, etc.) from each broken leaf. This is a practical utility tool for quickly clearing tree canopies after chopping the trunk.

## Requirements

### Functional Requirements

#### FR-1: Pruner Tool Behavior
- The Pruner is a single-variant tool (Steel Pruner) crafted and used like any other Luanti tool
- Left-clicking (punching) a leaf node with the Pruner triggers a breadth-first search from that leaf
- BFS finds all connected leaf nodes in the 6 cardinal directions (no diagonals)
- Every connected leaf found by the BFS is removed, and the player receives proper drops for each leaf
- Drops respect normal drop chances (e.g., saplings at 1/20)
- If the player punches a non-leaf node, the Pruner does nothing

#### FR-2: BFS Constraints
- BFS is capped at 100 leaves per use to prevent server lag
- Most trees have 40-60 leaves, so this covers nearly all trees in one action
- BFS explores only 6 cardinal directions (up, down, north, south, east, west)
- Uses string keys (`x:y:z`) for visited set to track already-checked positions

#### FR-3: Tool Durability
- Durability of approximately 200 individual leaf breaks (about 5 full trees)
- Wear is applied per leaf broken using `itemstack:add_wear()`
- Wear per leaf: `math.ceil(65535 / 200)` = ~328 wear units
- The tool can break mid-use if it runs out of durability
- Loop stops immediately if tool wears out (checked via `itemstack:is_empty()`)

#### FR-4: Crafting Recipe
- Crafted from 2 steel ingots and 1 stick
- Diagonal shears-on-stick shaped recipe:
  - Row 1: empty, steel ingot, empty
  - Row 2: steel ingot, empty, empty
  - Row 3: empty, empty, stick (`group:stick`)
- Depends on `default` mod for steel ingots, sticks, and leaf node definitions

### Non-Functional Requirements

#### NFR-1: Performance
- 100 `get_node` + `remove_node` calls is sub-millisecond each; no server lag
- Array-based queue with head index pointer for O(1) dequeue (avoids `table.remove` which is O(n))

#### NFR-2: Robustness
- Unloaded chunks return `ignore` nodes which have no `leaves` group; BFS naturally stops at chunk boundaries
- Player-built leaf walls will be pruned — this is expected behavior
- Hard dependency on `default` mod; mod will not load without it, with clear error message

#### NFR-3: Code Conventions
- Uses the `core` namespace (modern Luanti convention, not legacy `minetest` alias)
- Texture naming follows Luanti convention: `modname_itemname.png`

## Clarification Decisions

- **Mod location**: Created inside `building/pruner/` (the working directory)
- **Texture**: Generated programmatically as a minimal valid 16x16 placeholder PNG
- **Tool description**: Includes usage hint — `"Steel Pruner — punch leaves to clear the canopy"`

## Mod Structure

```
building/pruner/
├── mod.conf                    # Mod metadata (name, description, depends)
├── init.lua                    # All mod logic
└── textures/
    └── pruner_pruner.png       # 16x16 tool texture (placeholder)
```

Three files total.

## API Functions Used

| Function | Purpose |
|----------|---------|
| `core.register_tool` | Register a new tool item |
| `core.register_craft` | Register a crafting recipe |
| `core.get_node` | Get the node at a position |
| `core.registered_nodes` | Look up a node's definition (groups, etc.) |
| `core.remove_node` | Remove a node from the world |
| `core.get_node_drops` | Get the drop table for a node |
| `core.handle_node_drops` | Give drops to player or drop on ground |
| `itemstack:add_wear` | Add wear to a tool (65535 = fully worn) |
| `itemstack:is_empty` | Check if tool has been destroyed by wear |

## Edge Cases

| Edge Case | Handling |
|-----------|---------|
| BFS hits unloaded chunks (`ignore` nodes) | `ignore` has no `leaves` group — BFS skips naturally |
| Player-built leaf walls | Pruned — tool breaks leaves regardless of origin |
| Tool breaks mid-loop | `itemstack:is_empty()` check stops the loop |
| Mod loaded without `default` | Hard dependency prevents loading with clear error |
| Isolated single leaf | Only that one leaf breaks |
| Non-leaf node punched | Nothing happens |

## Out of Scope

- Multiple tool variants (wooden, diamond)
- Particle or sound effects
- Trunk detection to avoid pruning merged canopies
- Server-configurable settings

## Testing Plan

1. Place mod in Luanti mods directory (or symlink)
2. Enable mod for a test world
3. Use `/giveme pruner:pruner` or craft it
4. Punch leaves on a tree — all connected leaves should break
5. Verify: drops appear (saplings, sticks), wear bar decreases, tool eventually breaks
6. Edge cases: punch non-leaf node (nothing), punch isolated leaf (only that one)
