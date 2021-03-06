-- ORCA for norns
--
-- its your bedtime
--
--         X
--
-- hundred rabbits
--
function unrequire(name)
  package.loaded[name] = nil
  _G[name] = nil
end

unrequire("timber/lib/timber_engine")
engine.name = "Timber"
Timber = require "timber/lib/timber_engine"
local music = require "musicutil"
local NUM_SAMPLES = 35
local keyb = hid.connect()
local keycodes = include("orca/lib/keycodes")
local transpose_table = include("orca/lib/transpose")
local tab = require 'tabutil'
local fileselect = require "fileselect"
local textentry = require "textentry"
local music = require 'musicutil'
local BeatClock = require 'beatclock'
local mode = #music.SCALES
local scale = music.generate_scale_of_length(60,music.SCALES[mode].name,16)
local midi_out_device 
local clk = BeatClock.new()
local notes_off_metro = metro.init()
local active_notes = {}
local keyinput = ""
local XSIZE = 101 
local YSIZE = 33  
local x_index = 1
local y_index = 1
local bar = false
local help = false
local field_grid = 1
local field_offset_y = 0
local field_offset_x = 0
local bounds_x = 25
local bounds_y = 8
local sc_ops = 0
local max_sc_ops = 6
local frame = 1
local ops = {}
local field = {}
field.cell = {}
field.cell.params = {}
field.active = {}
local vars = {}
local map = false
local main_menu = false
local load_menu = false
local projects = {}
local menu_index = 1
local menu_entries = {{'New', function() init() main_menu = false menu_index = 1 end}, 
              {'Load', function() main_menu = false load_menu = true end}, 
              {'Save', function() textentry.enter(ops.save_project, 'untitled' ) end}
}

local function all_notes_off(ch)
    for _, a in pairs(active_notes) do
      midi_out_device:note_off(a, nil, ch)
    end
  active_notes = {}
end

