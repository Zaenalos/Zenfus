local player = { name = "Player", health = 100 }
local current_room = "living_room"

::start_game::
print("Welcome to the House Adventure!")
print("You are currently in the " .. current_room .. ".")

::main_loop::
if current_room == "living_room" then
    ::living_room::
    print("You see a cozy living room with a sofa and a TV.")
    print("Options: go to kitchen, go to bedroom, go to bathroom, exit house")
    local choice = io.read()

    if choice == "go to kitchen" then
        current_room = "kitchen"
        goto kitchen
    elseif choice == "go to bedroom" then
        current_room = "bedroom"
        goto bedroom
    elseif choice == "go to bathroom" then
        current_room = "bathroom"
        goto bathroom
    elseif choice == "exit house" then
        print("You decided to leave the house. Game Over.")
        goto end_game
    else
        print("Invalid option. Try again.")
        goto living_room
    end

elseif current_room == "kitchen" then
    print("You are now in the kitchen. There is a fridge and a stove here.")
    print("Options: go to living room, check fridge, check stove")
    local choice = io.read()

    if choice == "go to living room" then
        current_room = "living_room"
        goto main_loop
    elseif choice == "check fridge" then
        print("You found some food and gained 10 health.")
        player.health = player.health + 10
        print("Your health is now " .. player.health .. ".")
        goto kitchen
    elseif choice == "check stove" then
        print("The stove is off. Nothing interesting here.")
        goto kitchen
    else
        print("Invalid option. Try again.")
        goto kitchen
    end

elseif current_room == "bedroom" then
    print("You are now in the bedroom. There is a bed and a closet here.")
    print("Options: go to living room, take a nap, check closet")
    local choice = io.read()

    if choice == "go to living room" then
        current_room = "living_room"
        goto main_loop
    elseif choice == "take a nap" then
        print("You took a nap and gained 20 health.")
        player.health = player.health + 20
        print("Your health is now " .. player.health .. ".")
        goto bedroom
    elseif choice == "check closet" then
        print("The closet is empty.")
        goto bedroom
    else
        print("Invalid option. Try again.")
        goto bedroom
    end

elseif current_room == "bathroom" then
    print("You are now in the bathroom. There is a sink and a shower here.")
    print("Options: go to living room, wash hands, take a shower")
    local choice = io.read()

    if choice == "go to living room" then
        current_room = "living_room"
        goto main_loop
    elseif choice == "wash hands" then
        print("You washed your hands. You feel refreshed.")
        goto bathroom
    elseif choice == "take a shower" then
        print("You took a shower and feel much better.")
        player.health = player.health + 15
        print("Your health is now " .. player.health .. ".")
        goto bathroom
    else
        print("Invalid option. Try again.")
        goto bathroom
    end    
else
    print("Error: Unknown room. Exiting game.")
    goto end_game
end

::kitchen::
print("Going to kitchen")
goto main_loop
::bedroom::
print("Going to bedroom")
goto main_loop
::bathroom::
print("Going to bathroom")
goto main_loop


::end_game::
print("Thank you for playing! Your final health is " .. player.health .. ".")