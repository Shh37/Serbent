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
const COLOR_GHOST = Color("#928374") # Gruvbox Material gray

const COLOR_BUTTON_NORMAL = COLOR_FG
const COLOR_BUTTON_HOVER = COLOR_SNAKE
const COLOR_BUTTON_PRESSED = Color("#7f8b4d")
const COLOR_TOGGLE_ON = COLOR_POINT
const COLOR_TOGGLE_ON_HOVER = Color("#eac06d")
const COLOR_TOGGLE_ON_PRESSED = Color("#a06a2c")
const COLOR_TOGGLE_OFF = COLOR_DANGER
const COLOR_TOGGLE_OFF_HOVER = Color("#fb837c")
const COLOR_TOGGLE_OFF_PRESSED = Color("#b44f4a")
const COLOR_RANKING_LENGTH = COLOR_POINT
const COLOR_RANKING_LENGTH_HOVER = Color("#eac06d")
const COLOR_RANKING_LENGTH_PRESSED = Color("#a06a2c")
const COLOR_RANKING_SURVIVAL = COLOR_DANGER
const COLOR_RANKING_SURVIVAL_HOVER = Color("#fb837c")
const COLOR_RANKING_SURVIVAL_PRESSED = Color("#b44f4a")
const COLOR_SKIN_LOCKED = Color("#504945")
const BUTTON_SKIN_HOVER_LIGHTEN = 0.18
const BUTTON_PRESSED_DARKEN = 0.22

const COLOR_POINT_NORMAL = Color("#d8a657")
const POINT_VALUE_NORMAL = 1

enum PowerUpType { GHOST, TIME_STOP, DOUBLE_GROWTH }

enum SkinColor { BASIC, MINT, OLIVE, MOSS, LIME, EMERALD }
enum SkinPattern { SOLID, STRIPE11, STRIPE12, STRIPE21, STRIPE22, GRADIENT }

const SKIN_COLORS = {
	SkinColor.BASIC: Color("#a9b665"),
	SkinColor.MINT: Color("#89b482"),
	SkinColor.OLIVE: Color("#98971a"),
	SkinColor.MOSS: Color("#626e3c"),
	SkinColor.LIME: Color("#b8bb26"),
	SkinColor.EMERALD: Color("#689d6a"),
}

const COLOR_POWERUP_GHOST = Color("#d3869b") # Purple
const COLOR_POWERUP_TIME = Color("#7daea3")  # Blue
const COLOR_POWERUP_GROWTH = Color("#a9b665") # Green




const BOMB_SIZE = 5
const BOMB_WARNING_TIME = 2.5
const BOMB_EXPLOSION_TIME = 0.5

const SNAKE_INITIAL_SPEED = 0.2
const SNAKE_MIN_SPEED = 0.06
const SNAKE_SPEED_INCREMENT = 0.003
const SNAKE_DASH_MULTIPLIER = 0.4
const SNAKE_REVERSE_TIME = 0.6