ops.load_project = function(pth)
  if string.find(pth, 'orca') ~= nil then
    saved = tab.load(pth)
    if saved ~= nil then
      print("data found")
      field = saved
      local name = string.sub(string.gsub(pth, '%w+/',''),2,-6) 
      softcut.buffer_read_mono(norns.state.data .. name .. '_buffer.aif', 0, 0, #ops.chars, 1, 1)
      params:read(norns.state.data .. name ..".pset")
      print ('loaded ' .. norns.state.data .. name .. '_buffer.aif')
      load_menu = false
      main_menu = false
    else
      print("no data")
    end
  end
end

ops.save_project = function(txt)
  if txt then
    tab.save(field, norns.state.data .. txt ..".orca")
    softcut.buffer_write_mono(norns.state.data..txt .."_buffer.aif",0,#ops.chars, 1)
    params:write(norns.state.data .. txt .. ".pset")
    print ('saved ' .. norns.state.data .. txt .. '_buffer.aif')
  else
    print("save cancel")
  end
end

ops.list =  {
  ["*"] = '*',
  [':'] = ':',
  ["'"] = "'",
  ['/'] = '/',
  ['\\']= '\\',
  ["A"] = 'A',
  ["B"] = 'B',
  ["C"] = 'C',
  ["D"] = 'D',
  ["E"] = 'E',
  ["F"] = 'F',
  -- ['G']
  ['H'] = 'H',
  ["I"] = 'I',
  ["J"] = 'J',
  ['K'] = 'K',
  ["L"] = 'L',
  ["M"] = 'M',
  ["N"] = 'N',
  ['O'] = 'O',
  ["P"] = 'P',
  -- ['Q']
  ["R"] = 'R',
  ["S"] = 'S',
  ['T'] = 'T',
  -- ['U']
  ["V"] = 'V',
  ["W"] = 'W',
  ["X"] = 'X',
  ['Y'] = 'Y',
  ["Z"] = 'Z'
}
ops.bangs ={
  ["E"] = 'E',
  ["W"] = 'W',
  ["S"] = 'S',
  ["N"] = 'N',
  ['Z'] = 'Z'
}
ops.names =  {
  ["*"] = 'bang',
  [':'] = 'midi',
  ["'"] = 'engine',
  ['/'] = 'softcut',
  ['\\']= 'r note',
  ["A"] = 'add',
  ["B"] = 'bounce',
  ["C"] = 'clock',
  ["D"] = 'delay',
  ["E"] = 'east',
  ["F"] = 'if',
  -- ['G']
  ['H'] = 'halt',
  ["I"] = 'increment',
  ["J"] = 'jumper',
  ['K'] = 'konkat',
  ["L"] = 'loop',
  ["M"] = 'modulo',
  ["N"] = 'north',
  ['O'] = 'offset',
  ["P"] = 'push',
  -- ['Q']
  ["R"] = 'random',
  ["S"] = 'south',
  ['T'] = 'track',
  -- ['U']
  ["V"] = 'variable',
  ["W"] = 'west',
  ["X"] = 'write',
  ['Y'] = 'jymper',
  ["Z"] = 'zoom'

}
ops.info = {
  ['*'] = 'Bangs neighboring operators.',
  [':'] = 'Midi 1-channel 2-octave 3-note 4-velocity 5-length',
  ["'"] = 'Engine 1-sample 2-pitch 3-pitch 4-level 5-pos',
  ['/'] = 'Softcut 1-plhead 2-rec 3-play 4-level 5-pos',
  ['\\']= 'Outputs random note within octave',
  ['='] = 'Sends a OSC message',
  ['A'] = 'Outputs the sum of inputs.',
  ['B'] = 'Bounces between two values based on the runtime frame.',
  ['C'] = 'Outputs a constant value based on the runtime frame.',
  ['D'] = 'Bangs on a fraction of the runtime frame.',
  ['E'] = 'Moves eastward, or bangs.',
  ['F'] = 'Bangs if both inputs are equal.',
  ['G'] = '',
  ['H'] = 'Stops southward operator from operating.',
  ['I'] = 'Increments southward operator.',
  ['J'] = 'Outputs the northward operator.',
  ['K'] = '',
  ['L'] = 'Loops a number of eastward operators.',
  ['M'] = 'Outputs the modulo of input.',
  ['N'] = 'Moves northward, or bangs.',
  ['O'] = 'Reads a distant operator with offset.',
  ['P'] = 'Writes an eastward operator with offset.',
  ['Q'] = '',
  ['R'] = 'Outputs a random value.',
  ['S'] = 'Moves southward, or bangs.',
  ['T'] = 'Reads an eastward operator with offset',
  ['U'] = '',
  ['V'] = 'Reads and writes globally available variable',
  ['W'] = 'Moves westward, or bangs.',
  ['X'] = 'Writes a distant operator with offset',
  ['Y'] = 'Outputs the westward operator',
  ['Z'] = 'Moves easwardly, respawns west on collision',
}
ops.ports = {
  [':'] = {{1, 0, 'input_op'}, {2, 0, 'input_op'}, {3, 0 , 'input_op'}, {4, 0 , 'input_op'}, {5, 0 , 'input_op'}},
  ["'"] = {{1, 0, 'input_op'}, {2, 0, 'input_op'}, {3, 0 , 'input_op'}, {4, 0 , 'input_op'}, {5,0, 'input_op'}},
  ['/'] = {{1, 0, 'input_op'}, {2, 0, 'input_op'}, {3, 0 , 'input_op'}, {4, 0 , 'input_op'}, {5, 0 , 'input_op'}, {6, 0 , 'input_op'}},
  ['\\']= {{1, 0, 'input'}, {-1, 0, 'input'}, {0, 1 , 'output_op'}},
  ['A'] = {{1, 0, 'input_op'}, {-1, 0, 'input_op'}, {0, 1 , 'output_op'}},
  ['B'] = {{1, 0, 'input'}, {-1, 0, 'input'}, {0, 1 , 'output'}},
  ['C'] = {{1, 0, 'input_op'}, {-1, 0, 'input'}, {0, 1 , 'output'}},
  ['D'] = {{1, 0, 'input_op'}, {-1, 0, 'input'}, {0, 1 , 'output'}},
  ['F'] = {{1, 0, 'input'}, {-1, 0, 'input'}, {0, 1 , 'output_op'}},
  ['H'] = {{0, 1, 'output'}},
  ['J'] = {{0, -1, 'input'}, {0, 1, 'output_op'}},
  ['K'] = {{-1, 0, 'input'}},
  ['L'] = {{-1, 0, 'input'}, {-2, 0, 'input'}},
  ['I'] = {{1, 0, 'input'}, {-1, 0, 'input'}, {0, 1 , 'output'}},
  ['O'] = {{-1, 0, 'input'}, {-2, 0, 'input'}, {0, 1 , 'input_op'}},
  ['M'] = {{-1, 0, 'input'}, {1, 0, 'input'}, {0, 1 , 'output'}},
  ['P'] = {{1, 0, 'input_op'}, {-1, 0, 'input'}, {-2, 0, 'input'}},
  ['T'] = {{-1,0, 'input_op'},  {-2, 0, 'input_op'},  {1, 0, 'input_op'}, {0, 1 , 'output_op'}},
  ['R'] = {{-1, 0, 'input'}, {1, 0, 'input'}, {0, 1 , 'output_op'}},
  ['X'] = {{1, 0, 'input_op'}, {-1, 0, 'input'}, {-2, 0 , 'input'}},
  ['V'] = {{-1,0, 'input_op'},  {1, 0, 'input_op'}},
  ['Y'] = {{-1, 0, 'input'}, {1, 0, 'output_op'}},
  ['W'] = {},
  ['S'] = {},
  ['E'] = {},
  ['N'] = {},
  ['Z'] = {},
  ['*'] = {},
}
ops.notes = {"C", "c", "D", "d", "E", "F", "f", "G", "g", "A", "a", "B"}
ops.chars = {'1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
ops.chars[0] = '0'


function ops.normalize(n)
  return n == 'e' and 'F' or n == 'b' and 'C' or n
end

function ops.transpose(n, o)
  if n == nil or n == 'null' then n = 'C' else n = tostring(n) end 
  if o == nil or o == 'null' then o = 0 end
  local note = ops.normalize(string.sub(transpose_table[n], 1, 1))
  local octave = util.clamp(ops.normalize(string.sub(transpose_table[n], 2)) + o,0,8)
  local value = tab.key(ops.notes, note)
  local id = util.clamp((octave * 12) + value, 0, 127)
  local real = id < 89 and tab.key(transpose_table, id - 45) or nil -- ??
  return {id, value, note, octave, real}
end

function ops:input(x,y, default)
  local value = string.lower(tostring(field.cell[y][x]))
  if value == '0' then 
    return 0
  elseif value ~= nil or value ~= 'null' then 
    return tab.key(ops.chars, value)
  else
    return false
  end
end 

function ops.is_op(x,y)
  x = util.clamp(x,0,XSIZE)
  y = util.clamp(y,0,YSIZE)
  if (field.cell[y][x] ~= 'null' and field.cell[y][x] ~= nil) then
    if (ops.list[string.upper(field.cell[y][x])] and field.cell.params[y][x].op) then
      if ops.list[string.upper(field.cell[y][x])] and field.cell.params[y][x].act == true then
        return true
      end
    end
  else
    return false
  end
end

function ops.is_bang(x,y)
  if (field.cell[y][x] ~= 'null' and field.cell[y][x] ~= nil) then
    if (ops.bangs[string.upper(field.cell[y][x])] and field.cell.params[y][x].op) then
      return true
    end
  else
    return false
  end
end

function ops.banged(x,y)
  if field.cell[y][x - 1] == '*' then -- or  ops.is_bang(x - 1, y) then
    return true
  elseif field.cell[y][x + 1] == '*' then --or ops.is_bang(x + 1, y) then
    return true
  elseif field.cell[y - 1][x] == '*' then --or ops.is_bang(x, y - 1) then 
    return true
  elseif field.cell[y + 1][x] == '*' then -- or ops.is_bang(x, y + 1) then 
    return true
  else
    return false
  end
end

function ops:active()
  if field.cell.params[self.y][self.x].op == true then
    if field.cell[self.y][self.x] == string.upper(field.cell[self.y][self.x]) then
      return true
    elseif field.cell[self.y][self.x] == string.lower(field.cell[self.y][self.x]) then
      return false
    end
  end
end

function ops:replace(i)
  field.cell[self.y][self.x] = i
end

function ops:shift(s, e)
  local data = field.cell[self.y][self.x + s]
  local params_data = field.cell.params[self.y][self.x + s]
  table.remove(field.cell[self.y], self.x + s)
  table.remove(field.cell.params[self.y], self.x + s)
  table.insert(field.cell[self.y], self.x + e, data)
  table.insert(field.cell.params[self.y], self.x + e, params_data)
end

function ops:cleanup()
  if ops.is_op(self.x, self.y) then self:clean_ports(ops.ports[string.upper(field.cell[self.y][self.x])]) end
  field.cell.params[self.y][self.x] = {op = true, lit = false, lit_out = false, act = true, cursor = false, dot_cursor = false, dot_port = false, dot = false, placeholder = nil}
  if field.cell.params[self.y+1][self.x].cursor == true then field.cell.params[self.y+1][self.x].cursor = false end
  if field.cell.params[self.y][self.x + 1].op == false then field.cell.params[self.y][self.x + 1].op = true end
  if field.cell.params[self.y + 1][self.x].lit_out == true then field.cell.params[self.y + 1][self.x].lit_out = false end

  -- specific ops cleanup
  if (field.cell[self.y][self.x] == 'P' or field.cell[self.y][self.x] == 'p') then
    local seqlen = tonumber(ops:input(self.x - 1, self.y)) or 1
    for i=0, seqlen do
      field.cell.params[self.y + 1][self.x + i].op = true
      field.cell.params[self.y + 1][self.x + i].lit = false
      field.cell.params[self.y + 1][self.x + i].cursor = false
      field.cell.params[self.y + 1][self.x + i].dot = false
    end
  elseif (field.cell[self.y][self.x] == 'T' or field.cell[self.y][self.x] == 't') then
    local seqlen = tonumber(ops:input(self.x - 1, self.y)) or 1
    field.cell.params[self.y+1][self.x].lit_out  = false
    for i=1, seqlen do
      field.cell.params[self.y][self.x + i].op = true
      field.cell.params[self.y][self.x + i].cursor = false
      field.cell.params[self.y][self.x + i].dot = false
    end
  elseif (field.cell[self.y][self.x] == 'K' or field.cell[self.y][self.x] == 'k') then
    local seqlen = tonumber(ops:input(self.x - 1, self.y)) or 1
    for i=1,seqlen do
      field.cell.params[self.y][self.x + i].dot = false
      field.cell.params[self.y][(self.x + i)].op = true
      field.cell.params[self.y][(self.x + i)].act = true
      field.cell.params[self.y + 1][(self.x + i)].act = true
    end
  elseif (field.cell[self.y][self.x] == 'L' or field.cell[self.y][self.x] == 'l') then
    local seqlen = tonumber(ops:input(self.x - 1, self.y)) or 1
    for i=1,seqlen do
      field.cell.params[self.y][self.x + i].dot = false
      field.cell.params[self.y][(self.x + i)].op = true
    end
  elseif (field.cell[self.y][self.x] == 'H' or field.cell[self.y][self.x] == 'h') then
    field.cell.params[self.y + 1][self.x].act = true
  elseif (field.cell[self.y][self.x] == 'X' or field.cell[self.y][self.x] == 'x') then
    local a = tonumber(field.cell[self.y][self.x - 2]) or 0 -- x
    local b = util.clamp(tonumber(field.cell[self.y][self.x - 1]) or 1, 1, 9) -- y
    field.cell.params[self.y + b][self.x + a].dot_cursor = false
    field.cell.params[self.y + b][self.x + a].cursor = false
    field.cell.params[self.y + b][self.x + a].placeholder = nil
  elseif (field.cell[self.y][self.x] == "'" or field.cell[self.y][self.x] == ':' or field.cell[self.y][self.x] == '/') then
    if field.cell[self.y][self.x] == '/' then sc_ops = util.clamp(sc_ops - 1,1,max_sc_ops) softcut.play(field.cell[self.y][self.x + 1]~= 'null' and field.cell[self.y][self.x + 1] or sc_ops,0) end
    if field.cell[self.y][self.x] == "'" then local sample = ops:input(self.x + 1, self.y) or 0 engine.noteOff(sample) end

  end 
end

function ops:erase(x,y)
  self.x = x
  self.y = y
  if self:active() then 
    self:cleanup() 
  end
  ops:remove_from_queue(self.x,self.y)  
  self:replace('null')
end

function ops:explode()
  self:replace('*')
  self:add_to_queue(self.x,self.y)
end

function ops:id(x, y)
  return tostring(x .. ":" .. y)
end

function ops:add_to_queue(x,y)
  x = util.clamp(x,1,XSIZE + 1)
  y = util.clamp(y,1,YSIZE + 1)
  field.active[ops:id(x,y)] = {x, y, field.cell[y][x]}
end

function ops.removeKey(t, k_to_remove)
  local new = {}
  for k, v in pairs(t) do
    new[k] = v
  end
  new[k_to_remove] = nil
  return new
end


function ops:remove_from_queue(x,y)
  self.x = x
  self.y = y
  field.active = ops.removeKey(field.active, ops:id(self.x,self.y))
end

function ops:exec_queue()
  frame = (frame + 1) % 999
  for k,v in pairs(field.active) do
    if k ~= nil then
    local x = field.active[k][1]
    local y = field.active[k][2]
    local op = field.active[k][3]
    if op ~= 'null' and ops.is_op(x,y) then
      ops[string.upper(op)](self, x, y, frame) 
    end
    end
  end
end

function ops:move(x,y)
  a = self.y + y
  b = self.x + x
  local collider = field.cell[a][b]
  -- collide rules
  if collider ~= 'null'  then
    if field.cell[a][b] ~= nil then
      if collider == '*' then
        ops:move_cell(b,a)
        if field.cell[self.y][self.x] == 'Z' then
          ops:move_cell(1,a)
          self:explode()
        end
        self:erase(self.x,self.y)
      elseif field.cell.params[a][b].op == false or (collider == '.' and field.cell.params[a][b].op == false) then
        ops:move_cell(b,a)
      elseif (
        (collider == '.' and field.cell.params[a][b].op == true)
        or
        collider == field.cell[self.y][self.x]
        or
        (ops:active() and ops.list[string.upper(field.cell[a][b])])
        or
        collider == tonumber(collider)
        or
        collider ~= ops.is_op(a,b)
        or
        ops.is_bang(a,b)
        )
      then
        if field.cell[self.y][self.x] == 'Z' then
          ops:move_cell(1,a)
        end
        self:explode()
      -- L fix
      elseif field.cell.params[a][b].op == false or (collider == '.' and field.cell.params[a][b].op == false ) then
        ops:move_cell(b,a)
        self:erase(self.x,self.y)
      end
    else
      self:explode()
    end
  else
    ops:move_cell(b,a)
  end
end

function ops:move_cell(x,y)
  field.cell[y][x] = field.cell[self.y][self.x]
  self:erase(self.x,self.y)
  ops:add_to_queue(x,y)
end

function ops:clean_ports(t, x1, y1)
  for i=1,#t do
    if t[i] ~= nil then
      for l=1,#t[i]-2 do
        local x = x1 ~= nil and x1 + t[i][l]  or self.x + t[i][l] 
        local y = y1 ~= nil and y1 + t[i][l+1] or self.y + t[i][l+1] 
        field.cell.params[self.y][self.x].lit = false
        if field.cell[y][x] ~= nil then
          if t[i][l + 2] == 'output' then
            field.cell.params[y][x].lit_out = false
            field.cell.params[y][x].dot_port = false
          elseif t[i][l + 2] == 'input' then
            field.cell.params[y][x].dot_port = false
          elseif t[i][l + 2] == 'input_op' then
            field.cell.params[y][x].op = true
            field.cell.params[y][x].dot_port = false
          elseif t[i][l + 2] == 'output_op' then
            field.cell.params[y][x].op = true
            field.cell.params[y][x].dot_port = false
            field.cell.params[y][x].lit_out = false
          end
        end
      end
    end
  end
end

function ops:spawn(t)
  for i=1,#t do
    for l= 1, #t[i] - 2 do
      local x = self.x + t[i][l]
      local y = self.y + t[i][l+1]
      local existing = field.cell[y][x] == ops.list[field.cell[y][x]] and field.cell[y][x] or nil
      local port_type = t[i][l + 2]

      -- draw frame
      if field.cell[self.y][self.x] ~= string.lower(field.cell[self.y][self.x]) then
        field.cell.params[self.y][self.x].lit = true
      elseif (field.cell[self.y][self.x] == "'" or field.cell[self.y][self.x]  == ':' or field.cell[self.y][self.x]  == '/') then
        field.cell.params[self.y][self.x].lit = true
      end

      -- draw inputs / outputs
      if field.cell[y][x] ~= nil then
        if port_type == 'output' then
          field.cell.params[y][x].lit_out = true
          field.cell.params[y][x].dot_port = true
        elseif port_type == 'input' then
          field.cell.params[y][x].dot_port = true
          
        elseif port_type == 'input_op' then
          field.cell.params[y][x].op = false
          field.cell.params[y][x].dot_port = true
          if existing ~= nil then
            ops:clean_ports(existing, x,y)
          else
          end
        elseif port_type == 'output_op' then
          field.cell.params[y][x].lit_out = true
          field.cell.params[y][x].op = false
          field.cell.params[y][x].dot_port = true
        end
      end
    end
  end
end
-----

ops["*"] = function(self, x,y,f)
  self.x = x 
  self.y = y 
  if field.cell.params[self.y][self.x].act == true then self:erase(self.x, self.y) end
end

ops.V = function (self,x,y,frame)
  self.name = 'V'
  self.y = y
  self.x = x
  local a = tonumber(ops:input(x - 1, y, 0))  ~= nil and tonumber(ops:input(x - 1, y, 0)) or 0
  local b = tonumber(ops:input(x + 1, y, 0)) ~= nil and tonumber(ops:input(x + 1, y, 0)) or 0
  if self:active() then
    self:spawn(ops.ports[self.name])
    if (b ~= 0 and vars[b] ~= nil and a == 0) then
      if vars[b] ~= nil then
       field.cell.params[y + 1][x].lit_out = true
       field.cell[y + 1][x] = vars[b] 
      end 
    elseif self:active() and b ~= 0 and  a ~= 0  then
      vars[a] = field.cell[y][x + 1]
    else 
      field.cell.params[y + 1][x].lit_out = false
    end
  elseif not self:active() then
    if ops.banged(x,y) then
    end
  end
end

ops.A = function (self,x,y,frame)
  self.name = 'A'
  self.y = y
  self.x = x
  local b = tonumber(ops:input(x + 1, y, 0)) ~= nil and tonumber(ops:input(x + 1, y, 0)) or 0
  local a = tonumber(ops:input(x - 1, y, 0))  ~= nil and tonumber(ops:input(x - 1, y, 0))  or 0
  local sum
  if (a ~= 0 or b ~= 0) then sum  = ops.chars[util.clamp(math.ceil((a+b)),0,#ops.chars)]
  else sum = 0 end
  if self:active() then
    self:spawn(ops.ports[self.name])
      field.cell[y+1][x] = sum
  elseif not self:active() then
    if ops.banged(x,y) then
      field.cell[y+1][x] = sum
    end
  end
end

ops.B = function (self, x,y, frame)
  self.name = 'B'
  self.y = y
  self.x = x
  local to = tonumber(ops:input(x + 1, y)) or 1
  local rate = tonumber(ops:input(x - 1, y)) or 1
  if to == 0 or to == nil then to = 1 end
  if rate == 0 or rate == nil then rate = 1 end
  local key = math.floor(frame / rate) % (to * 2)
  local val = key <= to and key or to - (key - to)
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y + 1][x] = ops.chars[val]
  elseif not self:active() then
    if ops.banged(x,y) then
      field.cell[y + 1][x] = ops.chars[val]
    end
  end
end

ops.C  = function (self, x, y, frame)
  self.name = 'C'
  self.y = y
  self.x = x
  local modulus = tonumber(ops:input(x + 1, y)) or 9
  local rate = tonumber(ops:input(x - 1, y)) or 1
  if modulus == 0 or modulus == nil then modulus = 1 end
  if rate == 0 or rate == nil then rate = 1 end
  local val = (math.floor(frame / rate) % modulus) + 1
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y+1][x] = ops.chars[val]
  elseif not self:active() then
    if ops.banged(x,y) then
      self:spawn(ops.ports[self.name])
      field.cell[y+1][x] = ops.chars[val]
    end
  end
end

ops.D  = function (self, x, y, frame)
  self.name = 'D'
  self.y = y
  self.x = x
  local modulus = tonumber(ops:input(x + 1, y)) -- only int
  local rate = tonumber(ops:input(x - 1, y)) -- only int
  if modulus == 0 then modulus = 1 end
  local val = (frame % (modulus or 9)) * (rate or 1)
  local out = (val == 0 or modulus == 1) and '*' or 'null'
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y+1][x] = out
  elseif not self:active() then
    if ops.banged(x,y) then
      self:spawn(ops.ports[self.name])
      field.cell[y+1][x] = out
    end
  end
end

ops.F = function(self, x,y)
  self.name = 'F'
  self.y = y
  self.x = x
  local b = tonumber(field.cell[y][x + 1])
  local a = tonumber(field.cell[y][x - 1])
  local val = a == b and '*' or 'null'
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y+1][x] = val
  elseif not self:active() then
    if ops.banged(x,y) then
      field.cell[y+1][x] = val
    end
  end
end

ops.H = function(self,x,y)
  self.name = 'H'
  self.y = y
  self.x = x
  local ports = {{0, 1 , 'output'}}
  local a = field.cell[y - 1][x]
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell.params[y + 1][x].act = false
    if ((field.cell[y + 1][x] == 'H' or field.cell[y + 1][x] ==  'h') and field.cell.params[y + 1][x].op) then
      field.cell.params[y + 2][x].act = true
    end
  elseif not self:active() then
    if ops.banged(x,y) then
      field.cell.params[y + 1][x].act = false
      if ((field.cell[y + 1][x] == 'H' or field.cell[y + 1][x] ==  'h') and field.cell.params[y + 1][x].op) then
        field.cell.params[y + 2][x].act = true
      end
    else
      field.cell.params[y + 1][x].act = true
    end
  end
end

ops.J = function(self, x,y)
  self.name = 'J'
  self.y = y
  self.x = x
  local a = field.cell[y - 1][x]
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y + 1][x] = a
  elseif not self:active() then
    if ops.banged(x,y) then
      field.cell[y + 1][x] = a
    end
  end
