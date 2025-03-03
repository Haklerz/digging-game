* Build server side code first.

# Notes from Daniel P H Fox's "Daydream" devlogs

## Chunking system

Generate the world in chunks around players.

On the server side, the chunks will have a chunk coordinate, and hold the tiles for that chunk.

On the client side the chunk will also need to store a dual grid representation of the chunk. This will need to be recalculated every time the chunk changes.

## Seperate representation of chunks and rendering of chunks

Store the chunks in the world.
Store the required extra data for rendering in Chunk_Renderer's.


A Chunk_Renderer holds the data required to draw a representation of a chunk.
It is reconciled with it's corresponding chunk whenever the chunk becomes dirty. [^1]

[^1]: The Chunk_Renderer will actually also have to be updated if any of the neighbouring chunks change.

We then need a World_Renderer that will hold all the Chunk_Renderer's.  
It will provide a way to reconsile the whole world.

When entities are introduced this will also perform the interpolation for them.

## Void tiles

Have a void tile type that is a actual tile type.

It is solid, but does not render.

When asking for a tile from a chunk that is not loaded return a void tile.

This will also be used to handle the edge of the world for dual grid tile rendering.

## Texture Atlas

Use a texture atlas.
