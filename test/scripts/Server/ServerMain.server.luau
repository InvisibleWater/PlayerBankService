--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.playerbank)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("PlayerBankService"))
serviceBag:Init()
serviceBag:Start()