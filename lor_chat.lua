--[[
    Chat log printing / output functions
    Author: Ragnarok.Lorand
--]]

local lor_chat = {}
lor_chat._author = 'Ragnarok.Lorand'
lor_chat._version = '2016.07.03'

require('lor/lor_utils')
_libs.req('maths', 'strings', 'tables')
_libs.lor.req('functional', 'strings', 'tables')
_libs.lor.chat = lor_chat


function atc(...)
    local args = T({...})
    local c = 0
    if type(args[1]) == 'number' then
        c = args[1]
        args = args:slice(2)
    end
    local msg = lor.G.windower.to_shift_jis(" ":join(args))
    lor.G.windower.add_to_chat(c, msg)
end


function atcc(...)
    local args = T({...})
    local c = 0
    if type(args[1]) == 'number' then
        c = args[1]
        args = args:slice(2)
    end
    local msg = lor.G.windower.to_shift_jis(" ":join(args))
    lor.G.windower.add_to_chat(0, msg:colorize(c))
end


function atcs(msg)
    lor.G.windower.add_to_chat(0, windower.to_shift_jis(tostring(msg)))
end


function atcd(c, msg)
    if show_debug then
        atc(c, msg)
    end
end


--[[
    Formatted Add to Chat - The first arg is used as the color if it's numeric.
    The next argument is used as the format string, and remaining arguments
    are passed in to be formatted in the string.
--]]
function atcf(...)
    local args = T({...})
    local c = 0
    if type(args[1]) == 'number' then
        c = args[1]
        args = args:slice(2)
    end
    
    --local msg = (#args < 2) and tostring(args[1]) or args[1]:format(unpack(args:slice(2)))
    local msg
    if #args < 2 then
        msg = tostring(args[1])
    else
        msg = args[1]:format(unpack(args:slice(2)))
        --lor.G.windower.add_to_chat(c, string.format(args[1], unpack(args:slice(2))))
    end
    lor.G.windower.add_to_chat(c, lor.G.windower.to_shift_jis(msg))
end


--[[
    String-Formatted Add to Chat - Works as atcf above, but all args are
    converted to strings before being passed in to string.format.
--]]
function atcfs(...)
    local args = T({...})
    local c = 0
    if type(args[1]) == 'number' then
        c = args[1]
        args = args:slice(2)
    end
    
    local msg
    if #args < 2 then
        msg = tostring(args[1])
    else
        --lor.G.windower.add_to_chat(c, string.format(args[1], unpack(map(tostring, args:slice(2)))))
        msg = args[1]:format(unpack(map(tostring, args:slice(2))))
    end
    lor.G.windower.add_to_chat(c, lor.G.windower.to_shift_jis(msg))
end


function echo(msg)
    if (msg ~= nil) then
        local prefix = ''
        if _addon and _addon.name then
            prefix = '['.._addon.name..']'
        end
        windower.send_command('echo %s%s':format(prefix, msg))
    end
end


local function fmt_output(s, w)
    local sp = ' ':rep(w - tostring(s):wlen())
    return s..sp
end


--[[
    Pretty Print the given object, optionally with a header line
--]]
function _pprint(obj, header)
    if obj ~= nil then
        if header ~= nil then
            atc(2, header)
        end
        if type(obj) == 'table' then
            if sizeof(obj) < 1 then
                atc('{}')
                return
            end
            local c = 0
            local lwkl = max(unpack(map(string.wlen, table.keys(obj))))
            local fmt = '%s :  %s'
            for k,v in opairs(obj) do
                if (c ~= 0) and ((c % 30) == 0) then
                    atc(160,'---------- ('..c..') ----------')
                end
                atcfs(fmt, fmt_output(k, lwkl), v)
                c = c + 1
            end
        else
            atc(0, tostring(obj))
        end
    else
        atc(0, tostring(obj))
    end
end


local function print_indented_array(arr, indent)
    indent = (type(indent) == 'string') and indent or ' ':rep(indent)
    --local indented = {}
    local tbl = table.copy(arr)
    table.sort(tbl)
    local tmp, i = indent, 0
    for k,v in ipairs(map(tostring, tbl)) do
        if (i > 0) and (#tmp + #v) > 190 then
            --table.insert(indented, tmp)
            atc(0, tmp)
            tmp, i = indent, 0
        end
        if i > 0 then tmp = tmp..' ' end
        tmp = tmp..v
        if k < #tbl then tmp = tmp..',' end
        i = i + 1
    end
    --table.insert(indented, tmp)
    --return indented
end


function pprint_tiered(obj, header, lead_width, depth)
    if header ~= nil then
        atc(2, header)
    end
    if lor.G.rawequal(obj, _G) then
        _pprint(obj)
        return
    end

    local default_depth = 3
    depth = depth and (depth - 1) or default_depth
    lead_width = lead_width and (lead_width + 6) or 0
    local indent = ' ':rep(lead_width)
    if obj ~= nil then
        if type(obj) == 'table' then
            local lwkl = max(unpack(map(string.wlen, table.keys(obj))))
            local fmt = indent..'%s :  %s'
            for k,v in opairs(obj) do
                if not lor.G.rawequal(obj, v) then   --Skip _G._G
                    local fk = fmt_output(k, lwkl)
                    if type(v) == 'table' then
                        if depth > 1 then
                            if table.has_nested(v) then
                                local k1,v1 = table.first_pair(v)
                                if (sizeof(v) == 1) and (type(v1) == 'table') and (sizeof(v1) == 0) then
                                    atcfs(0, fmt, fk, '{%s}':format(', ':join(table.kv_strings(v))))
                                else
                                    atcfs(0, fmt, fk, '{')
                                    pprint_tiered(v, nil, lead_width + lwkl, depth)
                                    atc(0, indent, ' ':rep(lwkl-1), '}')
                                end
                            elseif table.is_array(v) then
                                local arrstr = '{%s}':format(', ':join(v))
                                arrstr = fmt:format(fk, arrstr)
                                if arrstr:wlen() > 190 then
                                    atcfs(0, fmt, fk, '{')
                                    print_indented_array(v, lead_width + lwkl)
                                    atc(0, indent, ' ':rep(lwkl-1), '}')
                                else
                                    atc(0, arrstr)
                                end
                            else
                                local kvstr = '{%s}':format(', ':join(table.kv_strings(v)))
                                kvstr = fmt:format(fk, kvstr)
                                if kvstr:wlen() > 190 then
                                    atcfs(0, fmt, fk, '{')
                                    pprint_tiered(v, nil, lead_width + lwkl, depth)
                                    atc(0, indent, ' ':rep(lwkl-1), '}')
                                else
                                    atc(0, kvstr)
                                end
                            end
                        else
                            if table.is_array(v) then
                                local arrstr = '{%s}':format(', ':join(v))
                                arrstr = fmt:format(fk, arrstr)
                                if arrstr:wlen() > 190 then
                                    atcfs(0, fmt, fk, '{')
                                    print_indented_array(v, lead_width + lwkl)
                                    atc(0, indent, ' ':rep(lwkl-1), '}')
                                else
                                    atc(0, arrstr)
                                end
                            else
                                local kvstr = '{%s}':format(', ':join(table.kv_strings(v)))
                                kvstr = fmt:format(fk, kvstr)
                                if kvstr:wlen() > 190 then
                                    atcfs(0, fmt, fk, v)
                                else
                                    atc(0, kvstr)
                                end
                            end
                        end
                    else
                        atcfs(0, fmt, fk, v)
                    end
                end
            end
        else
            atc(0, indent..tostring(obj))
        end
    else
        atc(0, indent..tostring(obj))
    end
end

pprint = _pprint

return lor_chat

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2016, Ragnarok.Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of libs/lor nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------
