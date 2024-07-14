--[[Ulysse94]]--

local speedSign = function(model:PVInstance, informations):nil
    local speed:number|string = informations.Speed
    local speedText:TextLabel = model:FindFirstChild("SpeedSignText", true)

    speedText.Text = speed
end