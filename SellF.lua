message("ah result")

local ah_opened_event = "AUCTION_HOUSE_SHOW"
local frame = CreateFrame("Frame")
frame:RegisterEvent(ah_opened_event)
frame:SetScript("OnEvent", function(self, event, ...)
    print("AH opened")
    local canQuery,canQueryAll = CanSendAuctionQuery()
    if canQuery then 
        QueryAuctionItems("Osmenite Ore", nil, nil, 0, nil, 0, false, false, nil)
    else 
        print("Can't query the AH")
    end

    if canQueryAll then 
        print("Can query ALL the AH") 
   else 
       print("Can't query ALL the AH")
   end
   -- /script QueryAuctionItems("Osmen", nil, nil, 0, nil, 0, false, false, nil)
end)

-- local printResult = ""
-- for _,v in ipairs(arg) do
--     printResult = printResult .. tostring(v) .. "  "
-- end
-- print(printResult)



-- API 

-- QueryAuctionItems(name, minLevel, maxLevel, page,
--   isUsable, qualityIndex, getAll, exactMatch, filterData
-- )
-- https://wowwiki.fandom.com/wiki/API_QueryAuctionItems
