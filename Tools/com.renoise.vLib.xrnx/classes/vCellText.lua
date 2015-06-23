--[[============================================================================
vCellText
============================================================================]]--

class 'vCellText' (vCell)

--------------------------------------------------------------------------------
---	Text support for vCell. See also renoise.Views.Text

vCellText.DEFAULT_VALUE = ""

function vCellText:__init(...)

  local args = vLib.unpack_args(...)

  -- (variant) usually string, but any type is accepted
  -- note: the text cell supports both "transform" and "formatting"
  self._text = nil
  self.text = property(self.get_text,self.set_text)

  -- (string)
  -- Available mode are:
  -- >  "left"  
  -- >  "right"  
  -- >  "center"
  self.align = property(self.get_align,self.set_align)

  -- (string)
  -- Available font styles are:
  -- >  "normal"  
  -- >  "big"  
  -- >  "bold  
  -- >  "italic"  
  -- >  "mono"
  self.font = property(self.get_font,self.set_font)

  -- (string)
  -- Decide how the value is converted into text. Use this if you just
  -- need a light-weight formatting of text (for more complex formatting,
  -- a "transform" callback function can be defined, as with any other cell)
  -- Formatting field types:
  -- %d decimal integer
  -- %o octal integer
  -- %x hexadecimal integer, uppercase if %X
  -- %f floating-point in the form [-]nnnn.nnnn
  -- %e floating-point in exp. Form [-]n.nnnn e [+|-]nnn, uppercase if %E
  -- %g floating-point as %e if exp. < -4 or >= precision, else as %f; uppercase if %G.
  -- %c character having the (system-dependent) code passed as integer
  -- %s string with no embedded zeros
  -- %q string between double quotes, with all special characters escaped
  -- %% '%' character
  self.formatting = nil

  -- internal -------------------------

	vCell.__init(self,...)

  self.view = args.vb:text{
    text = args.text or "",
    align = args.align,
    font = args.font or "normal",
  }

	vCell.update(self)

end

--------------------------------------------------------------------------------

function vCellText:set_value(str)
  self:set_text(str)
end

function vCellText:get_value()
  return self._text
end

--------------------------------------------------------------------------------
-- set the text value - notice how we store the raw value, 
-- but can display a transformed/formatted version 

function vCellText:get_text()
  return self._text
end

function vCellText:set_text(str)
  self._text = str
  local str = self._text
  if (type(str)== "nil") then
    str = vCellText.DEFAULT_VALUE
  else
    if self.transform then
      str = self.transform(str,self)
    end
    if self.formatting then
      str = (self.formatting):format(str)
    else
      str = ("%s"):format(tostring(str))
    end
  end
  self.view.text = str
	vCell.update(self)
end

--------------------------------------------------------------------------------

function vCellText:get_align()
  return self.view.align
end

function vCellText:set_align(str)
  self.view.align = str
	vCell.update(self)
end

--------------------------------------------------------------------------------

function vCellText:get_font()
  return self.view.font
end

function vCellText:set_font(str)
  self.view.font = str
	vCell.update(self)
end

