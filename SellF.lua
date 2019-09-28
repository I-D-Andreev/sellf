message("ah search sort")

local mats_array = {"Monelite Ore", "Storm Silver Ore", "Platinum Ore", "Osmenite Ore",
                    "Riverbud", "Sea Stalk", "Star Moss", "Akunda's Bite", "Winter's Kiss",
                    "Siren's Pollen", "Zin'anthid", "Anchor Weed"}

local prices = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:SetScript("OnEvent", function(self, event, ...)
    -- Set the AH to show smallest unit price first
    SortAuctionClearSort("list")
    SortAuctionSetSort("list", "unitprice", false)
    SortAuctionApplySort("list")

    scanAH(1)
end)


function scanAH(itemNumber) -- starting from 1; defined in the array at the top 
    if(itemNumber>table.getn(mats_array)) then
        return
    end

    print("Scanning for item: "..mats_array[itemNumber])
    QueryAuctionItems(mats_array[itemNumber], nil, nil, 0, false, 0, false, false, nil)
    C_Timer.After(3, function() getPrice(itemNumber) end)
    C_Timer.After(4, function() scanAH(itemNumber+1) end)
end

function getPrice(itemID)
    local name, _, count, _, _, _, _,minBid,_,buyoutPrice, _, _, _, owner, _, saleStatus, _, _=GetAuctionItemInfo("list", 1)
    prices[mats_array[itemID]] = buyoutPrice/count
    print(name.."  -  "..buyoutPrice/count)
end

-- API 

-- QueryAuctionItems(name, minLevel, maxLevel, page,
--   isUsable, qualityIndex, getAll, exactMatch, filterData
-- )
-- https://wowwiki.fandom.com/wiki/API_QueryAuctionItems


-- GetAuctionItemInfo
-- local name, texture, count, quality, canUse, level, levelColHeader, minBid,
-- minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
-- ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("type", index)