end

ops.I = function (self, x, y, frame)
  self.name = 'I'
  self.y = y
  self.x = x
  local a, b
  a = ops:input(x - 1, y, 0) 
  b = ops:input(x + 1, y, 9)
  a = tonumber(a) or 0
  b = tonumber(b) ~= tonumber(a) and tonumber(b) or tonumber(a) + 1
  if b < a then a,b = b,a end
  val = util.clamp((frame  % math.ceil(b)) + 1,a,b)
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y+1][x] = ops.chars[val]
  end
end

ops.W = function(self, x, y)
  self.name = 'W'
  self.x = x
  self.y = y
  if self:active() then
    ops:move(-1,0)
  elseif not self:active() then
    if ops.banged(x,y) then
      ops:move(-1,0)
    end
  end
end

ops.E = function (self, x, y)
  self.name = 'E'
  self.x = x
  self.y = y
  if self:active() then
    ops:move(1,0)
  elseif not self:active() then
    if ops.banged(x,y) then
      ops:move(1,0)
    end
  end
end

ops.N = function (self, x, y)
  self.name = 'N'
  self.x = x
  self.y = y
  if self:active() then
    ops:move(0,-1)
  elseif not self:active() then
    if ops.banged(x,y) then
      ops:move(0,-1)
    end
  end
