if TTT2 then return end

AddCSLuaFile()

CreateConVar("ttt_martyrdom_detective", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Detectives be able to buy the Martyrdom Perk?")
CreateConVar("ttt_martyrdom_traitor", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Should Traitors be able to buy the Martyrdom Perk?")
CreateConVar("ttt_martyrdom_detective_loadout", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Should Detectives have the Martyrdom Perk in their loadout?")
CreateConVar("ttt_martyrdom_traitor_loadout", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, "Should Traitors have the Martyrdom Perk in their loadout?")

if SERVER then
    resource.AddWorkshop("1324649928")

    util.AddNetworkString("ttt_martyrdom_bought")
else
    LANG.AddToLanguage("english", "martyrdom_perk_name", "Martyrdom")
    LANG.AddToLanguage("english", "martyrdom_perk_desc", "Drops a live grenade upon your death!\n")
end

EQUIP_MARTYR = GenerateNewEquipmentID and GenerateNewEquipmentID() or 66

local perk = {
	id = EQUIP_MARTYR,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/exho_martyrdom.png",
	name = "martyrdom_perk_name",
	desc = "martyrdom_perk_desc",
	hud = true
}

if (GetConVar("ttt_martyrdom_detective"):GetBool()) then
	if SERVER then
		perk["loadout"] = GetConVar("ttt_martyrdom_detective_loadout"):GetBool()
	end

	table.insert(EquipmentItems[ROLE_DETECTIVE], perk)
end

if (GetConVar("ttt_martyrdom_traitor"):GetBool()) then
	if SERVER then
		perk["loadout"] = GetConVar("ttt_martyrdom_traitor_loadout"):GetBool()
	end

	table.insert(EquipmentItems[ROLE_TRAITOR], perk)
end

if SERVER then
    hook.Add("PlayerDeath", "TTTMartyrdomPerk", function(ply, infl, att)
        if ply.shouldmartyr then
            local proj = "ttt_martyr_proj" -- Create our grenade
            local martyr = ents.Create(proj)
            martyr:SetPos(ply:GetPos())
            martyr:SetAngles(ply:GetAngles())
            martyr:Spawn()
            martyr:SetThrower(ply) -- Someone has to be accountible for this tragedy!
            martyr:EmitSound("martyrdom/grenade_bounce.mp3")
            local spos = ply:GetPos()

            local tr = util.TraceLine({
                start = spos,
                endpos = spos + Vector(0, 0, -32),
                mask = MASK_SHOT_HULL,
                filter = ply
            })

            timer.Simple(3, function()
                martyr:Explode(tr)
                ply.shouldmartyr = false -- No need to explode again, you have fufilled your purpose
            end)
        end
    end)

    hook.Add("TTTOrderedEquipment", "TTTMartyrdomPerk", function(ply, id, is_item)

        if id == EQUIP_MARTYR then
            ply.shouldmartyr = true -- So we set a boolean on the player
            net.Start("ttt_martyrdom_bought")
            net.WriteBool(true)
            net.Send(ply)
        end
    end)

    hook.Add("TTTPrepareRound", "TTTMartyrdomPerk", function()
        for k, v in pairs(player.GetAll()) do
            v.shouldmartyr = false
        end
    end)
end

if CLIENT then
    -- feel for to use this function for your own perk, but please credit me
    -- your perk needs a "hud = true" in the table, to work properly
    local defaultY = ScrH() / 2 + 20

    local function getYCoordinate(currentPerkID)
        local amount, i, perk = 0, 1

        while (i < currentPerkID) do
            perk = GetEquipmentItem(LocalPlayer():GetRole(), i)

            if (istable(perk) and perk.hud and LocalPlayer():HasEquipmentItem(perk.id)) then
                amount = amount + 1
            end

            i = i * 2
        end

        return defaultY - 80 * amount
    end

    local yCoordinate = defaultY

    -- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
    hook.Add("TTTBoughtItem", "TTTMartyrdomPerk", function()
        if (LocalPlayer():HasEquipmentItem(EQUIP_MARTYR)) then
            yCoordinate = getYCoordinate(EQUIP_MARTYR)
        end
    end)

    -- draw the HUD icon
    local material = Material("vgui/ttt/perks/martyrdom_perk_hud.png")

    hook.Add("HUDPaint", "TTTMartyrdomPerk", function()
        if (LocalPlayer():HasEquipmentItem(EQUIP_MARTYR)) then
            surface.SetMaterial(material)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(20, yCoordinate, 64, 64)
        end
    end)

    net.Receive("ttt_martyrdom_bought", function()
        local bought = net.ReadBool()
        if not bought then return end
        chat.AddText("Martyrdom: ", Color(255, 255, 255), "You will drop a live grenade upon death.")
        chat.PlaySound()
    end)
end
