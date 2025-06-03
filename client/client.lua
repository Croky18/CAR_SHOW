local vehiclesSpawned = false
local spawnedShowroomVehicles = {}
local spawnedVehicles = {}

local function DeleteShowroomVehicles()
    if not spawnedShowroomVehicles or #spawnedShowroomVehicles == 0 then
        lib.notify({ title = 'Car Show', description = ("RESET"), type = 'info' })
        return
    end

    for _, v in pairs(spawnedShowroomVehicles) do
        if DoesEntityExist(v.entity) then
            NetworkRequestControlOfEntity(v.entity)
            Wait(100)
            DeleteEntity(v.entity)
        end
    end

    spawnedShowroomVehicles = {}
    lib.notify({ title = 'Car Show', description = ("deleted"), type = 'success' })
end

RegisterNetEvent('carshow:spawnVehicles', function(vehicleData)
    DeleteShowroomVehicles()

    for _, data in pairs(vehicleData) do
        local model = GetHashKey(data.model)
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 1000 do
            Wait(10)
            timeout += 1
        end

        if not HasModelLoaded(model) then
            print((("modeload_fail")):format(data.model))
        else
            local veh = CreateVehicle(model, data.coords.x, data.coords.y, data.coords.z, data.coords.w, false, false)
            SetEntityAsMissionEntity(veh, true, true)
            SetVehicleOnGroundProperly(veh)
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleUndriveable(veh, true)
            table.insert(spawnedShowroomVehicles, { entity = veh, model = data.model, price = data.price })
        end
    end

    CreateThread(function()
        while #spawnedShowroomVehicles > 0 do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for _, v in pairs(spawnedShowroomVehicles) do
                local vehCoords = GetEntityCoords(v.entity)
                if #(coords - vehCoords) < 15.0 then
                    local displayText = Config.ShowVehicleName
                        and ("%s - €%s"):format(v.model, v.price)
                        or ("€%s"):format(v.price)
                    DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 1.5, displayText)
                end
            end
            Wait(0)
        end
    end)
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.50, 0.50)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(0, 255, 0, 215)
    SetTextCentre(true)
    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function EndTestDrive(veh, playerPed, message, notifyType)
    if DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
    SetEntityCoords(playerPed, Config.VehicleTest.returnCoords.x, Config.VehicleTest.returnCoords.y, Config.VehicleTest.returnCoords.z)
    lib.notify({ title = 'Car Show', description = message, type = notifyType })
end

RegisterNetEvent('carshow:testDrive', function(model)
    if not Config.VehicleTest or not Config.VehicleTest.enabled then
        lib.notify({ title = 'Car Show', description = ("test disabled"), type = 'error' })
        return
    end

        local allowed = lib.callback.await('carshow:isVehicleInDatabase', false, model)
    if not allowed then
        lib.notify({ title = 'Car Show', description = "This vehicle is not in the showroom.", type = 'error' })
        return
    end

    local playerPed = PlayerPedId()
    local modelHash = GetHashKey(model)

        local allowed = lib.callback.await('carshow:isVehicleInDatabase', false, model)
    if not allowed then
        lib.notify({ title = 'Car Show', description = "This vehicle is not in the showroom.", type = 'error' })
        return
    end

    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 1000 do
        Wait(10)
        timeout += 1
    end

    if not HasModelLoaded(modelHash) then
        lib.notify({ title = 'Car Show', description = (("modeload_fail")):format(model), type = 'error' })
        return
    end

    local veh = CreateVehicle(modelHash, Config.VehicleTest.testSpawn.x, Config.VehicleTest.testSpawn.y, Config.VehicleTest.testSpawn.z, Config.VehicleTest.testSpawn.w, true, false)
    SetVehicleNumberPlateText(veh, "TEST")
    TaskWarpPedIntoVehicle(playerPed, veh, -1)
    lib.notify({ title = 'Car Show', description = (("test start")):format(Config.VehicleTest.testDuration), type = 'inform' })

    local timeLeft = Config.VehicleTest.testDuration
    local finished = false

    CreateThread(function()
        while timeLeft > 0 and not finished do
            Wait(1000)
            timeLeft -= 1
        end
        if not finished then
            finished = true
            EndTestDrive(veh, playerPed, ("test end"), 'info')
        end
    end)

    CreateThread(function()
        while timeLeft > 0 and not finished do
            local coords = GetEntityCoords(playerPed)
            DrawText3D(coords.x, coords.y, coords.z + 1.0, ("⏱️ Test time: %ss"):format(timeLeft))
            Wait(0)
        end
    end)

    CreateThread(function()
        while timeLeft > 0 and not finished do
            Wait(500)
            if not IsPedInAnyVehicle(playerPed, false) then
                finished = true
                EndTestDrive(veh, playerPed, ("test exit"), 'error')
            end
        end
    end)
end)