end

ops.S = function(self, x, y)
  self.name = 'S'
  self.x = x
  self.y = y
  if self:active() then
    ops:move(0,1)
  elseif not self:active() then
    if ops.banged(x,y) then
      --ops:move(0,1)
    end
  end
end

ops.O = function (self, x, y)
  self.name = 'O'
  self.y = y
  self.x = x
  local a = (tonumber(field.cell[y][x - 2]) == 0 or tonumber(field.cell[y][x - 2]) == nil) and 1 or tonumber(field.cell[y][x - 2]) -- x
  local b = tonumber(field.cell[y][x - 1]) or 0 -- y
  local offsety = b + y
  local offsetx = a + x
  if self:active() then
    field.cell[y + 1][x] = field.cell[offsety][offsetx]
    for i= x - 1, x + 9 do
      for l = x - 1, x + 9 do
        if (i == y and l == x) then
        elseif (i == offsety  and l == offsetx) then
          field.cell.params[offsety][offsetx].dot_cursor = true
          field.cell.params[offsety][offsetx].op = false
        else
          field.cell.params[i][l].dot_cursor = false
          field.cell.params[i][l].op = true
        end
      end
    end
    self:spawn(ops.ports[self.name])
  end
end

ops.M  = function (self, x, y)
  self.name = 'M'
  self.y = y
  self.x = x
  local l = tonumber(ops:input(x - 1, y, 1)) or 1 -- only int
  local m = tonumber(ops:input(x + 1, y, 1)) or 1-- only int
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y+1][x] = string.sub(l % (m ~= 0 and m or 1), -1)
  elseif not self:active() then
  end
end

ops.P = function (self, x, y, frame)
  self.name = 'P'
  self.y = y
  self.x = x
  local length = tonumber(ops:input(x - 1, y, 0) ) ~= nil and tonumber(ops:input(x - 1, y, 1) ) or 1
  local pos = util.clamp(tonumber(ops:input(x - 2, y, 0)) ~= 0 and tonumber(ops:input(x - 2, y, 0)) or 1, 1, length)
  local val = field.cell[y][x + 1]
  length = util.clamp(length, 1, XSIZE)
  if self:active() then
    self:spawn(ops.ports[self.name])
    for i = 1,length do
      field.cell.params[y + 1][(x + i) - 1 ].dot = true
      field.cell.params[y + 1][(x + i) - 1 ].op = false
    end
    -- highliht pos
    for l= 1, length do
      if ((pos or 1)  % (length + 1)) == l then
        field.cell.params[y + 1][(x + l) - 1].cursor = true
      else
        field.cell.params[y + 1][(x + l) - 1].cursor = false
      end
    end
    field.cell[y+1][(x + ((pos or 1)  % (length+1))) - 1] = val
  end
  -- cleanups
  for i= length, #ops.chars do
    if field.cell.params[y + 1][(x + i)].dot then
      field.cell.params[y + 1][(x + i)].dot = false
      field.cell.params[y + 1][(x + i) ].op = true
      field.cell.params[y + 1][(x + i) ].cursor = false
    end
  end
end

