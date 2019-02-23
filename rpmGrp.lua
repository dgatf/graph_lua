--[[
      rpmGraph v0.1

       22/02/2019

    
  Lua script for radios X7/X9 with openTx 2.2

  Shows a graph of rpm over time

]]--

-- Global variables

local refresh = 0
local config = {radio, field = 'RPM', field2 = 'VFAS', mode = 0, min = 0, max = 5000, duration = 60}
local graphData = {}
local timeStep
local timeStamp
local margin = {left = 0, right = 37, up = 10, down = 10}

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
  local value = list[first]
  list[first] = nil
  list.first = first + 1
  return value
end

function List.size (list)
  return list.last-list.first
end

-- Draw Value function

local function drawGraph()
  lcd.drawFilledRectangle(margin.left, margin.up, LCD_W-margin.left-margin.right+1, LCD_H-margin.up-margin.down, ERASE)
  for cont=graphData.first, graphData.last do
    if graphData[cont]>0 then lcd.drawPoint(cont-graphData.first, graphData[cont]+margin.up) end
  end   
end

-- Init function

local function init_func()
  lcd.clear()
  timeStep = config.duration/(LCD_W-margin.left-margin.right)
  timeStamp = getTime()/100
  graphData = List.new()
end

-- Background function

local function bg_func(event)
  if refresh < 5 then refresh = refresh + 1 end
end

-- Main function

local function run_func(event)

  if refresh == 5 then
    lcd.clear()
    lcd.drawText(LCD_W-margin.right+2, 1, config.field, MIDSIZE)
    lcd.drawText(LCD_W-margin.right+2, 30, config.field2, MIDSIZE)
    lcd.drawText(LCD_W-margin.right+2, 30, config.field2, MIDSIZE)
    lcd.drawText(1, 1, config.max, SMLSIZE)
    lcd.drawText(1, LCD_H-7, config.min, SMLSIZE)
    lcd.drawText(LCD_W-margin.right-10, LCD_H-7, config.duration, SMLSIZE)
  end

  -- Graph field

  value = getValue(config.field)
  lcd.drawText(LCD_W-margin.right+1, 15, value .. '      ', MIDSIZE)
  if getTime()-timeStamp > timeStep then
    List.enqueue(graphData, (LCD_H-margin.up-margin.down)*(1-value/(config.max-config.min)))
    if List.size(graphData) > LCD_W-margin.right-margin.left then List.dequeue(graphData) end
    drawGraph()
    timeStamp = getTime()
  end

  -- Field 2

  lcd.drawText(LCD_W-margin.right+2, 45, getValue(config.field2) .. '      ', MIDSIZE)

  refresh = 0
end

return {run=run_func, background=bg_func, init=init_func}

