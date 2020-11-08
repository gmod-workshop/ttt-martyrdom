AddCSLuaFile()

if SERVER then
    resource.AddWorkshop("1324649928")

    util.AddNetworkString("ttt_martyrdom_bought")
else
    LANG.AddToLanguage("english", "martyrdom_perk_name", "Martyrdom")
    LANG.AddToLanguage("english", "martyrdom_perk_desc", "Drops a live grenade upon your death!\n")
    LANG.AddToLanguage("english", "martyrdom_perk_corpse", "This body had a live grenade on it!\n")
end

ITEM.hud = Material("vgui/ttt/item_hud_effect_martyrdom.png")
ITEM.EquipMenuData = {
	type = "item_passive",
	name = "martyrdom_perk_name",
	desc = "martyrdom_perk_desc",
}
ITEM.material = "vgui/ttt/exho_martyrdom.png"
ITEM.CanBuy = {ROLE_DETECTIVE, ROLE_TRAITOR}
ITEM.corpseDesc = "martyrdom_perk_corpse"
ITEM.oldId = EQUIP_MARTYR

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

                if IsValid(ply) then
                    ply.shouldmartyr = false -- No need to explode again, you have fufilled your purpose
                end
            end)
        end
    end)

    hook.Add("TTTPrepareRound", "TTTMartyrdomPerk", function()
        for k, v in pairs(player.GetAll()) do
            v.shouldmartyr = false
        end
    end)

    function ITEM:Bought(ply)
        ply.shouldmartyr = true
        net.Start("ttt_martyrdom_bought")
        net.WriteBool(true)
        net.Send(ply)
    end
end

if CLIENT then
    net.Receive("ttt_martyrdom_bought", function()
        local bought = net.ReadBool()
        if not bought then return end
        chat.AddText("Martyrdom: ", Color(255, 255, 255), "You will drop a live grenade upon death.")
        chat.PlaySound()
    end)
end
