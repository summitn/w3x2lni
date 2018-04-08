local gui = require 'yue.gui'
local ext = require 'yue-ext'
local timer = require 'gui.timer'

window = {}

ext.on_timer = timer.update
function ext.on_dropfile(filename)
    window:show_page('select')
end

local FontPool = {}
function Font(name, size, weight, style)
    weight = weight or 'normal'
    style = style or 'normal'
    local key = ('%s|%d|%s|%s'):format(name, size, weight, style)
    local r = FontPool[key]
    if not r then
        r = gui.Font.create(name, size, weight, style)
        FontPool[key] = r
    end
    return r
end


function Label(text, color)
    if not color then
        color = window._color
    end
    local label = gui.Label.create(text)
    label:setbackgroundcolor(color)
    label:setfont(Font('黑体', 16))
    return label
end

function Button(text, color1, color2)
    if not color1 then
        color1 = window._color
    end
    if not color2 then
        color2 = ('#%06X'):format(tonumber('0x' .. color1:sub(2)) + 0x101010)
    end
    local btn = gui.Button.create(text)
    btn:setbackgroundcolor(color1)
    btn._backgroundcolor1 = color1
    btn._backgroundcolor2 = color2
    function btn:onmouseleave()
        self:setbackgroundcolor(self._backgroundcolor1)
    end
    function btn:onmouseenter()
        self:setbackgroundcolor(self._backgroundcolor2)
    end
    return btn
end

function SwitchPage(name)
    return window:show_page(name)
end

function window:close_theme()
    self._close._backgroundcolor1 = self._color
    self._close:setbackgroundcolor(self._close._backgroundcolor1)
end

function window:addcaption(w)
    local caption = gui.Container.create()
    caption:setmousedowncanmovewindow(true)
    caption:setstyle { Height = 40, FlexDirection = 'row', JustifyContent = 'space-between' }
    self._caption = caption
    g_caption = caption
    local title = gui.Label.create('W3x2Lni')
    title:setmousedowncanmovewindow(true)
    title:setstyle { Width = 120 }
    title:setfont(Font('Constantia', 24, 'bold'))
    caption:addchildview(title)
    self._title = title

    local close = gui.Container.create()
    close:setstyle { Margin = 0, Width = 40 }

    local canvas = gui.Canvas.createformainscreen{width=40, height=40}
    local painter = canvas:getpainter()
    painter:setstrokecolor('#000000')
    painter:beginpath()
    painter:moveto(15, 15)
    painter:lineto(25, 25)
    painter:moveto(15, 25)
    painter:lineto(25, 15)
    painter:closepath()
    painter:stroke()
    close._backgroundcolor1 = '#000000'
    close:setbackgroundcolor('#000000')
    function close:onmouseleave()
        self:setbackgroundcolor(self._backgroundcolor1)
    end
    function close:onmouseenter()
        self:setbackgroundcolor('#BE3246')
    end
    function close:onmousedown()
        w:close()
    end
    function close.ondraw(self, painter, dirty)
      painter:drawcanvas(canvas, {x=0, y=0, width=40, height=40})
    end

    self._close = close
    
    caption:addchildview(close)
    return caption
end

function window:create(t)
    local win = gui.Window.create { frame = false }
    function win.onclose()
        gui.MessageLoop.quit()
    end
    win:settitle('w3x2lni')
    ext.register_window('w3x2lni')

    local view = gui.Container.create()
    view:setbackgroundcolor('#222')
    local caption = self:addcaption(win)
    view:addchildview(caption)
    win:sethasshadow(true)
    win:setresizable(false)
    win:setmaximizable(false)
    win:setcontentview(view)
    win:setcontentsize { width = t.width, height = t.height }
    win:center()
    win:activate()
    self._window = win
end

function window:set_theme(title, color)
    self._title:settext(title)
    self._color = color
    self._caption:setbackgroundcolor(color)
    self:close_theme()
end

function window:show_page(name)
    local view = self._window:getcontentview()
    if self._page then
        self._page:setvisible(false)
    end
    self._page = require('gui.new.page.' .. name)
    self._page:setvisible(true)
    view:addchildview(self._page)
end

local view = window:create {
    width = 400, 
    height = 600,
}

window:set_theme('W3x2Lni', '#00ADD9')
window:set_theme('W3x2Slk', '#00AD3C')
--window:set_theme('W3x2Obj', '#D9A33C')
window:show_page('index')

gui.MessageLoop.run()
