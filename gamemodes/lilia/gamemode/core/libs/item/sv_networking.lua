util.AddNetworkString("liaCharacterInvList")
util.AddNetworkString("liaItemDelete")
util.AddNetworkString("liaItemInstance")

netstream.Hook("invAct", function(client, action, item, invID, data)
	local character = client:getChar()
	if (not character) then
		return
	end

	-- Refine item into an instance
	local entity
	if (isentity(item)) then
		if (not IsValid(item)) then
			return
		end
		if (item:GetPos():Distance(client:GetPos()) > 96) then
			return
		end
		if (not item.liaItemID) then
			return
		end
		entity = item
		item = lia.item.instances[item.liaItemID]
	else
		item = lia.item.instances[item]
	end
	if (not item) then
		return
	end
	-- Permission check with inventory. Or, if no inventory exists,
	-- the player has no way of accessing the item.
	local inventory = lia.inventory.instances[item.invID]
	local context = {
		client = client, item = item, entity = entity, action = action
	}
	if (
		inventory and not inventory:canAccess("item", context)
	) then
		return
	end

	item:interact(action, client, entity, data)
end)