ops.T = function (self, x, y, frame)
  self.name = 'T'
  self.y = y
  self.x = x
  local length = tonumber(ops:input(x - 1, y, 0) ) ~= nil and tonumber(ops:input(x - 1, y, 1) ) or 1
  length = util.clamp(length, 1, XSIZE)
  local pos = util.clamp(tonumber(ops:input(x - 2, y, 0)) ~= 0 and tonumber(ops:input(x - 2, y, 0)) or 1, 1, length)  
  local val = field.cell[self.y][self.x + util.clamp(pos,1,length)]
  if self:active() then
    field.cell.params[y+1][x].lit_out  = true
    self:spawn(ops.ports[self.name])
    for i = 1,length do
      field.cell.params[y][(x + i)].dot = true
      field.cell.params[y][(x + i)].op = false
    end
    -- highliht pos
    for l= 1, length do
      if pos == l then
        field.cell.params[y][(x + l)].cursor = true
      else
        field.cell.params[y][(x + l)].cursor = false
      end
    end
    field.cell[y+1][x] = val or '.'
  end
  -- cleanups
  for i= length+1, #ops.chars do
    field.cell.params[y][(x + i)].dot = false
    field.cell.params[y][(x + i)].op = true
    field.cell.params[y][(x + i)].cursor = false
  end
end

ops.K = function (self, x, y, frame)
  self.name = 'K'
  self.y = y
  self.x = x
  local length = tonumber(ops:input(x - 1, y, 0) ) ~= nil and tonumber(ops:input(x - 1, y, 0) ) or 0
  local offset = 1
  length = util.clamp(length,0,XSIZE)
  local l_start = x + offset
  local l_end = x + length
  if self:active() then
    self:spawn(ops.ports[self.name])
    if length - offset  == 0 then
      for i=2,length do
        field.cell.params[y][x + i].op = true
      end
    else
      for i = 1,length do
        local var = ops:input(x+i,y)
        field.cell.params[y][(x + i)].dot = true
        field.cell.params[y+1][(x + i)].dot_port = false
        field.cell.params[y][(x + i)].op = false
        field.cell.params[y][(x + i)].act = false
        field.cell.params[y+1][(x + i)].lit_out = false
        field.cell.params[y][(x + i)].lit = false
        if vars[var] ~= nil then
          field.cell.params[y+1][(x + i)].op = false
          field.cell.params[y + 1][(x + i)].act = false
          field.cell.params[y+1][(x + i)].lit_out = false
          field.cell.params[y+2][(x + i)].lit_out = false
          field.cell.params[y+1][(x + i)].lit = false
          field.cell[y+1][(x + i)] = vars[var]
        end
      end
      field.cell.params[y+1][x].dot_port = false
      field.cell.params[y+1][length + 1].dot_port = false
    end
  end
  -- cleanups
  if length < #ops.chars then
    for i= length == 0 and length or length+1, #ops.chars do
        field.cell.params[y][util.clamp((x + i),1,XSIZE)].dot = false
        field.cell.params[y][util.clamp((x + i),1,XSIZE)].op = true
        field.cell.params[y+1][util.clamp((x + i),1,XSIZE)].act = true
    end
  end
end
ops.L = function (self, x, y, frame)
  self.name = 'L'
  self.y = y
  self.x = x
  local length = tonumber(ops:input(x - 1, y, 0) ) ~= nil and tonumber(ops:input(x - 1, y, 0) ) or 0
  local rate = (tonumber(ops:input(x - 2, y, 0) ) == nil or tonumber(ops:input(x - 2, y, 0) ) == 0) and 1 or tonumber(ops:input(x - 2, y, 0) )
  local offset = 1
  length = util.clamp(length,0,XSIZE)
  local l_start = x + offset
  local l_end = x + length
  if self:active() then
    self:spawn(ops.ports[self.name])
    if length - offset  == 0 then
      for i=2,length do
        field.cell.params[y][x + i].op = true
      end
    else
      for i = 1,length do
        field.cell.params[y][(x + i)].dot = true
        field.cell.params[y][(x + i)].op = false
        field.cell.params[y+1][(x + i)].lit_out = false
        field.cell.params[y][(x + i)].lit = false
      end
    end
  end
  if frame % rate == 0 and length ~= 0 then
    self:shift(offset, length)
  end
  -- cleanups
  if length < #ops.chars then
    for i= length == 0 and length or length+1, #ops.chars do
        field.cell.params[y][(x + i)].dot = false
        field.cell.params[y][(x + i)].op = true
    end
  end
end

