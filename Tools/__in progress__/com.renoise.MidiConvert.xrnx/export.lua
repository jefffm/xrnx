--[[============================================================================
export.lua
============================================================================]]--

--[[

I tried to make an OO class, but yield would throw:
$ Error: attempt to yield across metamethod/C-call boundary

I also tried to make a Lua module, but I got:
$ Error: attempt to get length of upvalue [...]

Dinked around for hours, gave up.
Thusly, this file is procedural. Each function is to be prepended with `export_`
Good times.

]]--

--------------------------------------------------------------------------------
-- Variables & Globals
--------------------------------------------------------------------------------

local midi_division = 96 -- MIDI clicks per quarter note

local filepath = nil
local rns = nil

local data = table.create()
local data_bpm = table.create()
local data_lpb = table.create()
local data_tpl = table.create()
local data_tick_delay = table.create()


--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- MF2T Timestamp
function export_pos_to_time(pos, delay, division, lpb)
  local time = ((pos - 1) + delay / 256) * (division / lpb)
  return math.floor(time + .5) --Round
end

-- Tick to Delay (0.XX)
function export_tick_to_delay(tick, tpl)
  if tick > tpl then return false end
  local delay = tick * 256 / tpl
  return delay / 256
end


-- Used to sort a table in export_midi()
function export_compare(a, b)
  return a[1] < b[1]
end


-- Animate status bar
local status_animation = { "|", "/", "-", "\\" }
local status_animation_pos = 1
function export_status_progress()
  if status_animation_pos >= #status_animation then
    status_animation_pos = 1
  else
    status_animation_pos = status_animation_pos + 1
  end
  return "MIDI Export, Working... " .. status_animation[status_animation_pos]
end


--------------------------------------------------------------------------------
-- Build a data table
--------------------------------------------------------------------------------

function export_build_data()

  data:clear(); data_bpm:clear(); data_lpb:clear()
  data_tpl:clear(); data_tick_delay:clear()

  local instruments = rns.instruments
  local tracks = rns.tracks
  local sequencer = rns.sequencer
  local total_instruments = #instruments
  local total_tracks = #tracks
  local total_sequence = #sequencer.pattern_sequence

  -- Instruments
  for i=1,total_instruments do
    data[i] = table.create()
    local j = 0
    -- Tracks
    for track_index=1,total_tracks do
      -- Note Columns
      -- At least 1 (used to process master an send tracks)
      local total_note_columns = 1
      if tracks[track_index].visible_note_columns > 1 then
        total_note_columns = tracks[track_index].visible_note_columns
      end
      for column_index=1,total_note_columns do
        local pattern_current = -1
        local pattern_previous = sequencer.pattern_sequence[1]
        local pattern_offset = 0
        local pattern_length = 0
        -- Sequence
        for sequence_index=1,total_sequence do
          -- Calculate offset
          if pattern_current ~= sequence_index then
            pattern_current = sequence_index
            if sequence_index > 1 then
              pattern_offset = pattern_offset + rns.patterns[pattern_previous].number_of_lines
            end
          end
          local pattern_index = sequencer.pattern_sequence[sequence_index]
          local current_pattern_track = rns.patterns[pattern_index].tracks[track_index]
          pattern_length = rns.patterns[pattern_index].number_of_lines
          -- Lines
          for line_index=1,pattern_length do

            --------------------------------------------------------------------
            -- Data chug-a-lug start >>>
            --------------------------------------------------------------------

            local pos = line_index + pattern_offset

            -- Look for global changes, don't repeat more than once
            -- Override pos, from left to right
            if i == 1 then
              for fx_column_index=1,tracks[track_index].visible_effect_columns do
                local fx_col = current_pattern_track:line(line_index).effect_columns[fx_column_index]
                if 'F0' == fx_col.number_string then
                  -- F0xx - Set Beats Per Minute (BPM) (20 - FF, 00 = stop song)
                  data_bpm[pos] = fx_col.amount_string
                elseif 'F1' == fx_col.number_string  then
                  -- F1xx - Set Lines Per Beat (LPB) (01 - FF, 00 = stop song).
                   data_lpb[pos] = fx_col.amount_string
                elseif 'F2' == fx_col.number_string  then
                  -- F2xx - Set Ticks Per Line (TPL) (01 - 10).
                  data_tpl[pos] = fx_col.amount_string
                elseif '0D' == fx_col.number_string  then
                  -- 0Dxx, Delay all notes by xx ticks.
                  data_tick_delay[pos] = fx_col.amount_string
                end
              end
            end

            -- Notes data
            if
              tracks[track_index].type ~= renoise.Track.TRACK_TYPE_MASTER and
              tracks[track_index].type ~= renoise.Track.TRACK_TYPE_SEND
            then
              -- TODO:
              -- NNA and a more realistic note duration could, in theory,
              -- be calculated with the length of the sample and the instrument
              -- ADSR properties.

              local note_col = current_pattern_track:line(line_index).note_columns[column_index]
              local volume = 128
              local panning = 64
              local tick_delay = 0 -- Dx - Delay a note by x ticks (0 - F).

              -- Volume column
              if 0 <= note_col.volume_value and note_col.volume_value <= 128 then
                volume = note_col.volume_value
              elseif note_col.volume_string:find('D') == 1 then
                tick_delay = note_col.volume_string:sub(2)
              end
              -- Panning col
              if 0 <= note_col.panning_value and note_col.panning_value <= 128 then
                panning = note_col.panning_value
              elseif note_col.panning_string:find('D') == 1 then
                tick_delay = note_col.panning_string:sub(2)
              end

              -- Note OFF
              if
                not note_col.is_empty and
                j > 0 and data[i][j].pos_end == 0
              then
                data[i][j].pos_end = pos
                data[i][j].delay_end = note_col.delay_value
                data[i][j].tick_delay_end = tick_delay
              end
              -- Note ON
              if note_col.instrument_value == i-1 then
                data[i]:insert{
                  note = note_col.note_value,
                  pos_start = pos,
                  pos_end = 0,
                  delay_start = note_col.delay_value,
                  tick_delay_start = tick_delay,
                  delay_end = 0,
                  tick_delay_end = 0,
                  volume = volume,
                  panning = panning,
                  -- track = track_index,
                  -- column = column_index,
                  -- sequence_index = sequence_index,
                }
                j = table.count(data[i])
              end
              pattern_previous = sequencer.pattern_sequence[sequence_index]
            end

            --------------------------------------------------------------------
            -- <<< Data chug-a-lug end
            --------------------------------------------------------------------

          end -- Lines

          -- Insert terminating Note OFF
          if j > 0 and data[i][j].pos_end == 0 then
            data[i][j].pos_end = pattern_offset + pattern_length + rns.transport.lpb
          end

        end -- Sequence
      end -- Note Columns

      -- Yield every track to avoid timeout nag screens
      renoise.app():show_status(export_status_progress())
      coroutine.yield()
      print(("Process(build_data()) - Instr: %d; Track: %d.")
        :format(i, track_index))

    end -- Tracks
  end -- Instruments
