local remasteredAdminPanel = GlobalEvent("RemasteredAdminPanelTests")

function remasteredAdminPanel.onThink(interval, lastExecution)
	if Remastered and Remastered.AdminBalanceTests and Remastered.AdminBalanceTests.processPanelRequest then
		Remastered.AdminBalanceTests.processPanelRequest()
	end
	return true
end

remasteredAdminPanel:interval(2000)
remasteredAdminPanel:register()
