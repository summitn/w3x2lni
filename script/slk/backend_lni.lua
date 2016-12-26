local progress = require 'progress'

local table_insert = table.insert
local table_sort = table.sort
local math_type = math.type
local table_concat = table.concat
local string_char = string.char
local type = type
local os_clock = os.clock

local keydata
local metadata

local character = { 'A','B','C','D','E','F','G','H','I' }

local function get_displaykey(code, key)
    local id = keydata[code] and keydata[code][key] or keydata['common'][key]
    local meta = metadata[id]
    if not meta then
        return
    end
    local key = meta.field
    local num = meta.data
    if num and num ~= 0 then
        key = key .. character[num]
    end
    if meta._has_index then
        key = key .. ':' .. (meta.index + 1)
    end
    return key
end

local mt = {}
mt.__index = mt

local function get_len(tbl)
	local n = 0
	for k in pairs(tbl) do
		if type(k) == 'number' and k > n then
			n = k
		end
	end
	return n
end

function mt:format_value(value)
	local tp = type(value)
	if tp == 'number' then
		if math_type(value) == 'integer' then
			return ('%d'):format(value)
		else
			return ('%.4f'):format(value)
		end
	elseif tp == 'nil' then
		return 'nil'
	else
		value = self.w2l:editstring(value)
		if value:match '[\n\r]' then
			return ('[=[\r\n%s]=]'):format(value)
		else
			return ('%q'):format(value)
		end
	end
end

function mt:add(format, ...)
	self.lines[#self.lines+1] = format:format(...)
end

function mt:add_chunk(chunk, type)
	local names = {}
	for name, obj in pairs(chunk) do
		if name:sub(1, 1) ~= '_' then
			table_insert(names, name)
		end
	end
	table_sort(names, function(name1, name2)
		local is_origin1 = name1 == chunk[name1]['_lower_parent']
		local is_origin2 = name2 == chunk[name2]['_lower_parent']
		if is_origin1 and not is_origin2 then
			return true
		end
		if not is_origin1 and is_origin2 then
			return false
		end
		return chunk[name1]['_id'] < chunk[name2]['_id']
	end)
    local clock = os_clock()
	for i = 1, #names do
		local obj = chunk[names[i]]
		self:add_obj(obj)
        if os_clock() - clock >= 0.1 then
            clock = os_clock()
            message(('正在转换%s: [%s] (%d/%d)'):format(type, obj._id, i, #names))
            progress(i / #names)
        end
	end
end

function mt:add_obj(obj)
	if self.remove_unuse_object and not obj._mark then
		return
	end
	local upper_obj = {}
    local keys = {}
	local name = obj._id
	local code = obj._code
    for key, data in pairs(obj) do
		if key:sub(1, 1) ~= '_' then
			local key = get_displaykey(code, key)
			if key then
				keys[#keys+1] = key
				upper_obj[key] = data
			end
		end
	end
    table_sort(keys)
    local lines = {}
	for _, key in ipairs(keys) do
		local id = self:key2id(code, key:lower())
		self:add_data(key, id, upper_obj[key], lines)
	end
    if not lines or #lines == 0 then
        return
    end

	self:add('[%s]', obj['_id'])
	if obj['_parent'] then
		self:add('%s = %q', '_id', obj['_parent'])
	end
    if obj['_name'] then
        self:add('%s = %q', '_name', obj['_name'])
    end
    for i = 1, #lines do
        self:add(table.unpack(lines[i]))
    end
	self:add ''
end

function mt:add_data(key, id, data, lines)
	local len
	if type(data) == 'table' then
		len = get_len(data)
		if len == 0 then
			return
		end
	end
	if key:match '[^%w%_]' then
		key = ('%q'):format(key)
	end
    lines[#lines+1] = {'-- %s', self:get_comment(id)}
	if not len then
		lines[#lines+1] = {'%s = %s', key, self:format_value(data)}
		return
	end
	if len <= 1 then
		lines[#lines+1] = {'%s = %s', key, self:format_value(data[1])}
		return
	end

	local values = {}
	local is_string
	for i = 1, len do
		if type(data[i]) == 'string' then
			is_string = true
		end
		if len >= 10 then
			values[i] = ('%d = %s'):format(i, self:format_value(data[i]))
		else
			values[i] = self:format_value(data[i])
		end
	end

	if is_string or len >= 10 then
		lines[#lines+1] = {'%s = {\r\n%s,\r\n}', key, table_concat(values, ',\r\n')}
		return
	end
	
	lines[#lines+1] = {'%s = {%s}', key, table_concat(values, ', ')}
end

function mt:key2id(code, key)
    local id = keydata[code] and keydata[code][key] or keydata['common'][key]
    return id
end

function mt:get_comment(id)
	local comment = metadata[id].displayname
	return self.w2l:editstring(comment):gsub('^%s*(.-)%s*$', '%1')
end

return function (w2l, type, data)
	local tbl = setmetatable({}, mt)
	tbl.lines = {}
	tbl.w2l = w2l
	tbl.remove_unuse_object = w2l.config.remove_unuse_object
	metadata = w2l:read_metadata(type)
	keydata = w2l:keyconvert(type)
	tbl.file_name = type
	tbl:add_chunk(data, type)
	return table_concat(tbl.lines, '\r\n')
end
