--[[============================================================================
Renoise ViewBuilder API Reference
============================================================================]]--

--[[

This reference lists all "View" related functions in the API. "View" means
classes and functions that are used to build custom GUIs; GUIs for your
scripts in Renoise.

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

Do not try to execute this file. It uses a .lua extension for markups only.

]]


-- Currently there are two ways to to use custom views:

-- (shows a dialog with a title, custom content and custom button labels)
app():show_custom_prompt(title, content_view, {button_labels} [,key_handler_func]) 
  -> [pressed button]

and

-- (shows a non modal dialog (a tool window) with a custom content)
app():show_custom_dialog(title, content_view [, key_handler_func]) 
  -> [dialog object]

-- key_handler_func is optional. when defined, it must have the below noted
-- signature. "key" is a table with the fields {
--   name,      -- name of the key, like 'esc' or 'a' - always valid
--   modifiers, -- modifier states. 'shift + control' - always valid
--   character, -- character representation of the key or nil
--   note,      -- virtual keyboard piano key value (starting from 0) or nil
-- }
function my_keyhandler_func(dialog, key) end

-- if no handler is installed, only the Escape key is used to close the dialog.
-- For prompts, also the first character of the button labels is used to invoke
-- the corresponding button

-- For a small tutorial, and more detials on how to createand use views, take
-- a look at the  "Tools/ExampleTool_GUI.lua" file please.


--==============================================================================
-- Views
--==============================================================================

--------------------------------------------------------------------------------
-- renoise.Views.View
--------------------------------------------------------------------------------

-- a View is the base class for all following specialized views. So all
-- View properties can be applied to any of the following views


------ functions

-- create view hierarchies
view:add_child(View child_view)
view:remove_child(View child_view)


----- properties

-- set to false to hide this view (make it invisible without removing it).
-- Please note that view.visible will also return false when any of its
-- parents are invisible (when its implicitly invisible)
-- by default true
view.visible 
  -> [boolean]

-- get/set a views size. all views must have a size > 0
-- by default > 0: how much exactly depends on the specialized view type.

-- Note: in nested view_builder notations you can also specify relative
-- sizes like for example vb:text { width = "80%"}. The percentage values are
-- relative to the views parent and will automatically update on size changes...
view.width 
  -> [number]
view.height 
  -> [number]

-- get/set a tooltip text that should be shown for this view.
-- by default empty (no tip will be shown)
view.tooltip 
  -> [string]


--------------------------------------------------------------------------------
-- renoise.Views.Rack (inherits from View, 'column' or 'row' in ViewBuilder)
--------------------------------------------------------------------------------

-- a Rack has no content by its own, but stacks its child views either
-- vertically (ViewBuilder.column) or horizontally (ViewBuilder.row)

----- functions

-- adding new views to a rack automatically enlarges it while the views got 
-- stacked . by calling resize, you can let the rack recalc its size and set 
-- it to exactly conver all child views. when resizeing a rack view that is 
-- the main content view of a dialog, 'resize' will also update the dialogs 
-- size...
rack:resize()


----- properties

-- setup the "borders" of the rack (left, right, top and bottom equally)
-- by default 0
rack.margin 
  -> [number]

-- setup by which amount stacked child views are separated
-- by default 0
rack.spacing 
  -> [number]

-- setup a background style for this rack. Available styles are:
-- "invisible" -> no background is drawn
-- "plain"     -> undecorated, single colored background
-- "border"    -> same as plain, but with a bold nesting border
-- "body"      -> main "background" style, as used in dialogs backs
-- "panel"     -> alternative "background" style, beveled
-- "group"     -> background for "nested" groups within "body"s
-- by default "invisible"
rack.style 
  -> [string]

-- when set to true, child views will get resized to the max size of
-- all child views. This can be useful to automatically align all sub
-- columns/panels to the same size...
-- by default false
rack.uniform 
  -> [boolean]


--------------------------------------------------------------------------------
-- renoise.Views.Aligner (inherits from View, 'horizontal_aligner' or
--   'vertical_aligner' in ViewBuilder)
--------------------------------------------------------------------------------

-- like the Rack, the Aligner has no content by its own, but aligns its
-- child(s) either vertically or horizontally. When childs are added, it will
-- expand itself to make sure that all childs will fit (including the spacing &
-- margins), but to create modes like "center", you obviously have to setup a
-- size that is bigger than its childs.

