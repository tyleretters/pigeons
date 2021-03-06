local m = {}

-- these should both be env things
m.logs = {}
m.listeners = {}
    -- [ ] UI?
    -- [ ] app-level (load, save, init, etc.)?
    -- [ ] HID
    -- [ ] crow?
    -- [x] MIDI
    -- [x] knob/enc

local max_log_size = 9
local spinner_max_index1 = 12
local spinner_max_index2 = 8
local spinner_index1 = 0
local spinner_index2 = 0

m.log = function (msg)
    -- gross, but... yeah. this was the best place for now
    if msg.message_type == 'midi' and msg.type == 'clock' then 
        return 
    end

    if #m.logs >= max_log_size then
        table.remove(m.logs, 1)
    end
    table.insert(m.logs, { 
        message=msg, 
        spinner_index1=spinner_index1, 
        spinner_index2=spinner_index2 
    })
    spinner_index1 = (spinner_index1 + 1) % spinner_max_index1
    spinner_index2 = (spinner_index2 + 1) % spinner_max_index2
end

-- may need responsibilities split somewhat
-- I'm legit making up origins as I go. hope that's not a problem lol.
-- DON'T OVERTHINK IT, KID
m.transmit = function (message_type, msg, origin)
    -- getting time *immediately* is good for latency
    local now = util.time()
    msg = msg or {}

    msg.now = now
    msg.message_type = message_type
    msg.origin = origin or msg.origin or "lua"

    if not message_type then
        Utils.warn("message has no type, ignoring")
        return false
    end

    local handlers = m.listeners[message_type]
    if not handlers then
    -- nah, this is problematic for lensing
    --    Utils.warn("message", message_type, "not identified, ignoring")
    --    return false

        handlers = {} -- purely to avoid error on #handlers
        -- print('no handlers for '..message_type)
    end

    -- it might be good to bring your own env...
    -- for inheritance, and stuff
    local l = Lisp.fork(msg)

    -- something feels off here
    -- I think because we're doing lisp things in the message area
    for i = 1,#handlers do
        local derp = l.exec(handlers[i], l)
    end

    m.log(msg)
    -- this is very tacky. I don't like it.
    _Ui.dirty = true
end

-- TODO: implement in lisp so we can utilize environment
--       this will be useful when e.g. switching modes (and envs)
m.attach = function (message_type, handler)
    if type(handler) == 'string' then handler = { handler } end
    if m.listeners[message_type] == nil then m.listeners[message_type] = {} end

    --[[ to avoid dupes, might convert to string
    (e.g. s-expression)  & check collisions ]]
    table.insert(m.listeners[message_type], handler)
end

-- this may be unnecessary
-- it is useful for discoverability though
m.identify = function (name)
    if m.listeners[name] ~= nil then
        Utils.warn("message", name, "already identified")
        return false
    end
    m.listeners[name] = {}
    return true
end

return m
