ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Bacon Slice (Cooked)"
ENT.Author = "SaDow4100"
ENT.Contact = "Steam"
ENT.Purpose = "Bacon"
ENT.Instructions = "E" 
ENT.Category = "Food"

ENT.Spawnable			= true
ENT.AdminSpawnable		= true

function ENT:SetupModel()

	self.Entity:SetModel("models/FoodNHouseholdItems/baconcooked.mdl")
	
end