--[=[
	@class PlayerBankService
]=]

local require = require(script.Parent.loader).load(script)

local Maid = require("Maid")
local ObservableCountingMap = require("ObservableCountingMap")
local PlayerDataStoreService = require("PlayerDataStoreService")
local RxPlayerUtils = require("RxPlayerUtils")
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
	self._maid:GiveTask(RxPlayerUtils.observePlayersBrio():Subscribe(function(brio)
		local maid, player = brio:ToMaidAndValue()

		maid:GivePromise(self._playerDataStoreService:PromiseDataStore(player)):Then(function(dataStore)
			local subStore = dataStore:GetSubStore("Stats")

			maid:GivePromise(subStore:Load("Credits", 0)):Then(function(credits)
				maid:GiveTask(self._currency:Set(player, credits))
			end, function()
				warn("Could not load money. Using defaults for this session.")
			end)

			maid:GiveTask(self._currency:ObserveAtKey(player):Subscribe(function(credits)
				subStore:Store("Credits", credits)
			end))
		end)
	end))
end

function PlayerBankService.Deposit(self: PlayerBankService, player: Player, credits: number): () -> ()
	return self._currency:Add(player, credits)
end

function PlayerBankService.Withdraw(self: PlayerBankService, player: Player, credits: number): () -> ()
	return self._currency:Remove(player, credits)
end

function PlayerBankService.SetPlayerCredits(self: PlayerBankService, player: Player, credits: number): () -> ()
	return self._currency:Set(player, credits)
end

function PlayerBankService.ObservePlayerCredits(self: PlayerBankService, player: Player)
	return self._currency:ObserveAtKey(player)
end

function PlayerBankService.ObserveAllCreditsBrio(self: PlayerBankService)
	return self._currency:ObservePairsBrio()
end

function PlayerBankService.Destroy(self: PlayerBankService)
	self._maid:DoCleaning()
end

return PlayerBankService