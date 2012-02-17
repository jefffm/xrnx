--[[----------------------------------------------------------------------------
-- Duplex.UIKeyPressure
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UISlider > UIKeyPressure


About

  UIKeyPressure is a UIComponent that respond to channel-pressure events.


--]]


--==============================================================================

class 'UIKeyPressure' (UISlider)

function UIKeyPressure:__init(display)
  TRACE("UIKeyPressure:__init()",display)

  UISlider.__init(self,display)

end


function UIKeyPressure:add_listeners()
  TRACE("UIKeyPressure:add_listeners()")

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_CHANNEL_PRESSURE,
    function(msg) return self:do_change(msg) end )

end

function UIKeyPressure:remove_listeners()
  TRACE("UIKeyPressure:remove_listeners()")

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_CHANNEL_PRESSURE)

end

