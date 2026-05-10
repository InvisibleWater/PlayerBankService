--[=[
	@class PlayerBankService
]=]

local require = require(script.Parent.loader).load(script)

local Maid = require("Maid")
local ObservableCountingMap = require("ObservableCountingMap")
local PlayerDataStoreService = require("PlayerDataStoreService")
local ServiceBag = require("ServiceBag")

local PlayerBankService = {}
PlayerBankService.ServiceName = "PlayerBankService"

export type PlayerBankService = typeof(setmetatable(
	{} :: {
		_maid: Maid.Maid,
		_currency: ObservableCountingMap.ObservableCountingMap<Player>,
		_playerDataStoreService: PlayerDataStoreService.PlayerDataStoreService
	},
	{} :: typeof({__index = PlayerBankService})
))

function PlayerBankService.Init(self: PlayerBankService, serviceBag: ServiceBag.ServiceBag)
	self._maid = Maid.new()
	self._currency = self._maid:Add(ObservableCountingMap.new())
	self._playerDataStoreService = serviceBag:GetService(PlayerDataStoreService)
end

function PlayerBankService.Start(self: PlayerBankService)
	self._maid:GivePromise()
end

return PlayerBankService