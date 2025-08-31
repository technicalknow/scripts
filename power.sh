#!/bin/bash

# Function to display the power menu
show_power_menu() {
    options=("Power Off" "Restart" "Suspend" "Log Out")

    # Show the menu using rofi
    selected_option=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Select an action:")

    # Execute the selected action
    case $selected_option in
        "Power Off")
            systemctl poweroff
            ;;
        "Restart")
            systemctl reboot
            ;;
        "Suspend")
            systemctl suspend
            ;;
        "Log Out")
            # Log out command for XFCE
            xfce4-session-logout --logout
            ;;
        *)
            echo "No valid option selected."
            ;;
    esac
}

# Call the function to show the power menu
show_power_menu