RegisterCommand('cartest', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    if #(playerCoords - Config.ShowroomZone) > Config.ShowroomRadius then
        lib.notify({ title = 'Car Show', description = ("out of zone"), type = 'error' })
        return
    end

    if Config.MenuType == 'ox' then
        lib.registerContext({
            id = 'carshow_test_menu',
            title = 'Voertuig Testmenu',
            options = {
                {
                    title = 'Test vehicle (time limit)',
                    icon = 'stopwatch',
                    onSelect = function()
                        local input = lib.inputDialog(("vehicle name"), {
                            { type = 'input', label = ("modelabel"), required = true }
                        })
                        if input and input[1] then
                            TriggerEvent('carshow:testDrive', input[1])
                        end
                    end
                }
            }
        })
        lib.showContext('carshow_test_menu')
    elseif Config.MenuType == 'qb' then
        exports['qb-menu']:openMenu({
            {
                header = "🚘 Vehicle Test Menu",
                isMenuHeader = true
            },
            {
                header = "⏱️ Start Test Drive",
                txt = "Enter a model name",
                params = {
                    event = "carshow:testDrivePrompt"
                }
            }
        })
    end
end)

RegisterNetEvent('carshow:testDrivePrompt', function()
    local input = lib.inputDialog(("add_vehicle"), {
        { type = 'input', label = ("modelabel"), required = true }
    })
    if input and input[1] then
        TriggerEvent('carshow:testDrive', input[1])
    end
end)



-- QB-MENU CALLBACKS
RegisterNetEvent('carshow:addVehiclePrompt', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Nieuw Showroom Voertuig",
        submitText = "Confirm",
        inputs = {
            {
                text = "Vehicle Model",
                name = "model",
                type = "text",
                isRequired = true
            },
            {
                text = "Selling price (€/$)",
                name = "price",
                type = "number",
                isRequired = true
            }
        }
    })

    if dialog and dialog.model and dialog.price then
        local coords = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        TriggerServerEvent('carshow:saveVehicleToDatabase', dialog.model, coords.x, coords.y, coords.z, heading, tonumber(dialog.price))
    end
end)

RegisterNetEvent('carshow:deleteVehiclePrompt', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Remove Vehicle",
        submitText = "Remove",
        inputs = {
            {
                text = "Vehicle Model (e.g. Sultan)",
                name = "model",
                type = "text",
                isRequired = true
            }
        }
    })

    if dialog and dialog.model then
        TriggerServerEvent('carshow:deleteVehicleByModel', dialog.model)
    end
end)

RegisterNetEvent('carshow:clearVehicles', function()
    DeleteShowroomVehicles()
end)

RegisterNetEvent('carshow:requestVehicles', function()
    TriggerServerEvent('carshow:requestVehicles')
end)

-- Showroom menu
RegisterCommand('carshowmenu', function()
    local job = lib.callback.await('carshow:getPlayerJob', false)
    if job ~= Config.AllowedJob then
        lib.notify({ title = 'Car Show', description = 'No access.', type = 'error' })
        return
    end

    if Config.MenuType == 'ox' then
        openOxMenu()
    elseif Config.MenuType == 'qb' then
        openQbMenu()
    else
        print("❌ Invalid Config.MenuType. Choose 'ox' or 'qb'")
    end
end)

function openOxMenu()
    lib.registerContext({
        id = 'carshow_menu',
        title = '🚘 Car Showroom Menu',
        options = {
            {
                title = '🚗 Spawn vehicles (showroom)',
                onSelect = function()
                    TriggerServerEvent('carshow:requestVehicles')
                end
            },
            {
                title = '➕ Add vehicle (position + price)',
                onSelect = function()
                    local input = lib.inputDialog('New Showroom Vehicle', {
                        { type = 'input', label = 'Vehicle Model', required = true },
                        { type = 'number', label = 'Selling price (€/$)', required = true }
                    })
                    if input then
                        local model = input[1]
                        local price = tonumber(input[2])
                        local coords = GetEntityCoords(PlayerPedId())
                        local heading = GetEntityHeading(PlayerPedId())
                        TriggerServerEvent('carshow:saveVehicleToDatabase', model, coords.x, coords.y, coords.z, heading, price)
                    end
                end
            },
            {
                title = '🗑️ Remove all showroom vehicles',
                onSelect = function()
                    DeleteShowroomVehicles()
                end
            },
            {
                title = '❌Remove vehicle from database',
                onSelect = function()
                    local input = lib.inputDialog('Remove vehicle', {
                        { type = 'input', label = 'Vehicle Model (e.g. Sultan)', required = true }
                    })
                    if input and input[1] then
                        local modelName = input[1]
                        TriggerServerEvent('carshow:deleteVehicleByModel', modelName)
                    end
                end
            }
        }
    })
    lib.showContext('carshow_menu')
end

function openQbMenu()
    local menu = {
        {
            header = "🚘 Car Showroom Menu",
            isMenuHeader = true
        },
        {
            header = "🚗 Spawn vehicles",
            txt = "Show all showroom vehicles",
            params = { event = "carshow:requestVehicles" }
        },
        {
            header = "➕ Add vehicle",
            txt = "Place vehicle with price",
            params = {
                event = "carshow:addVehiclePrompt"
            }
        },
        {
            header = "🗑️ Remove showroom",
            txt = "Remove all vehicles",
            params = {
                event = "carshow:clearVehicles"
            }
        },
        {
            header = "❌ Remove vehicle",
            txt = "Please enter a model name",
            params = {
                event = "carshow:deleteVehiclePrompt"
            }
        }
    }

    exports['qb-menu']:openMenu(menu)
end
