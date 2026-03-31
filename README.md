# godot-rts-terrain

A Warcraft 3-style terrain editor and RTS prototype built as a Godot 4 editor plugin. It provides procedural terrain mesh generation with editable cliff levels, ramps, and textured ground tiles, all manipulable directly in the Godot editor. The project also includes an A*-based navigation system, physics-driven unit movement, and basic RTS game mechanics like building placement and resource management.

## Features

- **Terrain Editor Plugin** — In-editor tools for raising/lowering terrain, placing ramps, and painting cliff models with rotation support
- **Procedural Mesh Generation** — Ground and cliff meshes generated from a heightmap with automatic UV mapping and collision shapes
- **3D Cliff Models** — Snap-in cliff pieces (sides, inner/outer corners, ramps) with multiple art styles (dungeon, simple)
- **A*-Based Pathfinding** — Node-based navigation graph with debug visualization and path caching via `NavigationRouter`
- **Physics-Based Unit Movement** — Units use `CharacterBody3D` with `move_and_slide()` for proper terrain collision
- **RTS Game Systems** — Gold resource management, building placement with terrain holes, unit selection box, and tower construction

## Limitations

- The project targets Godot 4.0 alpha/beta and may not work with newer Godot 4.x stable releases without adjustments
- The terrain editor is a prototype — there is no undo/redo, no save/load for terrain data, and no map serialization
- Navigation relies on manually placed `NavigationNode3D` waypoints rather than automatic navmesh generation
- Only a Windows Desktop export preset is configured

## Getting Started

1. Install [Godot 4](https://godotengine.org/download) (the project was developed against early 4.0 builds)
2. Clone this repository:
   ```
   git clone https://github.com/shmolyneaux/godot-rts-terrain.git
   ```
3. Open the project in the Godot editor by importing `project.godot`
4. Enable the **RTS Terrain** plugin under **Project → Project Settings → Plugins**
5. Open `Scenes/main.tscn` and run the project (F5)

### Using the Terrain Editor

Select an `RtsTerrain` node in the scene tree. The terrain editing dock will appear, allowing you to:

- Raise or lower cliff levels
- Place and rotate ramp/cliff models
- Assign ground and cliff materials via the inspector

## History

Development started on 2022-02-06 and largely stopped on 2022-02-24:

- 2022-02-06 — Initial procedural terrain generation with cliff levels, ramps, and collision
- 2022-02-08 — Terrain editor plugin with in-editor brush and tool dock
- 2022-02-10 — Per-vertex heightmap editing support
- 2022-02-11 — Material system with separate ground and cliff textures
- 2022-02-12 — 3D cliff model assets (sides, corners, ramps from `.glb` files)
- 2022-02-13 — Full cliff model integration with rotation and automatic placement
- 2022-02-14 — Simplified cliff model variants
- 2022-02-15 — Physics-based unit movement using `CharacterBody3D`
- 2022-02-19 — A*-based pathfinding with `NodeNavigationServer3D` and debug visualization
- 2022-02-20 — Navigation routing with path caching, dungeon-themed assets, health and damage systems
- 2022-02-24 — RTS game systems: gold resources, building placement, unit selection, and UI