-- can be used to align only one child view, or also multiple child views...


----- properties

-- setup the "borders" of the aligner (left, right, top and bottom equally)
-- by default 0
aligner.margin 
  -> [number]

-- setup by which amount the child views are separated
-- by default 0
aligner.spacing 
  -> [number]

-- setup the alignment mode. Available mode are:
-- "left"       -> align from left to right (for horizontal_aligner only)
-- "right"      -> align from right to left (for horizontal_aligner only)
-- "top"        -> align from top to bottom (for vertical_aligner only)
-- "bottom"     -> align from bottom to top (for vertical_aligner only)
-- "center"     -> center all views
-- "justify"    -> keep outer views at the borders, distribute the rest
-- "distribute" -> equally distributes views over the aligners width/height
-- by default "left" for a horizontal_aligner, "top" for a vertical_aligner,
aligner.mode 
  -> [string]


-----------------------------------------------------------------------------"
-- renoise.Views.Text (inherits from View, 'text' in ViewBuilder)
-----------------------------------------------------------------------------"

-- a view which simply shows a static text string. Static just means that
-- its not linked to some value. You can of course change the text at runtime...

--[[
 Text, Bla
--]]


----- properties

-- get/set the text that should be displayed. setting a new text will resize
-- the view, but only if the text would not be fully visible (expands only)
-- by default empty
text.text 
  -> [string]

-- get/set the font that the text should be displayed with.
-- avilable font styles are: "normal", "big", "bold, "italic" and "mono"
-- by default "normal"
text.font 
  -> [string]

-- setup the texts alignment
-- "left", "right" or "center" are valid align values
-- by default "left"
text.align 
  -> [string]


--------------------------------------------------------------------------------
-- renoise.Views.MultiLineText (inherits from View, 'multiline_text' in the builder)
--------------------------------------------------------------------------------

-- a view which shows multiple lines of text, auto formatting those line by
-- line. size is not automatically set. when the text does not fit into the view,
-- a scroll bar will be shown

--[[
 +--------------+-+
 | Text, Bla 1  |+|
 | Text, Bla 2  | |
 | Text, Bla 3  | |
 | Text, Bla 4  |+|
 +--------------+-+
--]]


----- properties

-- get/set the text that should be displayed. newlines in the text can be used
-- to display multiple paragraphs
-- by default empty
multiline_text.text 
  -> [string]

-- get/set a list/table of text lines, which will be converted to paragraphs
-- by default empty
multiline_text.paragraphs 
  -> [string]

-- get/set the font that the text should be displayed with.
-- avilable font styles are: "normal", "big", "bold, "italic" and "mono"
-- by default "normal"
multiline_text.font 
  -> [string]

-- setup the text views background style
-- "body"    -> simple body text color with no background
-- "strong"  -> stronger body text color with no background
-- "border"  -> text on a bordered background
-- by default "body"
multiline_text.style 
  -> [string]


----- functions

-- when a scroll bar is visible, scroll the text to show the last line
multiline_text:scroll_to_last_line()

-- when a scroll bar is visible, scroll the text to show the first line
multiline_text:scroll_to_first_line()

-- append a new text to the existing text. newlines in the text will
-- create new paragraphs, else a single new paragraph is appended
multiline_text:add_line(text)

-- clear the whole text
multiline_text:clear()


--------------------------------------------------------------------------------
-- renoise.Views.TextField (inherits from View, 'textfield' in the builder)
--------------------------------------------------------------------------------

-- a view which shows a user editable text string

--[[
 +----------------+
 | Editable Te|xt |
 +----------------+
--]]


----- properties

-- the currently shown value. the value will not be updated while editing,
-- but only after editing finished.
-- by default empty
textfield.value 
  -> [string]
-- exactly the same as "value"; provided for consistency
textfield.text 
  -> [string]

-- setup the text fields text alignment
-- "left", "right" or "center" are valid align values
-- by default "left"
textfield.align


--------------------------------------------------------------------------------
-- renoise.Views.MultilineTextField (inherits from View, 
--   'multiline_textfield' in the builder)
--------------------------------------------------------------------------------

-- a view which shows a user editable larg text string with 
-- paragraph autowrapping support

--[[
 +--------------------------+-+
 | Editable Te|xt.          |+|
 |                          | |
 | With multiple paragraphs | |
 | and autowrapping support |+|
 +--------------------------+-+
--]]             


