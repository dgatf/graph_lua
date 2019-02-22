--[[
      rpmGraph v0.1

       22/02/2019

    
  Lua script for radios X7/X9 with openTx 2.2

  Shows a graph of rpm over time

]]--

-- Global variables

local refresh = 0
local config = {radio, field, field2, mode, min, max, duration}
local graphData = {}
local display = {['x7'] = {x = 128, y = 64, colWidth = 64, margin = 1, colLen = {6, 5, 3}},
                 ['x9'] = {x = 212, y = 64, colWidth = 71, margin = 2, colLen = {7, 6, 4}}}

-- Fifo list

local List = {}

    function List.new ()
      return {first = 0, last = -1}
    end
    
    function List.enqueue (list, value)
      local last = list.last + 1
      list.last = last
      list[last] = value
    end
    
    function List.dequeue (list)
      local first = list.first
      if first > list.last then error("list is empty") end
      local value = list[first]
      list[first] = nil
      list.first = first + 1
      return value
    end
    

-- Read line function

local function readLine(configFile)
  local lineString = ''
  local char
  repeat
    char = io.read(configFile,1)
    if char ~='\n' then lineString = lineString .. char end
  until char == '\n' or char == ''
  if char == '' then eof = true else eof = false end
  return lineString, eof
end

-- Read config function

local function readConfig(configFile)
  local configType, lineString, eof
    config.field,eof = readLine(configFile)
    config.field,eof = readLine(configFile)
    config.mode,eof = readLine(configFile)
    config.field,eof = readLine(configFile)
    config.mode,eof = readLine(configFile)
    config.duration,eof = readLine(configFile)
    if eof then 
      config.field = 'RPM'
      config.field2 = 'VFAS'
      config.mode = 0
      config.min = 0
      config.max = 5000
      config.duration = 60
      saveConfig()
    end
end

-- Draw Value function

local function drawValue()
  for cont,value in ipairs(graphData) do
    lcd.drawPoint(cont, LCD_H/(max-min)*value)
  end
    
end

-- Init function

local function init_func()

  -- Get radio type and set display

  _,config.radio,_,_,_ = getVersion()
  config.radio = string.sub(config.radio,1,2)

  -- Read config

  local configFile = io.open('/SCRIPTS/TELEMETRY/rpm.cfg','r')
  if configFile ~= nil then
    readConfig(configFile)
    io.close(configFile)
  end
end

-- Background function

local function bg_func(event)
  if refresh < 5 then refresh = refresh + 1 end
end

-- Main function

local function run_func(event)

  if refresh == 5 then
    lcd.clear()
  end

  -- Graph value

  value = getValue(config.field)
  drawValue(value)
  lcd.drawText(LCD_W-30, 1, value , MIDSIZE)

  -- Field 2

  lcd.drawText(LCD_W-30, 10, getValue(config.field), MIDSIZE)

  refresh = 0
end

return {run=run_func, background=bg_func, init=init_func}
