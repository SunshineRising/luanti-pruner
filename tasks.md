# Tasks: Pruner Mod for Luanti

## Task Overview

| Task | Description | Dependencies | Status |
|------|-------------|-------------|--------|
| T1 | Create mod directory structure and mod.conf | None | done |
| T2 | Generate placeholder texture | T1 | done |
| T3 | Write init.lua — config constants and BFS function | T1 | done |
| T4 | Write init.lua — on_use callback, tool & craft registration | T3 | done |

---

### T1: Create mod directory structure and mod.conf

**Status**: done
**Dependencies**: None

Create the `pruner/` directory inside `building/`, including `textures/` subdirectory, and write `mod.conf`.

**Acceptance criteria**:
- `building/pruner/` directory exists
- `building/pruner/textures/` directory exists
- `building/pruner/mod.conf` contains name, description, and `depends = default`

**Files**:
- Create: `pruner/mod.conf`

---

### T2: Generate placeholder texture

**Status**: done
**Dependencies**: T1

Generate a minimal valid 16x16 PNG file at `pruner/textures/pruner_pruner.png`. The image should be a simple programmatically-generated placeholder representing angled steel blades on a brown stick handle with transparent background.

**Acceptance criteria**:
- `pruner/textures/pruner_pruner.png` exists and is a valid PNG
- Image is 16x16 pixels

**Files**:
- Create: `pruner/textures/pruner_pruner.png`

---

### T3: Write init.lua — config constants and BFS function

**Status**: done
**Dependencies**: T1

Write the first half of `init.lua` containing:
- Section A: Configuration constants (`MAX_LEAVES = 100`, `WEAR_PER_LEAF = math.ceil(65535 / 200)`)
- Section B: `find_connected_leaves(start_pos)` BFS function
  - Array-based queue with head index for O(1) dequeue
  - 6 cardinal directions
  - String key visited set (`x:y:z`)
  - Checks `leaves` group membership via `core.registered_nodes`
  - Returns list of `{pos, node}` capped at MAX_LEAVES

**Acceptance criteria**:
- `pruner/init.lua` exists with constants and BFS function
- BFS uses efficient queue (no `table.remove`)
- BFS respects MAX_LEAVES cap
- Uses `core` namespace (not `minetest`)

**Files**:
- Create: `pruner/init.lua`

---

### T4: Write init.lua — on_use callback, tool & craft registration

**Status**: done
**Dependencies**: T3

Append to `init.lua`:
- Section C: `pruner_on_use(itemstack, user, pointed_thing)` callback
  - Guards for non-node and non-leaf targets
  - Calls BFS, loops through results
  - Gets drops, removes node, handles drops, applies wear
  - Stops if tool breaks
- Section D: `core.register_tool("pruner:pruner", ...)` with description "Steel Pruner — punch leaves to clear the canopy", images, tool_capabilities, on_use
- `core.register_craft(...)` with diagonal shears-on-stick recipe

**Acceptance criteria**:
- on_use callback handles all edge cases (non-node, non-leaf, tool breaking)
- Tool registered with correct description and images
- Craft recipe uses 2 steel ingots + 1 stick in correct pattern
- Uses `group:stick` for stick ingredient
- Uses `core` namespace throughout

**Files**:
- Edit: `pruner/init.lua`
