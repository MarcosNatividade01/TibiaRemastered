local balanceTest = TalkAction("/testbalance", "/testxp", "/testskill", "/testloot")

function balanceTest.onSay(player, words, param)
	if not Remastered or not Remastered.AdminBalanceTests then
		player:sendCancelMessage("Remastered admin balance tests are not loaded.")
		return true
	end
	return Remastered.AdminBalanceTests.handleCommand(player, words, param)
end

balanceTest:separator(" ")
balanceTest:groupType("god")
balanceTest:register()
