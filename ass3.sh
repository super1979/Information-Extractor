#!/bin/bash

# function to prepare variables that are used later in the code
prepare () {
    declare -ag search_choices=("PROTOCOL" "SRC IP" "SRC PORT" "DEST IP" "DEST PORT" "PACKETS" "BYTES") # declaration of a global array to store the search categories
    declare -ag filenames # declaration of a global array to store the filenames of the log files available
    local array_counter=0 # local variable to store the current index of the array. Variable is initialized to 0
    
    for file in $(pwd)/*; do # looping through all the files in the current working directory
        if [[ $file = *.csv ]]; then # checking for csv files
            filenames[$array_counter]="$(basename $file)" # storing the basename of the csv file in the array
            ((array_counter++)) # increases the counter by 1 to indicate the next empty slot in the array
        fi
    done
}

# function that is the main body of the program
main () {
    
    clear # clears the terminal for the next part of the program
    while true; do # while loop to allow user to conduct searches until he decides to exit the program
        
        search_or_exit # calls the search_or_exit function
        if [[ $input_nx -eq 2 ]]; then # tests whether the user's choice is 2
            break # exits the while loop
        fi
        clear 

        choose_crit_pat # calls the choose_crit_pat function
        clear

        choose_file # calls the choose_file function
        clear

        verify_choices # calls the verify_choices function. Enhanced functionality of the program
        while [[ $verify =~ [nN] ]]; do # as long as the user is not satisfied with the choices he has selected, the while loop will let him make his selections again 
            choose_crit_pat
            clear

            choose_file
            clear
            
            verify_choices
        done 
        clear

        file_processing # calls the file_processing function
    done
}

# function to read the user's choice of new search or exiting the program. Conducts user input validation.
search_or_exit () {
    echo -e "Enter your choice:\n1) New search\n2) Exit the program" # prompts the user to select an option
    read input_nx # reads the user's choice from the terminal and stores the value in the variable 'input_nx'
    # while loop to make the user re-enter his choice if his previous choice is invalid
    while ! [[ $input_nx =~ ^[12]{1}$ ]]; do # tests whether the user's input is a number that is either 1 or 2
        echo -e "You have entered $input_nx and it is not entered a valid input. Please try again.\n" # tells the user the value he has entered and the value is invalid. Prompts the user to try again
        search_or_exit
    done
}

# function to read the user's choice of search category and pattern. Conducts user input validation.
choose_crit_pat () {
    echo -e "Choose a category for your search:" # prompts the user to select an option
    for ((i=0; i<${#search_choices[@]}; i++)); do # loops through all the available search choices stored in the search_choices array 
        echo "$(($i + 1))) ${search_choices[$i]}" # prints the search choice to the terminal
    done
    read input_cri # reads the user's choice from the terminal and stores the value in the variable 'input_cri'
    while ! [[ $input_cri =~ ^[1-7]{1}$ ]]; do # tests whether the user's input is a number that is from 1 to 7
        echo -e "You have entered $input_cri and it is not entered a valid input. Please try again.\n" # tells the user the value he has entered and the value is invalid. Prompts the user to try again
        choose_criteria
    done
    clear
    read -p "Enter the pattern you want to search for: " pat # reads the required pattern from the terminal and stores the value in the variable 'pat'
}

# function to read the user's choice of file. Conducts user input validation.
choose_file () {
    echo "Choose a file for your search:" # prompts the user to select an option
    for ((i=0; i<${#filenames[@]}; i++)); do # loops through all the available filenames stored in the filenames array 
        echo "$(($i + 1))) ${filenames[$i]}" # prints the filename to the terminal
    done
    read input_file # reads the user's choice from the terminal and stores the value in the variable 'input_file'
    while ! ([[ $input_file =~ ^[1-9][0-9]*$ ]] && [[ $input_file -gt 0 ]] && [[ $input_file -le ${#filenames[@]} ]]); do # tests whether the user's input is a number that is from 1 to the number of csv files in the current working directory
        echo -e "You have entered $input_file and it is not entered a valid input. Please try again.\n" # tells the user the value he has entered and the value is invalid. Prompts the user to try again
        choose_file
    done
}

# function that allows the user to verify his choices. Enhanced functionality of the program
verify_choices () {
    
    echo "You have chosen to search ${search_choices[$(($input_cri - 1))]} for the pattern \"$pat\" and you want to do the search on ${filenames[$(($input_file - 1))]}." # reminds the user of his previouly selected options
    read -p "Do you want to continue with your choices? (Y/N)" verify # reads the user's choice from the terminal and stores the value in the variable 'verify'
    while ! [[ $verify =~ ^[ynYN]{1}$ ]]; do # tests whether the user's input is 'y', 'n', 'Y' or 'N'
        echo -e "You have entered $verify and it is not entered a valid input. Please try again.\n" # tells the user the value he has entered and the value is invalid. Prompts the user to try again
        verify_choices
    done
    echo "" # prints an empty line for readability
}

# function that applies the user's choices and produces the desired output
file_processing () {
    local curdatime=$(date +"%d-%m-%Y_%H:%M:%S") # obtains the current date and time and stores it in the local variable 'curdatime'
    local orig_IFS=IFS # stores the current IFS in the local variable orig_IFS
    IFS=$'.' # changes the IFS to a dot
    read -ra arr <<< ${filenames[$(($input_file - 1))]} # splits the file selected by the user into its name and extension and stores them in the array 'arr'
    local filename="search_results_${arr[0]}_$curdatime.csv" # creates and stores the name of the output file into the local variable 'filename'
    IFS=$orig_IFS # restores IFS to the original IFS
    # grep grabs all lines with the string 'suspicious' (case insensitive) and passes them to awk for further processing
    # awk processes the data further by
    # 1) passes the pattern stored in the variable 'pat' to the awk variable 'pat', passes the category selected by the user (stored in the variable 'input_cri') 
    # to the awk variable 'input_cri' and passes the name of the output file (stored in the variable 'filename') to the awk variable 'name'
    # 2) declaring a custom function called printLine which defines the width of the arguments, redirects the printf results to a file and will be called in the main block 
    # 3) changing the field separator to comma, declaring and initializing a variable called total, telling awk to conduct case insensitive searches 
    # and print the header line (since the orginal headers were ignored by grep). These are done in the BEGIN block
    # 4) using a else if control structure to conduct the matching process and call the custom function if the test condition is true. These are done in the main block
    # 5) adding the number of packets or bytes sent to the variable 'total' in the main block if the category chosen is either 'PACKETS' or 'BYTES'
    # 6) printing the total number of packets or bytes sent in the END block if the category chosen is either 'PACKETS' or 'BYTES'
    grep -i 'suspicious' ${filenames[$(($input_file - 1))]} | awk -v pat="$pat" -v input_cri=$(($input_cri + 2)) -v name="$filename" '
                                                                    function printLine(v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13){
                                                                        printf " %-9s, %-10s, %-8s, %-15s, %-8s, %-15s, %-9s, %-8s, %-8s, %-5s, %-8s, %-3s, %-12s\n", v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13 >> name
                                                                    }
                                                                    
                                                                    BEGIN {FS=","; 
                                                                            IGNORECASE=1;
                                                                            total=0;
                                                                            printLine("DATE", "DURATION", "PROTOCOL", "SRC IP", "SRC PORT", "DEST IP", "DEST PORT", "PACKETS", "BYTES", "FLOWS", "FLAGS", "TOS", "CLASS");
                                                                          }
                                                                    
                                                                    {   if (input_cri==3 && match($3, pat))
                                                                        {
                                                                            printLine($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);
                                                                        }
                                                                        else if (input_cri==4 && match($4, pat))
                                                                        {
                                                                            printLine($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);
                                                                        }
                                                                        else if (input_cri==5 && match($5, pat))
                                                                        {
                                                                            printLine($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);
                                                                        }
                                                                        else if (input_cri==6 && (match($6, pat)))
                                                                        {
                                                                            printLine($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);
                                                                        }
                                                                        else if (input_cri==7 && (match($7, pat)))
                                                                        {
                                                                            printLine($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);
                                                                        }
                                                                        else if (input_cri==8 && (match($8, pat)))
                                                                        {
                                                                            printLine($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);
                                                                            total=total+$8;
                                                                        }
                                                                        else if (input_cri==9 && match($9, pat))
                                                                        {
                                                                            printLine($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);
                                                                            total=total+$9;
                                                                        }
                                                                    }
                                                                    
                                                                    END {
                                                                        if (input_cri==8)
                                                                            {
                                                                                printf "The total number of PACKETS sent is %d.\n\n", total;
                                                                            }
                                                                        else if (input_cri==9)
                                                                            {
                                                                                printf "The total number of BYTES sent is %d.\n\n", total;
                                                                            }
                                                                        }
                                                                    '
}

prepare # calls the prepare function
main # calls the main function
echo "You have exited the program."
exit 0
