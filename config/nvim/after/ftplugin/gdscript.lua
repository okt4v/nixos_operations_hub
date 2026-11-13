vim.opt_local.comments = ":#"
vim.opt_local.commentstring = "# %s"
vim.opt_local.formatoptions:remove({ "r", "o" })

-- Increase indent after any line ending with ':' (if/for/func/class/match/etc.)
_G.__gdscript_indent = function()
  local lnum = vim.v.lnum
  local prev_lnum = vim.fn.prevnonblank(lnum - 1)
  if prev_lnum == 0 then return 0 end

  local prev_line = vim.fn.getline(prev_lnum)
  local prev_indent = vim.fn.indent(prev_lnum)
  local sw = vim.fn.shiftwidth()
  local code = prev_line:gsub("%s*#.*$", ""):gsub("%s+$", "")

  if code:sub(-1) == ":" then
    return prev_indent + sw
  end
  return prev_indent
end

vim.opt_local.indentexpr = "v:lua.__gdscript_indent()"
vim.opt_local.indentkeys:append("=~:")

local ok, ls = pcall(require, "luasnip")
if not ok then return end

local s   = ls.snippet
local t   = ls.text_node
local i   = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

ls.add_snippets("gdscript", {

  -- Lifecycle
  s("ready",            fmt("func _ready() -> void:\n\t{}", { i(1, "pass") })),
  s("process",          fmt("func _process(delta: float) -> void:\n\t{}", { i(1, "pass") })),
  s("physics_process",  fmt("func _physics_process(delta: float) -> void:\n\t{}", { i(1, "pass") })),
  s("input",            fmt("func _input(event: InputEvent) -> void:\n\t{}", { i(1, "pass") })),
  s("unhandled_input",  fmt("func _unhandled_input(event: InputEvent) -> void:\n\t{}", { i(1, "pass") })),
  s("gui_input",        fmt("func _gui_input(event: InputEvent) -> void:\n\t{}", { i(1, "pass") })),
  s("enter_tree",       fmt("func _enter_tree() -> void:\n\t{}", { i(1, "pass") })),
  s("exit_tree",        fmt("func _exit_tree() -> void:\n\t{}", { i(1, "pass") })),
  s("draw",             fmt("func _draw() -> void:\n\t{}", { i(1, "pass") })),
  s("notification", fmt([[
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			{}
]], { i(1, "pass") })),

  -- Functions
  s("func",  fmt("func {}({}) -> {}:\n\t{}", { i(1, "name"), i(2), i(3, "void"), i(4, "pass") })),
  s("sfunc", fmt("static func {}({}) -> {}:\n\t{}", { i(1, "name"), i(2), i(3, "void"), i(4, "pass") })),

  -- Variables
  s("var",          fmt("var {}: {} = {}", { i(1, "name"), i(2, "Variant"), i(3) })),
  s("const",        fmt("const {} := {}", { i(1, "NAME"), i(2, "value") })),
  s("export",       fmt("@export var {}: {} = {}", { i(1, "name"), i(2, "Variant"), i(3) })),
  s("export_range", fmt("@export_range({}, {}) var {}: float = {}", { i(1, "0.0"), i(2, "1.0"), i(3, "name"), i(4, "0.0") })),
  s("export_enum",  fmt('@export_enum({}) var {}: int = 0', { i(1, '"Option A", "Option B"'), i(2, "name") })),
  s("onready",      fmt("@onready var {} = ${}", { i(1, "node_name"), i(2, "NodePath") })),
  s("setget", fmt([[
var {}: {}:
	get:
		return _{}
	set(value):
		_{} = value

var _{}: {}
]], { i(1, "name"), i(2, "Type"), rep(1), rep(1), rep(1), rep(2) })),
  s("tool", t("@tool")),

  -- Class structure
  s("cn",         fmt("class_name {}\nextends {}", { i(1, "ClassName"), i(2, "Node") })),
  s("class_name", fmt("class_name {}", { i(1, "ClassName") })),
  s("extends",    fmt("extends {}", { i(1, "Node") })),
  s("class",      fmt("class {}:\n\t{}", { i(1, "ClassName"), i(2, "pass") })),
  s("enum",       fmt("enum {} {{ {} }}", { i(1, "Name"), i(2, "VALUE_A, VALUE_B") })),

  -- Signals
  s("signal",      fmt("signal {}", { i(1, "signal_name") })),
  s("signal_args", fmt("signal {}({})", { i(1, "signal_name"), i(2, "arg: Type") })),
  s("emit",        fmt("{}.emit({})", { i(1, "signal_name"), i(2) })),
  s("connect",     fmt("{}.connect({})", { i(1, "signal_name"), i(2, "_on_signal_name") })),

  -- Control flow
  s("if",    fmt("if {}:\n\t{}", { i(1, "condition"), i(2, "pass") })),
  s("ife",   fmt("if {}:\n\t{}\nelse:\n\t{}", { i(1, "condition"), i(2, "pass"), i(3, "pass") })),
  s("elif",  fmt("elif {}:\n\t{}", { i(1, "condition"), i(2, "pass") })),
  s("for",   fmt("for {} in {}:\n\t{}", { i(1, "item"), i(2, "collection"), i(3, "pass") })),
  s("forr",  fmt("for {} in range({}):\n\t{}", { i(1, "i"), i(2, "10"), i(3, "pass") })),
  s("while", fmt("while {}:\n\t{}", { i(1, "condition"), i(2, "pass") })),
  s("match", fmt("match {}:\n\t{}:\n\t\t{}\n\t_:\n\t\t{}", { i(1, "value"), i(2, "pattern"), i(3, "pass"), i(4, "pass") })),

  -- Built-ins
  s("print",    fmt("print({})", { i(1) })),
  s("printe",   fmt("print_debug({})", { i(1) })),
  s("preload",  fmt('preload("{}")', { i(1, "res://") })),
  s("load",     fmt('load("{}")', { i(1, "res://") })),
  s("get_node", fmt('get_node("{}")', { i(1, "NodePath") })),
  s("assert",   fmt('assert({}, "{}")', { i(1, "condition"), i(2, "Assertion failed") })),
  s("await",    fmt("await {}", { i(1, "signal_or_coroutine") })),

  -- Tween
  s("tween", fmt([[
var tween := create_tween()
tween.tween_property({}, "{}", {}, {})
]], { i(1, "node"), i(2, "property:name"), i(3, "target_value"), i(4, "duration") })),

  -- Singleton pattern
  s("singleton", fmt([[
static var _instance: {}

static func get_instance() -> {}:
	return _instance

func _ready() -> void:
	_instance = self
]], { i(1, "ClassName"), rep(1) })),

}, { key = "gdscript" })