end


--------------------------------------------------------------------------------
-- Create and save midi file
--------------------------------------------------------------------------------

-- Note: we often re-use a special `sort_me` table
-- because we need to sort timestamps before they can be added

-- Returns max pos in table
-- (a) is a table where key is pos
function _export_max_pos(a)
  local keys = a:keys()
  local mi = 1
  local m = keys[mi]
  for i, val in ipairs(keys) do
    if val > m then
      mi = i
      m = val
    end
  end
  return m
end


-- Return a float representing, pos, delay, and tick
function _export_pos_to_float(pos, delay, tick, idx)
  -- Find last known tpl value
  local tpl = rns.transport.tpl
  for i=idx,1,-1 do
    if data_tpl[i] ~= nil and i <= pos then
      tpl = tonumber(data_tpl[i], 16)
      break
    end
  end
  -- Calculate tick delay
  local float = export_tick_to_delay(tick, tpl)
  if float == false then return false end
  -- Calculate global tick delay
  if data_tick_delay[pos] ~= nil then
    local g_float = export_tick_to_delay(tonumber(data_tick_delay[pos], 16), tpl)
    if g_float == false then return false
    else float = float + g_float end
  end
  -- Convert to pos
  float = float + delay / 256
  return pos + float
end


-- Return a MF2T timestamp
function _export_float_to_time(float, division, idx)
  -- Find last known tick value
  local lpb = rns.transport.lpb
  for i=idx,1,-1 do
    if data_lpb[i] ~= nil and i <= math.floor(float + .5) then
      lpb = tonumber(data_lpb[i], 16)
      break
    end
  end
  -- Calculate time
  local time = (float - 1) * (division / lpb)
  return math.floor(time + .5) --Round
end


-- Note ON
function _export_note_on(tn, sort_me, data, idx)
  -- Create MF2T message
  local pos_d = _export_pos_to_float(data.pos_start, data.delay_start,
    tonumber(data.tick_delay_start, 16), idx)
  if pos_d ~= false then
    local msg = "On ch=1 n=" ..  data.note .. " v=" .. math.min(data.volume, 127)
    sort_me:insert{pos_d, msg, tn}
  end
end


