PLUGIN.name = "Attributes"
PLUGIN.author = "Leonheart#7476/Cheesenot"
PLUGIN.desc = "Adds attributes for characters."

lia.util.include("sh_commands.lua")

lia.config.add(
	"maxAttribs",
	30,
	"The total maximum amount of attribute points allowed.",
	nil,
	{
		data = {min = 1, max = 250},
		category = "characters"
	}
)

lia.char.registerVar("attribs", {
	field = "_attribs",
	default = {},
	isLocal = true,
	index = 4,
	onValidate = function(value, data, client)
		if (value ~= nil) then
			if (istable(value)) then
				local count = 0

				for k, v in pairs(value) do
					local max = lia.attribs.list[k] and lia.attribs.list[k].startingMax or nil
					if max and max < v then return false, lia.attribs.list[k].name .. " too high" end
					count = count + v
				end
				local points = hook.Run("GetStartAttribPoints", client, count)
					or lia.config.get("maxAttribs", 30)
				if (count > points) then
					return false, "unknownError"
				end
			else
				return false, "unknownError"
			end
		end
	end,
	shouldDisplay = function(panel) return table.Count(lia.attribs.list) > 0 end
})

if (SERVER) then
	function PLUGIN:PostPlayerLoadout(client)
		lia.attribs.setup(client)
	end

	function PLUGIN:OnCharAttribBoosted(client, character, attribID)
		local attribute = lia.attribs.list[attribID]
		if (attribute and isfunction(attribute.onSetup)) then
			attribute:onSetup(client, character:getAttrib(attribID, 0))
		end
	end
else
	function PLUGIN:CreateCharInfoText(panel, suppress)
		if (suppress and suppress.attrib) then return end
		panel.attribName = panel.info:Add("DLabel")
		panel.attribName:Dock(TOP)
		panel.attribName:SetFont("liaMediumFont")
		panel.attribName:SetTextColor(color_white)
		panel.attribName:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		panel.attribName:DockMargin(0, 10, 0, 0)
		panel.attribName:SetText(L"attribs")

		panel.attribs = panel.info:Add("DScrollPanel")
		panel.attribs:Dock(FILL)
		panel.attribs:DockMargin(0, 10, 0, 0)
	end

	function PLUGIN:OnCharInfoSetup(panel)
		if (not IsValid(panel.attribs)) then return end
		local char = LocalPlayer():getChar()
		local boost = char:getBoosts()

		for k, v in SortedPairsByMemberValue(lia.attribs.list, "name") do
			local attribBoost = 0
			if (boost[k]) then
				for _, bValue in pairs(boost[k]) do
					attribBoost = attribBoost + bValue
				end
			end

			local bar = panel.attribs:Add("liaAttribBar")
			bar:Dock(TOP)
			bar:DockMargin(0, 0, 0, 3)

			local attribValue = char:getAttrib(k, 0)
			if (attribBoost) then
				bar:setValue(attribValue - attribBoost or 0)
			else
				bar:setValue(attribValue)
			end

			local maximum = v.maxValue or lia.config.get("maxAttribs", 30)
			bar:setMax(maximum)
			bar:setReadOnly()
			bar:setText(
				Format(
					"%s [%.1f/%.1f] (%.1f",
					L(v.name),
					attribValue,
					maximum,
					attribValue/maximum*100
				)
				.."%)"
			)

			if (attribBoost) then
				bar:setBoost(attribBoost)
			end
		end
	end

	function PLUGIN:ConfigureCharacterCreationSteps(panel)
		panel:addStep(vgui.Create("liaCharacterAttribs"), 99)
	end
end
