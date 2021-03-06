import sys

def graph(x1, x2, y1, y2, func):
  for y in reversed(xrange(y1, y2 + 1)):
    for x in xrange(x1, x2 + 1):
      if (abs(y - func(x)) < 2):
        out = '*'
      elif (x == 0 and y == 0):
        out = '+'
      elif (y == 0):
        out = '-'
      elif (x == 0):
        out = '|'
      else:
        out = ' '
      sys.stdout.write(out)
    print ''

graph(-10, 10, -10, 10, lambda x: (x * x) - 8)