-- Note OFF
function _export_note_off(tn, sort_me, data, idx)
  -- Create MF2T message
  local pos_d = _export_pos_to_float(data.pos_end, data.delay_end,
    tonumber(data.tick_delay_end, 16), idx)
  if pos_d ~= false then
    local msg = "Off ch=1 n=" ..  data.note .. " v=0"
    sort_me:insert{pos_d, msg, tn}
  end
end


function export_midi()

  local midi = Midi()
  midi:open()
  midi:setTimebase(midi_division);
  midi:setBpm(rns.transport.bpm); -- Initial BPM

  -- Debug
  -- rprint(data)
  -- rprint(data_bpm)
  -- rprint(data_lpb)
  -- rprint(data_tpl)
  -- rprint(data_tick_delay)

  -- Whenever we encounter a BPM change, write it to the MIDI tempo track
  local sort_me = table.create()
  local lpb = rns.transport.lpb -- Initial LPB
  for pos,bpm in pairs(data_bpm) do
    sort_me:insert{ pos, bpm }
  end
  -- [1] = Pos, [2] = BPM
  table.sort(sort_me, export_compare)
  for i=1,#sort_me do
    local bpm = tonumber(sort_me[i][2], 16)
    if  bpm > 0 then
      -- TODO:
      -- Apply LPB changes here? See "LBP procedure is flawed?" note below...
      local timestamp = export_pos_to_time(sort_me[i][1], 0, midi_division, lpb)
      if timestamp > 0 then
        midi:addMsg(1, timestamp .. " Tempo " .. bpm_to_tempo(bpm))
      end
    end
  end

  -- Create a new MIDI track for each Renoise Instrument
  local idx = _export_max_pos(data_tpl) or 1
  sort_me:clear()
  for i=1,#data do
    if table.count(data[i]) > 0 then
      local tn = midi:newTrack()
      -- Renoise Instrument Name as MIDI TrkName
      midi:addMsg(tn,
        '0 Meta TrkName "' ..
        string.format("%02d", i - 1) .. ": " ..
        string.gsub(rns.instruments[i].name, '"', '') .. '"'
      )
      -- Renoise Instrument Name as MIDI InstrName
      midi:addMsg(tn,
        '0 Meta InstrName "' ..
        string.format("%02d", i - 1) .. ": " ..
        string.gsub(rns.instruments[i].name, '"', '') .. '"'
      )

      -- [1] = Pos+Delay, [2] = Msg, [3] = Track number (tn)
      for j=1,#data[i] do
        _export_note_on(tn, sort_me, data[i][j], idx)
        _export_note_off(tn, sort_me, data[i][j], idx)
      end

    end
    -- Yield every track to avoid timeout nag screens
    renoise.app():show_status(export_status_progress())
    coroutine.yield()
    print(("Process(midi()) - Instr: %d."):format(i))
  end

  -- TODO:
  -- LBP procedure is flawed? for example:
  -- Note pos:1, LBP changed pos:3, LBP changed pos:5, Note pos:7
  -- Current algorithm only uses last known LBP on pos:5 
  -- But, pos:3 will affect the timeline?

  -- [1] = MF2T Timestamp, [2] = Msg, [3] = Track number (tn)
  idx = _export_max_pos(data_lpb) or 1
  for j=1,#sort_me do
    sort_me[j][1] = _export_float_to_time(sort_me[j][1], midi_division, idx)
  end
  table.sort(sort_me, export_compare)
  for i=1,#sort_me do
    midi:addMsg(sort_me[i][3], trim(sort_me[i][1] .. " " .. sort_me[i][2]))
    -- Yield every 1000 messages to avoid timeout nag screens
    if (i % 1000 == 0) then
      renoise.app():show_status(export_status_progress())
      coroutine.yield()
      print(("Process(midi()) - Msg: %d."):format(i))
    end
  end

  -- Save files
  midi:saveTxtFile(filepath .. '.txt')
  midi:saveMidFile(filepath)

end


--------------------------------------------------------------------------------
-- Main procedure(s) wraped in ProcessSlicer
--------------------------------------------------------------------------------

function export_procedure()
  filepath = renoise.app():prompt_for_filename_to_write("midi", "Export MIDI")
  if filepath == '' then return end

  rns = renoise.song()

  -- Reset song position
  rns.transport:stop()
  rns.transport.playback_pos = renoise.SongPos(1, 1)

  local process = ProcessSlicer(export_build, export_done)
  renoise.tool().app_release_document_observable
    :add_notifier(function()
      if (process and process:running()) then
        process:stop()
        print("Process 'build_data()' has been aborted due to song change.")
      end
    end)
  process:start()
end


function export_build()
  renoise.app():show_status(export_status_progress())
  export_build_data()
  export_midi()
end


function export_done()
  -- export_build_data()
  -- export_midi()
  renoise.app():show_status("MIDI Export, Done!")
end
