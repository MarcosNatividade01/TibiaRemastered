-- Targuna secondary tasks: completion hooks.
-- Daily Reward: detected when the daily reward "next reward time" storage is written (on claim).
-- Stash an Item / Take from Stash: detected via the playerOnStowItem / playerOnStashWithdraw
-- engine events (added in src/: Player::stowItem and Game::playerStashWithdraw).
local DAILY_REWARD_TASK = Storage.Quest.U15_24.Targuna.SecondaryTasks.DailyReward
local STASH_ITEM_TASK = Storage.Quest.U15_24.Targuna.SecondaryTasks.StashItem
local TAKE_FROM_STASH_TASK = Storage.Quest.U15_24.Targuna.SecondaryTasks.TakeFromStash

-- DailyReward.storages.nextRewardTime (see data/modules/scripts/daily_reward/daily_reward.lua)
local DAILY_REWARD_NEXT_TIME = 14899

local dailyRewardTask = EventCallback("TargunaDailyRewardTask")

function dailyRewardTask.playerOnStorageUpdate(player, key, value, oldValue, currentFrameTime)
	if key ~= DAILY_REWARD_NEXT_TIME then
		return
	end
	if not value or value <= 0 or value == oldValue then
		return
	end
	if player:getStorageValue(DAILY_REWARD_TASK) == 1 then
		player:setStorageValue(DAILY_REWARD_TASK, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Quest task complete: you claimed your daily reward.")
	end
end

dailyRewardTask:type("playerOnStorageUpdate")
dailyRewardTask:register()

-- The current 15.24 Remastered engine does not expose the upstream
-- playerOnStowItem/playerOnStashWithdraw EventCallback hooks. Keep these
-- secondary tasks disabled in sandbox instead of registering invalid callbacks.
local TARGUNA_STASH_TASKS_DISABLED = {
	stashItemTask = STASH_ITEM_TASK,
	takeFromStashTask = TAKE_FROM_STASH_TASK,
	reason = "Missing EventCallback hooks: playerOnStowItem/playerOnStashWithdraw",
}
