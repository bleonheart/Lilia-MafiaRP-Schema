ITEM.name = "A Tie"
ITEM.desc = "A Plastic Cable used for restraining a player"
ITEM.price = 50
ITEM.model = "models/items/crossbowrounds.mdl"

ITEM.functions.Use = {
    onRun = function(item)
        if item.beingUsed then return false end
        local client = item.player
        local data = {}
        data.start = client:GetShootPos()
        data.endpos = data.start + client:GetAimVector() * 96
        data.filter = client
        local target = util.TraceLine(data).Entity

        if IsValid(target) and target:IsPlayer() and target:Team() == FACTION_STAFF then
            target:notify("You were just attempted to be restrained by " .. client:Name() .. ".")
            client:notify("You can't tie a staff member!")

            return false
        end

        if IsValid(target) and target:IsPlayer() and target:getChar() and not target:getNetVar("tying") and not target:getNetVar("restricted") then
            item.beingUsed = true
            client:EmitSound("physics/plastic/plastic_barrel_strain" .. math.random(1, 3) .. ".wav")
            client:setAction("tying", 5)

            client:doStaredAction(target, function()
                target:setRestrictedTying(true)
                target:setNetVar("tying")
                client:EmitSound("npc/barnacle/neck_snap1.wav", 100, 140)
            end, 5, function()
                client:setAction()
                target:setAction()
                target:setNetVar("tying")
                item.beingUsed = false
            end)

            target:setNetVar("tying", true)
            target:setAction("beingTied", 5)
        else
            item.player:notifyLocalized("plyNotValid")
        end
    end,
    onCanRun = function(item)
        return not IsValid(item.entity)
    end,
    icon = "icon16/cog.png"
}

function ITEM:onCanBeTransfered(inventory, newInventory)
    return not self.beingUsed
end