----- properties

-- the current text as single line, using usinx newlinesto separate paragraphs
-- by default empty
multiline_textfield.value 
  -> [string]
-- exactly the same as "value"; provided for consistency
multiline_textfield.text 
  -> [string]

-- get/set a list/table of text lines, which will be converted to paragraphs
-- by default empty
multiline_textfield.pargraphs 
  -> [string]

-- get/set the font that the text should be displayed with.
-- avilable font styles are: "normal", "big", "bold, "italic" and "mono"
-- by default "normal"
multiline_textfield.font 
  -> [string]

-- setup the text views background style
-- "body"    -> simple body text color with no background
-- "strong"  -> stronger body text color with no background
-- "border"  -> text on a bordered background
-- by default "border"
multiline_textfield.style 
  -> [string]


----- functions

-- add/remove text change notifiers
multiline_textfield:add_notifier(function or {object, function} or {object, function})
multiline_textfield:remove_notifier(function or {object, function} or {object, function})


-- when a scroll bar is visible, scroll the text to show the last line
multiline_textfield:scroll_to_last_line()

-- when a scroll bar is visible, scroll the text to show the first line
multiline_textfield:scroll_to_first_line()

-- append a new text to the existing text. newlines in the text will
-- create new paragraphs, else a single new paragraph is appended
multiline_textfield:add_line(text)

-- clear the whole text
multiline_textfield:clear()


--------------------------------------------------------------------------------
-- renoise.Views.Bitmap (inherits from View, 'bitmap' in the builder)
--------------------------------------------------------------------------------

--[[    *
       ***
    +   *
   / \
  +---+
  | O |  o
  +---+  |
 ||||||||||||
--]]

-- a view which either simply draws a bitmap, or a draws bitmap which acts like
-- a button (with a notifier specified). The notifier is called when clicking
-- with the mouse button on the bitmap. When using a recolorable style
-- (see 'mode'), the bitmap is automatically recolored to match the current
-- theme colors. Also mouse hover is enabled when notifies are present then, to
-- show that the bitmap can be clicked...


----- functions

-- add/remove mouse click notifiers
bitmapview:add_notifier(function or {object, function} or {object, function})
bitmapview:remove_notifier(function or {object, function} or {object, function})


----- properties

-- setup how the bitmap should be painted, recolored. Available modes are:
-- "plain"        -> bitmap is drawn just like it is, no recoloring is done
-- "transparent"  -> same as plain, but will treat black pixels fully transparent
-- "button_color" -> recolor the bitmap, using the color themes button color
-- "body_color"   -> same as 'button_back' but with body text/back color
-- "main_color"   -> same as 'button_back' but with main text/back colors
-- by default "plain"
bitmapview.mode 
  -> [string]

-- set the to be drawn bitmap name and path. you should use a relative path
-- that either assumes the apps default resource folder as base (like
-- "Icons/ArrowRight.bmp").
-- Or specify a file relative from a folder which is named like you script:
-- Lets say your script is called "FindAndReplace.lua" and you pass
-- "MyBitmap.bmp" as name. Then the bitmap is loaded from
-- "./FindAndReplace/MyBitmap.bmp". The only supported bitmap format is
-- ".bmp" (Windows bitmap) on all platforms!
bitmapview.bitmap 
  -> [string]

-- valid in the construction table only: set up a click notifier
bitmapview.notifier 
  -> (function())


--------------------------------------------------------------------------------
-- renoise.Views.Button (inherits from View, 'button' in the builder)
--------------------------------------------------------------------------------

-- a simple button, which will call a supplied notifier when clicked.
-- supports text or bitmap labels

--[[
 +--------+
 | Button |
 +--------+
--]]


----- functions

-- add/remove button hit/release notifiers. 
-- when a pressed notifier is set, the release notifier is guaranteed to be 
-- called as soon as the mouse was released, either on your button or anywhere
-- else. when only release notifiers are set, those are only called when the 
-- mouse button was pressed and released on your button
button:add_pressed_notifier(function or {object, function} or {object, function})
button:add_released_notifier(function or {object, function} or {object, function})
button:remove_pressed_notifier(function or {object, function} or {object, function})
button:remove_released_notifier(function or {object, function} or {object, function})


----- properties

-- the label of the button
-- by default empty
button.text 
  -> [string]

