print("Sell fast loaded. Will scan on next AH opening.")
local SHOULD_SCAN_AH = true

local mats_array = {"Monelite Ore", "Storm Silver Ore", "Platinum Ore", "Osmenite Ore",
                    "Riverbud", "Sea Stalk", "Star Moss", "Akunda's Bite", "Winter's Kiss",
                    "Siren's Pollen", "Zin'anthid", "Anchor Weed"}

local prices = {}


------------------------------------
-----        SCANS AH         ------
------------------------------------
local itemNumber = 0;   -- defined in the array above, keeps track of which item we are currently scanning for
local already_updated_event = {}
local frame1 = CreateFrame("Frame")
frame1:RegisterEvent("AUCTION_HOUSE_SHOW")
frame1:SetScript("OnEvent", function(self, event, ...)
    if(SHOULD_SCAN_AH) then 
        -- Set the AH to show smallest unit price first
        SortAuctionClearSort("list")
        SortAuctionSetSort("list", "unitprice", false)
        SortAuctionApplySort("list")
        -- set variables
        itemNumber = 0
        for i=1, table.getn(mats_array) do already_updated_event[i] = false end
        queryAH()
    end
end)

function queryAH()
    local canQuery,_ = CanSendAuctionQuery()
    if canQuery then
        itemNumber = itemNumber + 1
        scanAH()
    else
        C_Timer.After(0.3, function() queryAH() end)
    end
end

function scanAH()
    if(itemNumber>table.getn(mats_array)) then
        print("--- Finished Scanning ---")
        SHOULD_SCAN_AH = false
        return
    end

    print("Scanning for item: "..mats_array[itemNumber])
    QueryAuctionItems(mats_array[itemNumber], nil, nil, 0, false, 0, false, false, nil) -- triggers event AUCTION_ITEM_LIST_UPDATE
end


local frame3 = CreateFrame("Frame")
frame3:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
frame3:SetScript("OnEvent", function(self, event, ...)
    -- event is triggered when QueryAuctionItems is called
    -- sometimes triggered twice, so already_updated_event[itemNumber] keeps track if has already been called
    if not already_updated_event[itemNumber] then 
        already_updated_event[itemNumber] = true
        getPrice()
    else
        return
    end
end)


function getPrice()
    local name, _, count, _, _, _, _,minBid,_,buyoutPrice, _, _, _, owner, _, saleStatus, _, _=GetAuctionItemInfo("list", 1)
    prices[mats_array[itemNumber]] = math.floor(buyoutPrice/count)
    local g, s, c = copperConverter(prices[mats_array[itemNumber]])
    print(name.."  -  "..g.."g "..s.."s "..c.."c")
   queryAH() -- call for the next item
end



function copperConverter(priceInCopper)
    local copper = priceInCopper % 100
    priceInCopper = math.floor(priceInCopper / 100)
    local silver = priceInCopper % 100
    priceInCopper = math.floor(priceInCopper / 100)
    local gold = priceInCopper
    return gold, silver, copper
end

------------------------------------
-----    PACKAGES STACKS      ------
------------------------------------

-- local cheap_mats    -- less than 50g
    --stacks of i   will be total x% of all items
    local cheap_mats = {}
    for i=1,50 do cheap_mats[i]=0 end
    cheap_mats[5] = 20
    cheap_mats[10] = 25
    cheap_mats[20] = 30
    cheap_mats[50] = 25
    local cheap_mats_step = {5,10,20,50}


-- local expensive_mats  -- more than 50g
    --stacks of i   will be total  x% of all items
    local expensive_mats = {}
    for i=1,5 do expensive_mats[i]=0 end

    expensive_mats[1] = 10
    expensive_mats[2] = 20
    expensive_mats[3] = 30
    expensive_mats[5] = 40
    local expensive_mats_step = {1,2,3,5}
local MAT_STACK_SIZES = 4

-- based on cheap_mats or expensive_mats, when a new item is put, calculate the stack sizes
-- e.g. stack of 5s will be 25 in total, because we use cheap mats and we have a total count of 125 (applied percentage is 20%)
    local stack_sizes = {}
    local step = {}  -- either expensive_mats step or cheap_mats_step (used to loop over the right elements of the arrays)

