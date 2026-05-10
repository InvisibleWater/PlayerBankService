--!strict
--[=[
	Singleton for centralized handling of in-game currency in Roblox games.
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

--[=[
	Initializes the service. Should be handled via ServiceBag.

	@param serviceBag ServiceBag
]=]
function PlayerBankService.Init(self: PlayerBankService, serviceBag: ServiceBag.ServiceBag): ()
	self._maid = Maid.new()
	self._currency = self._maid:Add(ObservableCountingMap.new())
	self._playerDataStoreService = serviceBag:GetService(PlayerDataStoreService :: any)
end

--[=[
	Starts the service's internal logic, including loading the players' last saved currency value. Should be handled via ServiceBag.
]=]
function PlayerBankService.Start(self: PlayerBankService): ()
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

--[=[
	Adds a given amount to a player's balance.

	@param player Player
	@param credits number
	@return callback
]=]
function PlayerBankService.Deposit(self: PlayerBankService, player: Player, credits: number): () -> ()
	return self._currency:Add(player, credits)
end

--[=[
	Removes a given amount from a player's balance.

	@param player Player
	@param credits number
	@return callback
]=]
function PlayerBankService.Withdraw(self: PlayerBankService, player: Player, credits: number): () -> ()
	return self._currency:Remove(player, credits)
end

--[=[
	Sets a player's balance to a given amount.

	@param player Player
	@param credits number
	@return callback
]=]
function PlayerBankService.SetPlayerCredits(self: PlayerBankService, player: Player, credits: number): () -> ()
	return self._currency:Set(player, credits)
end

--[=[
	Returns the provided player's balance.

	@param player Player
	@return number
]=]
function PlayerBankService.GetPlayerCredits(self: PlayerBankService, player: Player): number
	return self._currency:Get(player)
end

--[=[
	Creates an Observable that emits the current balance of the given player.

	@param player Player
	@return Observable<number>
]=]
function PlayerBankService.ObservePlayerCredits(self: PlayerBankService, player: Player)
	return self._currency:ObserveAtKey(player)
end

--[=[
	Creates an Observable that emits all updates to all balances as key-value pairs wrapped in Brios.

	@param player Player
	@return Observable<Brio<number>>
]=]
function PlayerBankService.ObserveAllCreditsBrio(self: PlayerBankService)
	return self._currency:ObservePairsBrio()
end

--[=[
	Cleans up the service. Should be handled via ServiceBag.
]=]
function PlayerBankService.Destroy(self: PlayerBankService): ()
	self._maid:DoCleaning()
end

return PlayerBankService