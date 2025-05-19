#!/usr/bin/env lua


-- Want to note something right here, because of the way this is all setup it only works with unix like OSes
-- and has only actually been tested with linux (Debian Bookworm), so if it works on macintosh or bsd, its a fucking miracle

local socket = require("socket")
local http = require ("socket.http")
local ltn12 = require("ltn12")

-- define target (this can either be an ip or ul, it doesnt matter)
local target = arg[1]
if not target then
    print("Usage: lua Poquer.lua <ip-or-url>")
    os.exit(1)
end







-- messy code, does what it says on the tin

function ping_host(host)
    local handle = io.popen("ping -c 4 " .. host)
    local result = handle:read("*a")
    handle:close()
    return result
end



local function run_command(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- DNS lookup
local function resolve_dns(host)
    print("\n[+] RESOLVING DNS...")
    local ip = socket.dns.toip(host)
    print("RESOLVED IP: " .. (ip or "N/A"))
    return ip
end

-- WHO TF IS YOU
local function whois_lookup(ip)
    print("\n[+] OBTAINING WHOIS LOOKUP INFO...")
    local result = run_command("whois " .. ip)
    print(result)
end

-- Ping#!/usr/bin/env lua, also, holy syntax lmao
local function port_scan(ip)
    print("\n[+] SCANNING COMMON PORTS...")
    local common_ports = {
        21, 22, 23, 25, 53, 80, 110, 143, 443, 3306, 3389
    }
    for _, port in ipairs(common_ports) do
        local conn = socket.tcp()
        conn:settimeout(1)
        local success, err = conn:connect(ip, port)
        if success then
            print("PORT: " .. port .. " IS OPEN")
        end
        conn:close()
    end
end

-- Get HTTP headers if web server
local function get_http_headers(host)
    print("\n[+] GETTING HTTP HEADERS...")
    local result = run_command("curl -I --max-time 3 http://" .. host)
    print(result)
end




-- Clipboard copy (Linux/xclip)
function copy_to_clipboard(text)
    local f = io.popen("xclip -selection clipboard", "w")
    if f then
        f:write(text)
        f:close()
        print("\n[Copied to clipboard]")
    else
        print("\n[Failed to copy to clipboard — is xclip installed?]")
    end
end

-- Save to file
function save_to_file(path, text)
    local f = io.open(path, "w")
    if f then
        f:write(text)
        f:close()
        print("\n[Saved to file: " .. path .. "]")
    else
        print("\n[Failed to save to file]")
    end
end





-- Main logic

function probe_host(target)
    local result = {}
    table.insert(result, "[*] TARGET: " .. target)

    local resolved_ip = socket.dns.toip(target) or target
    table.insert(result, "\n[+] RESOLVING DNS...")
    table.insert(result, "RESOLVED IP: " .. resolved_ip)

    table.insert(result, "\n[+] OBTAINING WHOIS LOOKUP INFO...")
    table.insert(result, run_command("whois " .. resolved_ip))

    table.insert(result, "\n[+] PINGING...")
    table.insert(result, ping_host(resolved_ip))

    table.insert(result, "\n[+] SCANNING COMMON PORTS...")
    local common_ports = { 21, 22, 23, 25, 53, 80, 110, 143, 443, 3306, 3389 }
    for _, port in ipairs(common_ports) do
        local conn = socket.tcp()
        conn:settimeout(1)
        local success, err = conn:connect(resolved_ip, port)
        if success then
            table.insert(result, "PORT: " .. port .. " IS OPEN")
        end
        conn:close()
    end

    table.insert(result, "\n[+] GETTING HTTP HEADERS...")
    table.insert(result, run_command("curl -I --max-time 3 http://" .. target))

    return table.concat(result, "\n")
end


-- Parse arguments
local target = arg[1]
if not target then
    print("Usage: lua Poquer.lua <ip-or-url> [-ctc] [-ctf <path>]")
    os.exit(1)
end

local output = probe_host(target)

-- Check for extra flags
for i = 2, #arg do
    if arg[i] == "-clip" then
        copy_to_clipboard(output)
    elseif arg[i] == "-wtf" and arg[i+1] then
        save_to_file(arg[i+1], output)
        i = i + 1
    end
end

print("\n--- SCAN RESULT ---\n" .. output)



-- PS: Fuck you apple for forcing people to buy your insanely expensive hardware and then on top of that forcing to compile to Xcode, if you want more third party apps on macintosh maybe dont make it as expensive and as time consuming as possible for people to develop on your platform. 