-- by default not set. when set, text is cleared, and a relative path from
-- the apps resource folder is expected (like "Icons/ArrowRight.bmp").
-- Alternatively a relative from a folder which is named like you script can
-- be used as well: Lets say your script is called "FindAndReplace.lua" and
-- you pass "MyBitmap.bmp" as name. Then the bitmap is loaded from
-- "./FindAndReplace/MyBitmap.bmp"
-- The only supported bitmap format is ".bmp". Colors will be overriden by the
-- theme colors, using black as transparant color, white is the full theme
-- color. All colors inbetween are mapped according to their grey value.
button.bitmap 
  -> [string]

-- table of rgb values like {0xff,0xff,0xff} -> white. when set, the
-- unpressed button's background will be draw with the specified color. a 
-- text color is automatically selected to make sure its always visible. 
-- set a color of {0,0,0} to enable the theme colors for the button again...
button.color 
  -> [table with 3 numbers (0-255)]


-- valid in the construction table only: set up a click notifier
button.pressed 
  -> (function())

-- valid in the construction table only: set up a click release notifier
button.released 
  -> (function())

-- synonymous for 'button.released'
button.notifier 
  -> (function())


--------------------------------------------------------------------------------
-- renoise.Views.CheckBox (inherits from View, 'checkbox' in the builder)
--------------------------------------------------------------------------------

-- a single button, which can be toggled on/off

--[[
 +----+
 | _/ |
 +----+
--]]


----- functions

-- add/remove state notifiers
checkbox:add_notifier(function or {object, function} or {object, function})
checkbox:remove_notifier(function or {object, function} or {object, function})


----- properties

-- the current state of the checkbox
-- by default false
checkbox.value 
  -> [boolen]

-- valid in the construction table only: set up a value notifier
checkbox.notifier 
  -> (function(value))


--------------------------------------------------------------------------------
-- renoise.Views.Switch (inherits from View, 'switch' in the builder)
--------------------------------------------------------------------------------

-- a set of horizontal buttons, where exactly one button is switched on at
-- the same time

--[[
 +-----------+------------+----------+
 | Button A  | +Button+B+ | Button C |
 +-----------+------------+----------+
--]]


----- functions

-- add/remove index change notifiers
switch:add_notifier(function or {object, function} or {object, function})
switch:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the currently shown buttons. Item list size must be >= 2
switch.items 
  -> [list of strings]

-- get/set the currently pressed button index
switch.value

-- valid in the construction table only: set up a value notifier
switch.notifier 
  -> (function(value))


--------------------------------------------------------------------------------
-- renoise.Views.Popup (inherits from View, 'popup' in the builder)
--------------------------------------------------------------------------------

-- a dropdown menu, which shows the currently selected value when closed,
-- when clicked offers a list of items

--[[
 +--------------++---+
 | Current Item || ^ |
 +--------------++---+
--]]


----- functions

-- add/remove index change notifiers
popup:add_notifier(function or {object, function} or {object, function})
popup:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the currently shown items. Item list can be empty, then "None" is
-- displayed and the value won't change...
popup.items 
  -> [list of strings]

-- get/set the currently selected item index
popup.value

-- valid in the construction table only: set up a value notifier
popup.notifier 
  -> (function(value))


--------------------------------------------------------------------------------
-- renoise.Views.Chooser (inherits from View, 'chooser' in the builder)
--------------------------------------------------------------------------------

-- a radio button alike set of vertically stacked items, where only
-- one value can be selected at the same time

--[[
 . Item A
 o Item B
 . Item C
--]]


----- functions

-- add/remove index change notifiers
chooser:add_notifier(function or {object, function} or {object, function})
chooser:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the currently shown items. Item list size must be >= 2.
chooser.items 
  -> [list of strings]

-- get/set the currently selected item index
chooser.value
  -> [number]

-- valid in the construction table only: set up a value notifier
chooser.notifier 
  -> (function(value))


--------------------------------------------------------------------------------
-- renoise.Views.ValueBox (inherits from View, 'valuebox' in the builder)
--------------------------------------------------------------------------------

-- a box with <> buttons and a editable value field, which allows showing /
-- editing number values in a custom range

--[[
 +---+-------+
 |<|>|  12   |
 +---+-------+
--]]


----- functions

