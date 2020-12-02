local utils = {}

local base_script_path = '/home/we/dust/code/pigeons/scripts/'

utils.tail = function (t, start)
    start = start or 2
    if type(t) ~= 'table' or #t == 0 then return {} end

    local result = {}
    for i=2,#t do
        table.insert(result, t[i])
    end
    return result
end

utils.warn = function (...)
    print("warn:", ...)
end

utils.table_to_string = function (table, depth)
    depth = depth or 0

    if type(table) == 'string' or type(table) == 'number' then
        return table
    elseif table == nil then
        return "(nil)"
    elseif type(table) == 'string' then
        return "("..type(table)..")"
    end

    local str = '{\n'
    local indent = ''
    -- TODO: find a string function that does this for me
    for i = 1, depth do
        indent = indent.."  "
    end

    if #table > 0 then
        -- array
        for i=1, #table do
            str = str..'\n'..indent.."  "
            str = str..utils.table_to_string(table[i], depth + 1)..'\n'
        end
    else
        -- dict
        for k, v in pairs(table) do
            str = str..'\n'..indent.."  "
            if type(k) ~= 'number' then
                str = str..k..' = '
            end
            str = str..utils.table_to_string(v, depth + 1)..'\n'
        end
    end
    return str..indent..'}'
end

utils.lisp_to_table = function (sexpr)
    -- wrap words in single quotes (end w/ digit(s) is OK)
    sexpr = string.gsub(sexpr, '([^%(%)0-9%s][^%(%)%s]*)', "'%0'")
    -- so hacky.
    sexpr = string.gsub(sexpr, '"false"', 'false')
    sexpr = string.gsub(sexpr, '"true"', 'true')
    -- parens to curlies
    sexpr = string.gsub(sexpr, '%(', '{')
    sexpr = string.gsub(sexpr, '%)', '}')
    -- contiguous whitespace to single comma
    sexpr = string.gsub(sexpr, '%s+', ',')
    
    local fn, err = load('return '..sexpr)
    if err then
        error("error loading "..filename..":\n"..err)
    end

    return fn()
end

utils.load_lisp_file = function (filename)
    local file = io.open(base_script_path..filename, 'r')
    io.input(file)
    local contents = io.read('*all')
    -- io.close() -- this keeps complaining, I'm just gonna ignore it for now lol

    return utils.lisp_to_table(contents)
end

return utils
