extends Node
class_name GameConstants

const CELL_SIZE = 32
const CHUNK_SIZE = 16 # Cells per chunk side
const CHUNK_PIXEL_SIZE = CELL_SIZE * CHUNK_SIZE

# Colors (Gruvbox Material Dark Medium)
const COLOR_BG = Color("#282828")
const COLOR_FG = Color("#d4be98")
const COLOR_SNAKE = Color("#a9b665")
const COLOR_DANGER = Color("#ea6962")
const COLOR_POINT = Color("#d8a657")
const COLOR_CHUNK_BORDER = Color("#3c3836")
const COLOR_BLOCK_BORDER = Color("#32302f") # Slightly lighter than BG
const COLOR_ACCENT_BLUE = Color("#7daea3")
const COLOR_ACCENT_PURPLE = Color("#d3869b")

const COLOR_POINT_NORMAL = Color("#d8a657")
const COLOR_POINT_MEDIUM = Color("#d3869b")
const COLOR_POINT_LARGE = Color("#7daea3")

const POINT_VALUE_NORMAL = 1
const POINT_VALUE_MEDIUM = 2
const POINT_VALUE_LARGE = 3

const BOMB_SIZE = 5
const BOMB_WARNING_TIME = 2.5
const BOMB_EXPLOSION_TIME = 0.5

const SNAKE_INITIAL_SPEED = 0.2
const SNAKE_MIN_SPEED = 0.06
const SNAKE_SPEED_INCREMENT = 0.003
const SNAKE_DASH_MULTIPLIER = 0.4