-- add/remove value change notifiers
valuebox:add_notifier(function or {object, function} or {object, function})
valuebox:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the min/max values that are expected, allowed.
-- by default 0 and 100
valuebox.min
  -> [number]
valuebox.max 
  -> [number]

-- get/set the current value
valuebox.value

-- valid in the construction table only: setup custom rules on how the number
-- should be displayed. both, 'tostring' and  'tovalue' must be set, or none
-- of them. If none are set, a default string/number conversion is done, which
-- simply shows the number with 3 digits after the decimal point.
--
-- when defined, 'tostring' must be a function with one parameter, the to be
-- converted number, and must return a string or nil (nothing).
-- 'tonumber' must be a function with one parameter and gets the to be
-- converted string passed, returning a a number or nil. when returning nil,
-- no conversion will be done and the value is not changed.
--
-- note: when any of the callbacks fails with an error, both will be disabled
-- to avoid floods of error messages
valuefield.tostring 
  -> (function(number) -> [string])
valuefield.tovalue 
  -> (function(string) -> [number])

-- valid in the construction table only: set up a value notifier
valuebox.notifier 
  -> (function(value))


--------------------------------------------------------------------------------
-- renoise.Views.Value (inherits from View, 'value' in the builder)
--------------------------------------------------------------------------------

-- a readonly text with a number getter/setters and custom string conversion
-- see also 'Views.ValueField'

--[[
 +---+-------+
 | 12.1 dB   |
 +---+-------+
--]]


----- functions

-- add/remove value change notifiers
value:add_notifier(function or {object, function} or {object, function})
value:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the current value
value.value

-- get/set the font that the text should be displayed with.
-- avilable font styles are: "normal", "big", "bold, "italic" and "mono"
-- by default "normal"
value.font 
  -> [string]

-- setup the value text's alignment
-- "left", "right" or "center" are valid align values
-- by default "left"
value.align 
  -> [string]

-- valid in the construction table only: setup a custom rule on how the
-- number should be displayed. when defined, 'tostring' must be a function
-- with one parameter, the to be converted number, and must return a string
-- or nil (nothing).
--
-- note: when the callback fails with an error, it will be disabled to avoid
-- floods of error messages
value.tostring 
  -> (function(number) -> [string])

-- valid in the construction table only: set up a value notifier
value.notifier 
  -> (function(number))


--------------------------------------------------------------------------------
-- renoise.Views.ValueField (inherits from View, 'valuefield' in the builder)
--------------------------------------------------------------------------------

-- a value which has an editfield to show and edit the double value as string

--[[
 +---+-------+
 | 12.1 dB   |
 +---+-------+
--]]


----- functions

-- add/remove value change notifiers
valuefield:add_notifier(function or {object, function} or {object, function})
valuefield:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the min/max values that are expected, allowed
-- by default 0.0 and 1.0
valuefield.min 
  -> [number]
valuefield.max 
  -> [number]

-- get/set the current value
valuefield.value

-- setup the texts alignment
-- "left", "right" or "center" are valid align values
-- by default "left"
valuefield.align 
  -> [string]

-- valid in the construction table only: setup custom rules on how the number
-- should be displayed. both, 'tostring' and  'tovalue' must be set, or none
-- of them. If none are set, a default string/number conversion is done, which
-- simply shows the number with 3 digits after the decimal point.
--
-- when defined, 'tostring' must be a function with one parameter, the to be
-- converted number, and must return a string or nil (nothing).
-- 'tonumber' must be a function with one parameter and gets the to be
-- converted string passed, returning a a number or nil. when returning nil,
-- no conversion will be done and the value is not changed.
--
-- note: when any of the callbacks fails with an error, both will be disabled
-- to avoid floods of error messages
valuefield.tostring 
  -> (function(number) -> [string])
valuefield.tovalue 
  -> (function(string) -> [number])

-- valid in the construction table only: set up a value notifier
valuefield.notifier 
  -> (function(number))


--------------------------------------------------------------------------------
-- renoise.Views.Slider (inherits from View, 'slider' in the builder)
--------------------------------------------------------------------------------

-- a slider with <> buttons, which allows showing / editing real values in
-- a custom range. a slider can be horizontal or vertical. will flip its layout 
-- according to the set width and height and is by default horizontal.

--[[
 +---+---------------+
 |<|>| --------[]    |
 +---+---------------+
--]]


----- functions

