RADIUS = 3963.1676 * 5280
HEIGHT = ARGV[0].to_i

distance = RADIUS * Math.atan(
  Math.sqrt(
    ((RADIUS + HEIGHT) ** 2 - (RADIUS ** 2)) /
    (RADIUS + HEIGHT)
  )
)
puts distance
