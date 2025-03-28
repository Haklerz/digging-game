# World system

- [ ] Figure out what chunks should be loaded.
- [ ] Request chunks in a spiral pattern starting from the center chunk.
- [ ] Unload LRU chunk when we run out of space for loaded chunks.
- [ ] Generate caves.

# World rendering

- [x] Sync render state with world state.
- [x] Render loaded chunks using "on-grid" tiles.
- [x] Render using "dual-grid" tiles.
- [ ] Cull offscreen chunks.

# Particle System

- [ ] Server side particle emitters.
- [ ] Client side particles.

# Client

- [ ] Reduce framerate when window is not focused.

# Entity system

- [ ] Make simple entities with a position and collider that can move around the world.
- [ ] Entities will request chunks to be loaded around them. (Players)

# Entity rendering

- [ ] Dead reckoning interpolation

# Simulation

- [x] Multi-threading.  
      Updating the simulation should happen in it's own thread.
- [ ] Implement simple AABB collisions.
- [ ] Push off corners.  
      Fudge an entities position if they collide with a corner to avoid gettting stuck on them.

# Rollback netcode / Multiplayer

- [ ] Have a deterministic simulate proc.
- [ ] Keep a history of Game_State's.
      This will require a circular buffer and keeping track of ticks.

# Input / Controls

- [ ] Input buffering.