-- add/remove value change notifiers
slider:add_notifier(function or {object, function} or {object, function})
slider:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the min/max values that are expected, allowed.
-- by default 0.0 and 1.0
slider.min 
  -> [number]
slider.max 
  -> [number]

-- get/set the current value
slider.value

-- valid in the construction table only: set up a value notifier
slider.notifier 
  -> (function(number))


--------------------------------------------------------------------------------
-- renoise.Views.MiniSlider (inherits from View, 'minislider' in the builder)
--------------------------------------------------------------------------------

-- same as a slider, but without <> buttons and a really tiny height. just like
-- the slider a mini slider can be horizontal or vertical. it will flip its layout 
-- according to the set width and height and is by default horizontal.

--[[
 --------[]
--]]


----- functions

-- add/remove value change notifiers
slider:add_notifier(function or {object, function} or {object, function})
slider:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the min/max values that are expected, allowed.
-- by default 0.0 and 1.0
slider.min 
  -> [number]
slider.max 
  -> [number]

-- get/set the current value
slider.value

-- valid in the construction table only: set up a value notifier
slider.notifier 
  -> (function(number))


--------------------------------------------------------------------------------
-- renoise.Views.RotaryEncoder (inherits from View, 'rotary' in the builder)
--------------------------------------------------------------------------------

--[[
   +-+
 / \   \
|   o   |
 \  |  /
   +-+
--]]

-- Note: when changing the size, the min of the width and height will be used
-- to draw and control the rotary control, so you should always set both equally.


----- functions

-- add/remove value change notifiers
rotary:add_notifier(function or {object, function} or {object, function})
rotary:remove_notifier(function or {object, function} or {object, function})


----- properties

-- get/set the min/max values that are expected, allowed.
-- by default 0.0 and 1.0
rotary.min 
  -> [number]
rotary.max 
  -> [number]

-- get/set the current value
rotary.value

-- valid in the construction table only: set up a value notifier
rotary.notifier 
  -> (function(number))


--==============================================================================
-- renoise.Dialog
--==============================================================================

-- a dialog can not created with the viewbuilder, but you may want to control it
-- close it after having passed it to a dialog. The apps non modal dialog
-- create functions will return a reference to the created dialogs

----- functions

dialog:show()
dialog:close()


----- properties

dialog.visible 
  -> [read-only, boolean]


--==============================================================================
-- renoise.ViewBuilder
--==============================================================================

-- class which is used to construct new Views. All views properties, as listed
-- above, can optionally be inlined in a passed construction table:

-- local vb = renoise.ViewBuilder() -- create a new ViewBuilder
-- vb:button { text = "ButtonText" } -- is the same as
-- my_button = vb:button{}; my_button.text = "ButtonText"

-- beside of the listed class properties above, you can also specify the
-- following "extra" properties in the passed table:
--
-- * id = "SomeString": which can be use to resolve the view later on
--   -> vb.views.SomeString or vb.views.["SomeString"]
--
-- * notifier = some_function or notifier = {some_obj, some_function} to
--   register notifiers (for views, which support notifiers only of course)
--
-- * nested child views: to directly add a child view to the currently
--   specified view. For example:
--
--   vb:column {
--     margin = 1,
--     vb:text {
--       text = "Text1"
--     }
--   }
--
--   (creates a column view with margin = 1 and adds a text as child view
--    to the column...)


-- consts (renoise.ViewBuilder.XXX)

renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT


----- functions

vb:column { Rack Properties and/or child views }
vb:row { Rack Properties and/or child views }

vb:horizontal_aligner { Aligner Properties and/or child views }
vb:vertical_aligner { Aligner Properties and/or child views }

vb:space { View Properties and/or child views }

vb:text { Text Properties }
vb:multiline_text { MultiLineText Properties }

vb:textfield { TextField Properties }

vb:bitmap { Bitmap Properties }

vb:button { Button Properties }

vb:checkbox  { Rack Properties }
vb:switch { Switch Properties }
vb:popup { Popup Properties }
vb:chooser { Chooser Properties }

vb:valuebox { ValueBox Properties }

vb:value { Value Properties }
vb:valuefield { ValueField Properties }

vb:slider { Slider Properties }
vb:minislider { MiniSlider Properties }

vb:rotary { RotaryEncoder Properties }


----- properties

-- view id is the key, value the corresponding view object
vb.views 
  -> [table of views, which got registered via the "id" property]
