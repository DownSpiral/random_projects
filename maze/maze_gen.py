#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
def maze_gen(length, width, edge_hole_tuples):
  def surrounding_tiles(tile):
    (x, y) = tile
    sur_tiles = set()
    if x != 0:
      sur_tiles.add((x - 1, y))
    if x != length - 1:
      sur_tiles.add((x + 1, y))
    if y != 0:
      sur_tiles.add((x, y - 1))
    if y != width - 1:
      sur_tiles.add((x, y + 1))
    return sur_tiles

  maze = [[0 for x in range(length)] for y in range(width)]
  all_tiles = set()
  for x in range(length):
    for y in range(width):
      if (x, y) not in edge_hole_tuples:
        all_tiles.add((x,y))
  for (x, y) in edge_hole_tuples:
    maze[y][x] = 1

  working_tiles = set()
  first_edge = edge_hole_tuples.pop()
  for t in surrounding_tiles(first_edge):
    working_tiles.add(t)

  while len(working_tiles) > 0:
    tile = working_tiles.pop()
    tiles = surrounding_tiles(tile)
    touching_count = reduce(lambda m, (x, y): m + maze[y][x], tiles, 0)
    edges = edge_hole_tuples & tiles

    if touching_count == 1:
      maze[tile[1]][tile[0]] = 1
    elif touching_count == 2 and len(edges) > 0:
      maze[tile[1]][tile[0]] = 1
      edge_hole_tuples.remove(edges.pop())
    else:
      continue
    for t in tiles:
      if t in all_tiles:
        working_tiles.add(t)
        all_tiles.remove(t)

  return maze

x_len = 25
y_len = 25
maze = maze_gen(x_len, y_len, set([(0,0), (x_len - 1, y_len - 1)]))
viewable = False
if (viewable):
  import codecs
  sys.stdout=codecs.getwriter('utf-8')(sys.stdout)

  wall_char = u"◽"
  path_char = u"◾"
  print wall_char * (x_len + 2)
  for row in maze:
    print wall_char + ''.join(path_char if x == 1 else wall_char for x in row) + wall_char
  print wall_char * (x_len + 2)
else:
  maze = [[0] * x_len] + maze + [[0] * x_len]
  first = True
  sys.stdout.write('[')
  i = 0
  for row in maze:
    comma = "," if i < len(maze) - 1 else "]"
    print str([0] + row + [0]) + comma
    i += 1