ops.R = function (self, x,y,frame)
  self.name = 'R'
  self.y = y
  self.x = x
  local a, b
  a = ops:input(x - 1, y, 1) 
  b = ops:input(x + 1, y, 9)
  a = util.clamp(tonumber(a) or 1,0,#ops.chars)
  b = util.clamp(tonumber(b) or 9,1,#ops.chars)
  if b == 27 and a == 27 then a = math.random(#ops.chars) b = math.random(#ops.chars) end -- rand 
  if b < a then a,b = b,a end
  if self:active() then
    self:spawn(ops.ports[self.name])
    field.cell[y+1][x] = ops.chars[math.random((a or 1),(b or 9))]
  end
end

ops.X = function(self, x,y)
  self.name = 'X'
  self.y = y
  self.x = x
  local a = tonumber(ops:input(x - 2, y)) or 0 -- x
  local b = util.clamp(ops:input(x - 1, y) or 1, 1, #ops.chars) -- y
  local offsety = b + y
  local offsetx = a + x
  if self:active() then
    self:spawn(ops.ports[self.name])
    --if frame % 1 == 0 then
      if field.cell[y][x+1] ~= 'null' then
        field.cell[util.clamp(offsety,1, #ops.chars)][offsetx] = field.cell[y][x+1]
         ops:add_to_queue(offsetx,util.clamp(offsety,1, #ops.chars))
        field.cell.params[util.clamp(offsety,1, #ops.chars)][offsetx].placeholder = field.cell[y][x+1]
        field.cell.params[util.clamp(offsety,1, #ops.chars)][offsetx].dot_cursor = false
      elseif field.cell[y][x+1] == 'null' then
        field.cell.params[util.clamp(offsety,1, #ops.chars)][offsetx].dot_cursor = true
      end
      for i= y,y+#ops.chars do
        for l = x, x+#ops.chars do
          if (i == y and l == x) then
          elseif (i == offsety and l == offsetx) then
            field.cell.params[i][l].cursor = true
          else
            field.cell.params[i][l].cursor = false
            field.cell.params[i][l].dot_cursor = false
            field.cell.params[i][l].lit = false
            field.cell.params[i][l].placeholder = nil
          end
        end
      end
    end
  --end
end

ops.Y = function(self, x,y)
  self.name = 'Y'
  self.y = y
  self.x = x
  local a = field.cell[y][x - 1] ~= nil and field.cell[y][x - 1] or 'null'
  if self:active() then
    self:spawn(ops.ports[self.name])
    if field.cell[y][x + 1] == 'null' or field.cell[y][x + 1] ~= ops.list[string.upper(field.cell[y][x + 1])] then
      field.cell[y][x + 1] = a
    else
    end
  elseif not self:active() then
    if field.cell[y+1][x] == '*' or ops.is_bang(x,y+1)  then
      field.cell[y][x+1] = a
    elseif field.cell[y-1][x] == '*' or ops.is_bang(x,y-1) then
      field.cell[y][x+1] = a
    end
  end
end

ops.Z = function (self, x, y)
  self.name = 'Z'
  self.x = x
  self.y = y
  if self:active() then
    ops:move(1,0)
  else
  end
end

ops["'"] = function (self, x,y,frame)
  self.name = "'"
  self.y = y
  self.x = x
  self:spawn(ops.ports[self.name])
  local sample = util.clamp(tonumber(ops:input(x + 1, y)) ~= nil and tonumber(ops:input(x + 1, y)) or 0,0,#ops.chars)
  local octave =  util.clamp(tonumber(ops:input(x + 2, y)) ~= nil and tonumber(ops:input(x + 2, y)) or 0,0,8)
  local vel =  util.clamp(tonumber(ops:input(x + 4, y)) ~= nil and tonumber(ops:input(x + 4, y)) or 33,0,#ops.chars)
  local start =  util.clamp(tonumber(ops:input(x + 5, y)) ~= nil and tonumber(ops:input(x + 5, y)) or 0,0,16)
  if octave == nil or octave == 'null' then octave = 0 end
  local transposed = ops.transpose(ops.chars[ops:input(x + 3, y)], octave )
  local oct = transposed[4]
  local n = math.floor(transposed[1])
  local velocity = math.floor((vel / #ops.chars) * 127)
  local length = params:get("end_frame_" .. sample)
  local start_pos = util.clamp(((start / #ops.chars)*2) * length, 0, length)
  params:set("start_frame_" .. sample,start_pos )
  if ops.banged(x,y) then
    field.cell.params[y][x].lit_out = false
    engine.noteOff(sample)
    engine.noteOn(sample, sample, music.note_num_to_freq(n), velocity)
  else
    field.cell.params[y][x].lit_out = true
    if frame % ( #ops.chars  * 4 )== 0 then engine.noteOff(sample) end
  end
end

ops['/'] = function (self, x,y,frame)
  self.name = '/'
  self.y = y
  self.x = x
  self:spawn(ops.ports[self.name])
  local num = sc_ops + 1
-- bang resets playhead to pos 
  local playhead = util.clamp(tonumber(field.cell[y][x + 1]) ~= 0 and  tonumber(field.cell[y][x + 1])  or sc_ops,1,max_sc_ops)
  local rec = tonumber(field.cell[y][x + 2]) or 0 -- rec 0 - off 1 - 9 on + rec_level
  local play = tonumber(field.cell[y][x + 3]) or 0 -- play 0 - stop  1 - 5 / fwd  6 - 9 rev
  local l =  util.clamp(tonumber(ops:input(x + 4, y)) ~= nil and tonumber(ops:input(x + 4, y)) or 0,0,#ops.chars) -- level 1-z
  local r =  util.clamp(tonumber(ops:input(x + 5, y)) ~= nil and tonumber(ops:input(x + 5, y)) or 0,0,#ops.chars) -- rate  1-z
  local p =  util.clamp(tonumber(ops:input(x + 6, y)) ~= nil and tonumber(ops:input(x + 6, y)) or 0,0,#ops.chars) -- pos  1-z 
  local pos = util.round((p / #ops.chars) * #ops.chars, 0.1)
  local level = util.round((l / #ops.chars) * 1, 0.1)
  local rate = util.round((r / #ops.chars) * 2, 0.1)
  if rec >= 1 then 
    softcut.rec_level(playhead, rec/9) 
    field.cell.params[y][x].lit_out = true 
  else 
    field.cell.params[y][x].lit_out = false 
    end
  if play > 5 then
    rate = -rate 
  end
  if play > 0 then
    softcut.play(playhead,play)
    softcut.rec(playhead,rec)
    softcut.rate(playhead,rate)
    softcut.level(playhead, level)
  else
    softcut.play(playhead,play)
  end
  if ops.banged(x,y) then
    field.cell.params[y][x].lit_out = false
    if play ~= 0 then
      softcut.position(playhead,pos)
    end
  else 
    field.cell.params[y][x].lit_out = true
  end
end

ops[':'] = function (self, x,y,frame)
  self.name = ':'
  self.y = y
  self.x = x
  self:spawn(ops.ports[self.name])
  local note = 'C'
  local channel = util.clamp(tonumber(ops:input(x + 1, y)) ~= nil and tonumber(ops:input(x + 1, y)) or 0,0,16)
  local octave =  util.clamp(tonumber(ops:input(x + 2, y)) ~= nil and tonumber(ops:input(x + 2, y)) or 0,0,8)
  local vel =  util.clamp(tonumber(ops:input(x + 4, y)) ~= nil and tonumber(ops:input(x + 4, y)) or 0,0,16)
  local length =  util.clamp(tonumber(ops:input(x + 5, y)) ~= nil and tonumber(ops:input(x + 5, y)) or 0,0,16)
  if octave == nil or octave == 'null' then octave = 0 end
  local transposed = ops.transpose(ops.chars[ops:input(x + 3, y)], octave )
  local oct = transposed[4]
  local n = math.floor(transposed[1])
  local velocity = math.floor((vel / 16) * 127)
  if ops.banged(x,y) then
    all_notes_off(channel)
    field.cell.params[y][x].lit_out = false
    midi_out_device:note_on(n, velocity, channel)
    table.insert(active_notes, n)
    notes_off_metro:start((60 / clk.bpm / clk.steps_per_beat / 4) * length, 1)
  else
    field.cell.params[y][x].lit_out = true
  end
end

ops['\\'] = function (self, x,y,frame)
  self.name = '\\'
  self.y = y
  self.x = x
  local rate = tonumber(ops:input(x - 1, y)) == 0 and 1 or tonumber(ops:input(x - 1, y)) or 1
  local scale = tonumber(ops:input(x + 1, y)) == 0 and 60 or tonumber(ops:input(x + 1, y)) or 60
  local mode = util.clamp(scale, 1, #music.SCALES)
  local scales = music.generate_scale_of_length(60,music.SCALES[mode].name,12)
  if self:active() then
    self:spawn(ops.ports[self.name])
    if frame % rate == 0 then
      field.cell[y+1][x] =  ops.notes[util.clamp(scales[math.random(#scales)] - 60, 1, 12)]
    end
  end
end

function ops:frame_count()
  ops:exec_queue()
end

function init()
  for y = 0,YSIZE + YSIZE do
    field.cell[y] = {}
    field.cell.params[y] = {}
    for x = 0,XSIZE + XSIZE do
      table.insert(field.cell[y], 'null')
      table.insert(field.cell.params[y], {op = true, lit = false, lit_out = false, act = true, cursor = false, dot_cursor = false, dot_port = false, dot = false, placeholder = nil})
    end
  end
  params:add_trigger('save_p', "save project" )
  params:set_action('save_p', function(x) textentry.enter(ops.save_project, 'untitled' ) end)
  params:add_file('load_p', "load project")
  params:set_action('load_p', function(x) ops.load_project(x) end)
  params:add_trigger('reset', "reset" )
  params:set_action('reset', function(x) init() end)

  softcut.reset()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  for i=1,max_sc_ops do
    softcut.level(i,1)
    softcut.level_input_cut(1, i, 1.0)
    softcut.level_input_cut(2, i, 1.0)
    softcut.pan(i, 0.5)
    softcut.play(i, 0)
    softcut.rate(i, 1)
    softcut.loop_start(i, 0)
    softcut.loop_end(i, #ops.chars + 1)
    softcut.loop(i, 0)
    softcut.rec(i, 0)
    softcut.fade_time(i,0.01)
    softcut.level_slew_time(i,0)
    softcut.rate_slew_time(i,0.01)
    softcut.rec_level(i, 1)
    softcut.pre_level(i, 1)
    softcut.position(i, 0)
    softcut.buffer(i,1)
    softcut.enable(i, 1)
    softcut.filter_dry(i, 1);
    softcut.filter_fc(i, 0);
    softcut.filter_lp(i, 0);
    softcut.filter_bp(i, 0);
    softcut.filter_rq(i, 0);
  end
  redraw_metro = metro.init(function(stage) redraw() end, 1/30)
  redraw_metro:start()
  clk.on_step = function() ops:exec_queue() end
  clk:add_clock_params()
  params:set("bpm", 120)
  clk:start()
  notes_off_metro.event = all_notes_off
  params:add_separator()


  Timber.add_params()
  for i = 0, NUM_SAMPLES - 1 do
    local extra_params = {
      {type = "option", id = "launch_mode_" .. i, name = "Launch Mode", options = {"Gate", "Toggle"}, default = 1, action = function(value)
        Timber.setup_params_dirty = true
      end},
    }
    params:add_separator()
    Timber.add_sample_params(i, true, extra_params)
    params:set("play_mode_" .. i, 4) -- set all to 1-shot 
  end



  params:add_separator()
  midi_out_device = midi.connect(1)
  midi_out_device.event = function() end
  params:add{type = "number", id = "midi_out_device", name = "midi out device",
  min = 1, max = 4, default = 1,
  action = function(value) midi_out_device = midi.connect(value) end}
end

local function get_key(code, val, shift)
  if keycodes.keys[code] ~= nil and val == 1 then
    if (shift) then
      if keycodes.shifts[code] ~= nil then
        return(keycodes.shifts[code])
      else
        return(keycodes.keys[code])
      end
    else
      return(string.lower(keycodes.keys[code]))
    end
  elseif keycodes.cmds[code] ~= nil and val == 1 then
    if (code == hid.codes.KEY_ENTER) then
      -- enter 
    end
  end
end

local function update_offset()
    if x_index < bounds_x + (field_offset_x - 24)  then 
      field_offset_x =  util.clamp(field_offset_x - 1,0,XSIZE - field_offset_x) 
    elseif x_index > field_offset_x + 25  then 
      field_offset_x =  util.clamp(field_offset_x + 1,0,XSIZE - bounds_x) 
    end
    if y_index  > field_offset_y + (bar and 7 or 8)   then 
        field_offset_y =  util.clamp(field_offset_y + 1,0,YSIZE - bounds_y) 
      elseif y_index < bounds_y + (field_offset_y - 7)  then 
      field_offset_y = util.clamp(field_offset_y - 1,0,YSIZE - bounds_y)
    end
end


function keyb.event(typ, code, val)
    --print("hid.event ", typ, code, val)
  if ((code == hid.codes.KEY_LEFTSHIFT or code == hid.codes.KEY_RIGHTSHIFT) and (val == 1 or val == 2)) then
    shift  = true;
  elseif (code == hid.codes.KEY_LEFTSHIFT or code == hid.codes.KEY_RIGHTSHIFT) and (val == 0) then
    shift = false;
  elseif (code == hid.codes.KEY_BACKSPACE or code == hid.codes.KEY_DELETE) then
    ops:erase(x_index,y_index)
  elseif (code == hid.codes.KEY_LEFT) and (val == 1) then
    x_index = util.clamp(x_index -1,1,XSIZE)
    update_offset()
  elseif (code == hid.codes.KEY_RIGHT) and (val == 1) then
    x_index = util.clamp(x_index + 1,1,XSIZE)
    update_offset()
  elseif (code == hid.codes.KEY_DOWN) and (val == 1) then
    if (main_menu or load_menu) then 
      menu_index = util.clamp(menu_index + 1 ,1,main_menu and #menu_entries or #projects)
    else
      y_index = util.clamp(y_index + 1,1,YSIZE)
      update_offset()
    end
  elseif (code == hid.codes.KEY_UP) and (val == 1) then
    if (main_menu or load_menu) then 
      menu_index = util.clamp(menu_index - 1 ,1,main_menu and #menu_entries or #projects)
    else
      y_index = util.clamp(y_index - 1 ,1,YSIZE)
      update_offset()
  end
  elseif (code == hid.codes.KEY_TAB and val == 1) then
    bar = not bar
  elseif (code == 41 and val == 1) then
    help = not help
  -- bypass crashes  -- 2do F1-F12 (59-68, 87,88)
  elseif (code == 26 and val == 1) then
    field_grid = util.clamp(field_grid - 1, 1, 8)
  elseif (code == 27 and val == 1) then
    field_grid = util.clamp(field_grid + 1, 1, 8)
  elseif (code == hid.codes.KEY_102ND and val == 1) then
  elseif (code == hid.codes.KEY_ESC and val == 1) then
    if not load_menu then main_menu = not main_menu end
    if load_menu then  main_menu = true load_menu = false menu_index = 2 end
  elseif (code == hid.codes.KEY_ENTER and val == 1) then
    if main_menu then
        menu_entries[menu_index][2]()
        menu_index = 1
    elseif load_menu then
      print(menu_index)
        local project_path = norns.state.data .. projects[menu_index] .. '.orca'
        ops.load_project(project_path)
      end
  elseif (code == hid.codes.KEY_LEFTALT and val == 1) then
  elseif (code == hid.codes.KEY_RIGHTALT and val == 1) then
  elseif (code == hid.codes.KEY_LEFTCTRL and val == 1) then
  elseif (code == hid.codes.KEY_RIGHTCTRL and val == 1) then
  elseif (code == hid.codes.KEY_DELETE and val == 1) then
  elseif (code == hid.codes.KEY_CAPSLOCK and val == 1) then
     map = not map
  elseif (code == hid.codes.KEY_NUMLOCK and val == 1) then
  elseif (code == hid.codes.KEY_SCROLLLOCK and val == 1) then
  elseif (code == hid.codes.KEY_SYSRQ and val == 1) then
  elseif (code == hid.codes.KEY_HOME and val == 1) then
  elseif (code == hid.codes.KEY_PAGEUP and val == 1) then
  elseif (code == hid.codes.KEY_RIGHTCTRL and val == 1) then
  elseif (code == hid.codes.KEY_DELETE and val == 1) then
  elseif (code == hid.codes.KEY_END and val == 1) then
  elseif (code == hid.codes.KEY_PAGEUP and val == 1) then
  elseif (code == hid.codes.KEY_PAGEDOWN and val == 1) then
  elseif (code == hid.codes.KEY_INSERT and val == 1) then
  elseif (code == hid.codes.KEY_END and val == 1) then
  elseif (code == hid.codes.KEY_LEFTMETA and val == 1) then
  elseif (code == hid.codes.KEY_RIGHTMETA and val == 1) then
  elseif (code == hid.codes.KEY_COMPOSE and val == 1) then
  elseif (code == 119 and val == 1) then
  elseif ((code == 88 or code == 87) and val == 1) then
  elseif (code == hid.codes.KEY_SPACE) and (val == 1) then
    if clk.playing then
      clk:stop()
      engine.noteKillAll()
      for i=1,max_sc_ops do
        softcut.play(i,0)
      end
    else
      frame = 0
      clk:start()
    end
  else
    if val == 1 then
      keyinput = get_key(code, val, shift)
      if ops.is_op(x_index,y_index) then
        ops:erase(x_index,y_index)
      elseif ops.list[string.upper(keyinput)] == 'H' or ops.list[string.upper(keyinput)] == 'h' then
      elseif ops.is_op(x_index, y_index - 1) then
      elseif ops.is_op(x_index,y_index + 1) then
        if ops.list[string.upper(keyinput)] == keyinput then
          -- remove southward op if new one have  outputs
          for i = 1,#ops.ports[string.upper(keyinput)] do
            if ops.ports[string.upper(keyinput)][i][2] == 1 then
              ops:erase(x_index,y_index + 1)
            else
              ops:erase(x_index,y_index)
            end
          end
        end 
      elseif (ops.is_op(x_index,y_index - 1) and tonumber(field.cell[y_index][x_index])) then
      end
      if keyinput == '/' then 
        if sc_ops == max_sc_ops then  
        else
          sc_ops = sc_ops + 1 
          field.cell[y_index][x_index] = keyinput
          ops:add_to_queue(x_index,y_index)
        end
      else
        field.cell[y_index][x_index] = keyinput
        ops:add_to_queue(x_index,y_index)
      end
    end
  end
end

local function draw_op_frame(x,y)
  screen.level(4)
  screen.rect((x * 5)-5, ((y*8) - 5) - 3, 5,8)
  screen.fill()
end

local function draw_op_out(x,y)
  if field.cell.params[y][x].act then
    screen.level(1)
    screen.rect((x * 5)-5, ((y*8) - 5) - 3, 5,8)
    screen.fill()
  end
end

local function draw_op_cursor(x,y)
  screen.level(1)
  screen.rect((x * 5)-5, ((y*8) - 5) - 3, 5,8)
  screen.fill()
end


local function draw_grid()
  screen.font_face(25)
  screen.font_size(6)
  for y= 1, bounds_y do
    for x = 1,bounds_x do
      local y = y + field_offset_y
      local x = x + field_offset_x
      if field.cell.params[y][x].lit then
        draw_op_frame(x - field_offset_x,y - field_offset_y)
      end
      if field.cell.params[y][x].cursor then
        draw_op_cursor(x - field_offset_x,y - field_offset_y)
      end
      if field.cell.params[y][x].lit_out then
        draw_op_out(x - field_offset_x,y - field_offset_y)
      end
      -- levels
      if field.cell[y][x] ~= 'null' then
        if ops.is_op(x,y) then
          screen.level(15)
        elseif field.cell.params[y][x].lit then
          screen.level(12)
        elseif field.cell.params[y][x].cursor then
          screen.level(12)
        elseif field.cell.params[y][x].lit_out then
          screen.level(12)
        elseif field.cell.params[y][x].dot_port then
          screen.level(9)
        elseif field.cell.params[y][x].dot_cursor then
          screen.level(12)
        elseif field.cell.params[y][x].dot then
          screen.level(5)
        else
          screen.level(3)
        end
      elseif field.cell[y][x] == 'null' then
        if field.cell.params[y][x].dot_port then
          screen.level(9)
        elseif field.cell.params[y][x].dot_cursor then
          screen.level(12)
        elseif field.cell.params[y][x].dot then
          screen.level(5)
        elseif field.cell.params[y][x].placeholder ~= nil then
          screen.level(12)
        else
          screen.level(1)
        end
      end
      screen.move(((x - field_offset_x) * 5) - 4 , ((y - field_offset_y )* 8) - (field.cell[y][x] and 2 or 3))
      --
      if field.cell[y][x] == 'null' or field.cell[y][x] == nil then
        if field.cell.params[y][x].dot_port then
          screen.text('.')
        elseif field.cell.params[y][x].dot_cursor then
          screen.text('.')
        elseif field.cell.params[y][x].dot then
          screen.text('.')
        elseif field.cell.params[y][x].placeholder ~= nil then
          screen.text(field.cell.params[y][x].placeholder)
        else
          screen.text( (x % field_grid == 0 and y % util.clamp(field_grid - 1,1,8) == 0) and  '.' or '')
        end
      else
        screen.text(field.cell[y][x])
      end
      screen.stroke()
    end
  end
end

local function draw_cursor(x,y)
  x_pos = ((x * 5) - 5) 
  y_pos = ((y * 8) - 8)
  if field.cell[y][x] == 'null' then
  screen.level(2)
  screen.rect(x_pos,y_pos,5,8)
  screen.fill()
    screen.move(x_pos,y_pos+6)
    screen.level(14)
    screen.font_face(0)
    screen.font_size(8)
    screen.text('@')
    screen.stroke()
  elseif field.cell[y][x] ~= 'null'  then
    screen.level(15)
    screen.rect(x_pos,y_pos,5,8)
    screen.fill()
    screen.move(x_pos + 1,y_pos+6)
    screen.level(1)
    screen.font_face(25)
    screen.font_size(6)
    screen.text(field.cell[y][x])
    screen.stroke()
  end
end

local function draw_bar()
  screen.level(0)
  screen.rect(0,56,128,8)
  screen.fill()
  screen.level(15)
  screen.move(2,63)
  screen.font_face(25)
  screen.font_size(6)
  screen.text(frame .. 'f')
  screen.stroke()
  screen.move(40,63)
  screen.text_center(field.cell[y_index][x_index] and ops.names[string.upper(field.cell[y_index][x_index])] or 'empty')
  screen.stroke()
  screen.move(75,63)
  screen.text(params:get("bpm") .. (frame % 4 == 0 and ' *' or ''))
  screen.stroke()
  screen.move(123,63)
  screen.text_right(x_index .. ',' .. y_index)
  screen.stroke()
end



--- wip 

local function draw_menu() 
  screen.clear()
  for i=1,#menu_entries do
    screen.level(menu_index == i and 9 or 4)
    screen.move(5, (i * 10) + 20)
    screen.text(menu_entries[i][1])
    screen.stroke()
  end
end


local function list_projects() 
  local l = util.scandir(norns.state.data)
  local projects = {}
  for i = 1,#l do
    local name = tab.split(l[i], '.')
    if name[2] == 'orca' then
      table.insert(projects, name[1])
    end
  end
  return projects
end


local function draw_projects_list()
  screen.clear()
  screen.font_face(0)
  screen.font_size(8)
  projects = list_projects()
  for i=1,#projects do
    screen.level(menu_index == i and 9 or 4)
    screen.move(5, (i * 10) + 20)
    screen.text(projects[i])
    screen.stroke()
  end
end

local function draw_help()
  if ops.info[string.upper(field.cell[y_index][x_index])] then
    screen.level(15)
    screen.rect(0,29,128,25)
    screen.fill()
    screen.level(0)
    screen.rect(1,30,126,23)
    screen.fill()
    if bar then
      screen.level(15)
      screen.move(36,53)
      screen.line_rel(4,4)
      screen.move(44,53)
      screen.line_rel(-4,4)
      screen.stroke()
      screen.level(0)
      screen.move(37,54)
      screen.line_rel(6,0)
      screen.stroke()
    end
    screen.font_face(25)
    screen.font_size(6)
    if ops.info[string.upper(field.cell[y_index][x_index])] then
      local s = ops.info[string.upper(field.cell[y_index][x_index])]
      local description = tab.split(s, ' ')
      screen.level(9)
      screen.move(3,38)
      local y = 40
      for i = 1, #description do
        screen.text(description[i] .. " ")
        if i == 4 or i == 9 then
          y = y + 8
          lenl = 0
          screen.move(3,y)
        end
      end
      screen.stroke()
    end
  else
  end
end

local function draw_map()
    -- window
  screen.level(15)
  screen.rect(4,5,120,55)
  screen.fill()
  screen.level(0)
  screen.rect(5,6,118,53)
  screen.fill()
    
  for y = 1, YSIZE do
    for x = 1, XSIZE do
      if field.cell[y][x] ~= 'null' then
      screen.level(1)
      screen.rect(((x / XSIZE ) * 114) + 5, ((y / YSIZE) * 48) + 7, 3,3 )
      screen.fill()
      end
      if field.cell.params[y][x].lit then
      screen.level(4)
      screen.rect(((x / XSIZE ) * 114) + 5, ((y / YSIZE) * 48) + 7, 3,3 )
      screen.fill()
      end
    end
  end
  screen.level(2)
  screen.rect((((util.clamp(x_index,1,78) / XSIZE) ) * 114) + 5, ((util.clamp(y_index,2,28) / YSIZE) * 48) + 5, (bounds_x / XSIZE) * 114 ,(bounds_y / YSIZE) * 48 )
  screen.stroke()
  screen.level(15)
  screen.rect(((x_index / XSIZE ) * 114) + 5, ((y_index / YSIZE) * 48) + 7, 1,1 )
  screen.fill()
end

function enc(n,d)
  if not main_menu or not load_menu then
    if n == 2 then
     x_index = util.clamp(x_index + d, 1, XSIZE)
    elseif n == 3 then
     y_index = util.clamp(y_index + d, 1, YSIZE)
    end
    update_offset()
  end
end

function redraw()
  screen.clear()
  if main_menu then
    draw_menu()
  elseif load_menu then
    draw_projects_list()
  else
    draw_grid()
    draw_cursor(util.clamp(x_index - field_offset_x,1,XSIZE), util.clamp(y_index - field_offset_y, 1, YSIZE))
    if bar then draw_bar() else  end
    if help then draw_help() else end
    if map then draw_map() else end
  end
  screen.update()
end
