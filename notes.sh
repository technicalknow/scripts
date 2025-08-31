#!/bin/bash

# Directory where your notes are stored
NOTE_DIR="$HOME/notes"

# Create the notes directory if it doesn't exist
mkdir -p "$NOTE_DIR"

# Function to create a new note
create_new_note() {
    # Prompt for the new note file name
    note_name=$(rofi -dmenu -p "Enter new note name:")
    
    # Check if the user provided a name
    if [ -n "$note_name" ]; then
        # Create the new note file
        touch "$NOTE_DIR/$note_name.txt"
        # Open the new note with xed
        xed "$NOTE_DIR/$note_name.txt"
    fi
}

# Function to list notes and open the selected one
open_note() {
    # List existing notes and add "New Note" option
    options=("New Note" $(ls "$NOTE_DIR"/*.txt 2>/dev/null | xargs -n 1 basename))
    
    # Show the menu using rofi
    selected_option=$(printf '%s\n' "${options[@]}" | rofi -dmenu -p "Select a note:")
    
    # Check if the selected option is "New Note"
    if [ "$selected_option" == "New Note" ]; then
        create_new_note
    elif [ -n "$selected_option" ]; then
        # Open the selected note with xed
        xed "$NOTE_DIR/$selected_option"
    else
        echo "No valid option selected."
    fi
}

# Call the function to open a note or create a new one
open_note