local EXPENSIVE_ITEM_THRESHOLD = 500000  -- 50g
local UNDERCUT_AMOUNT = 300 -- 3 silver
local PREVIOUS_ITEM_SOLD = ""
local PREVIOUS_ITEM_SOLD_INDEX = 0
local frame2 = CreateFrame("Frame")
frame2:RegisterEvent("NEW_AUCTION_UPDATE")
frame2:SetScript("OnEvent", function(self, event, ...)
    local name, _, _, _, _, _, _, _, count, _ = GetAuctionSellItemInfo();
    setPerUnit()

    if(name~=nil) then
        if(PREVIOUS_ITEM_SOLD == name) then
            C_Timer.After(0.5, function() fillInData(name, PREVIOUS_ITEM_SOLD_INDEX, count) end)
            C_Timer.After(0.8, function() PREVIOUS_ITEM_SOLD_INDEX = PREVIOUS_ITEM_SOLD_INDEX + 1 end)
        else
            PREVIOUS_ITEM_SOLD = name
            PREVIOUS_ITEM_SOLD_INDEX = 0
            stack_sizes = {}
            if prices[itemName] ~= nil then  -- might be an item we haven't scanned
                calculateStackSizesAndStep(name, count)
                C_Timer.After(0.5, function() fillInData(name, PREVIOUS_ITEM_SOLD_INDEX, count) end)
                C_Timer.After(0.8, function() PREVIOUS_ITEM_SOLD_INDEX = PREVIOUS_ITEM_SOLD_INDEX + 1 end)
            end
        end
    end

end)

function fillInData(itemName, prevIndex, count)  --fills in the data
    -- price is in prices[itemName]
    -- stack size is in step[prevIndex+1]
    -- total size for all stacks of certain size is in stack_sizes[step[prevIndex+1]]

    local price = prices[itemName] - UNDERCUT_AMOUNT

    -- set buyout price
    MoneyInputFrame_SetCopper(StartPrice, price -1)
    MoneyInputFrame_SetCopper(BuyoutPrice, price)

    -- only calculate stack size up to the 4th listing (as we only have percentages for 4 listings)
    if(prevIndex+1 <= MAT_STACK_SIZES) then
        local current_index = prevIndex + 1

        local stack_size = step[current_index]
        local num_stacks = math.floor(stack_sizes[step[current_index]] / stack_size)   -- total number / stack size
        
        -- when selling a low amount of mats the percentages gets screwed (e.g. less than 25 cheap mats)
        -- so we will just sell everything with the lowest amount
        if(num_stacks == 0 ) then
            if(count >= stack_size) then
                num_stacks = math.floor(count/stack_size)
            else 
                stack_size = count
                num_stacks = 1
            end
        end
        -- set stack size and number of stacks
        AuctionsStackSizeEntry:SetNumber(stack_size)
        AuctionsNumStacksEntry:SetNumber(num_stacks)

        -- print("Name - "..itemName)
        -- print("Stack size - "..stack_size)
        -- print("Num stacks - "..num_stacks)
        -- print("Price - "..price)
    end

end

function setPerUnit()
    -- set auction sell to be Per Unit
    -- AuctionFrameAuctions.priceType = 1;
    -- UIDropDownMenu_SetSelectedValue(PriceDropDown, AuctionFrameAuctions.priceType)
    PriceDropDownButton:Click("RightButton", false)
    DropDownList1Button1:Click("RightButton", false)
end

function calculateStackSizesAndStep(itemName, itemCount)  --calculates stacks
    local mats_percent = {}
    step = {}

    if(prices[itemName] >= EXPENSIVE_ITEM_THRESHOLD) then   -- more than 50g
        mats_percent = expensive_mats
        step = expensive_mats_step
    else  -- less than 50g 
        mats_percent = cheap_mats
        step = cheap_mats_step
    end

    -- calculate how many total mats will be for each stack, when applying the correct percentages
    for i=1, MAT_STACK_SIZES do
        stack_sizes[step[i]] = math.floor(itemCount * (mats_percent[step[i]]/100))
    end

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
