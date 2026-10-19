-- Makes the dash clock tell the time. The two hands are meshes hanging from the CLOCK_HOUR_HAND and CLOCK_MINUTE_HAND
-- nodes (empties at the middle of the dial); this turns those two nodes about the dial's axis to the time ([SCRIPT_0] in
-- ext_config.ini).
-- Needs Custom Shaders Patch. Without it the hands stay at the 10:08 they are modelled at, so the dial is a still clock.

local USE_GAME_TIME = false     -- false: the PC's clock; true: the session's time of day (follows the sun and the time multiplier)

-- The dial's own directions in the model's coordinates (the ones the nodes' matrices use: x is the car's left, y up,
-- z forward): UP is 12 o'clock and RIGHT is 3 o'clock as the driver sees them. The dial is tilted back with the dash, so
-- UP leans. They come from the dial's plane in the .blend, so work them out again if the dial moves or is retilted.
local UP = { 0, 0.89849, 0.43900 }
local RIGHT = { -1, 0, 0 }

-- The pose the hands are modelled in (10:08), in degrees clockwise from 12 o'clock.
local HOUR_MODELLED = 304
local MINUTE_MODELLED = 48

local function dot(a, b)
  return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

-- Finds a hand's node and keeps a copy of the first three rows of its matrix (where its three axes point, in the model's
-- coordinates; the node's position is the fourth row and doesn't change).
local function findHand(name, modelled)
  local m = ac.findNodes(name):getTransformationRaw()
  if m == nil then return nil end
  return {
    matrix = m,
    modelled = modelled,
    rows = {
      { m.row1.x, m.row1.y, m.row1.z },
      { m.row2.x, m.row2.y, m.row2.z },
      { m.row3.x, m.row3.y, m.row3.z },
    },
  }
end

-- Turns a hand to the given angle (degrees clockwise from 12 o'clock, as the driver sees it). Each axis of the node is
-- rotated in the dial's plane by the difference from the modelled pose; anything pointing out of the dial stays put.
-- Done with the dial's two directions rather than an axis and an angle, so there's no sign or handedness to get wrong.
local function turn(hand, degrees)
  local angle = math.rad(degrees - hand.modelled)
  local c, s = math.cos(angle), math.sin(angle)
  local rows = {}
  for i = 1, 3 do
    local v = hand.rows[i]
    local a, b = dot(v, UP), dot(v, RIGHT)
    local ku = a * (c - 1) - b * s
    local kr = a * s + b * (c - 1)
    rows[i] = vec4(v[1] + UP[1] * ku + RIGHT[1] * kr, v[2] + UP[2] * ku + RIGHT[2] * kr, v[3] + UP[3] * ku + RIGHT[3] * kr, 0)
  end
  hand.matrix:set(mat4x4(rows[1], rows[2], rows[3], hand.matrix.row4))
end

local function secondsOfDay()
  if USE_GAME_TIME then
    return ac.getSim().timeTotalSeconds
  end
  local t = os.date('*t')
  return t.hour * 3600 + t.min * 60 + t.sec
end

local hands

function script.update(dt)
  if hands == nil then
    hands = {
      hour = findHand('CLOCK_HOUR_HAND', HOUR_MODELLED),
      minute = findHand('CLOCK_MINUTE_HAND', MINUTE_MODELLED),
    }
  end
  local t = secondsOfDay()
  if hands.hour then turn(hands.hour, t / 120 % 360) end       -- once round in 12 hours
  if hands.minute then turn(hands.minute, t / 10 % 360) end    -- once round in an hour
end
