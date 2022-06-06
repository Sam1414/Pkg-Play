# Print Messages with colored prefix
print_message() {
    TYPE=$1
    MESSAGE=$2
    if [[ $TYPE = "warning" ]]
    then
        printf "\e[1;33;40m[WARNING]\e[0m %s\n" "$MESSAGE"
    elif [[ $TYPE = "success" ]]
    then
        printf "\e[1;32;40m[SUCCESS]\e[0m %s\n" "$MESSAGE"
    elif [[ $TYPE = "info" ]]
    then
        printf "\e[1;35;40m[INFO]\e[0m %s\n" "$MESSAGE"
    elif [[ $TYPE = "highlight" ]]
    then
        printf "\e[1;37;40m%s\e[0m" "$MESSAGE"
    fi
}

prequisites() {
    print_message info "Current Directory: $(pwd)"

    directory="maven-dependency-management"
    mkdir -p "$directory"
}

write_file() {
    variable=$1
    data=$2
    operation=$3
    file=$4

    directory="maven-dependency-management/json-obj"
    mkdir -p "$directory"

    if [[ $operation = "overwrite" ]]
    then
        echo "$variable = $data;" > "$directory/$file"
    elif [[ $operation = "append" ]]
    then
        echo "$variable = $data;" >> "$directory/$file"
    fi

    print_message success "Saved in File: $directory/$file"
}


verify_secure_repo_connection() {

    echo
    print_message info "---------------------------------------------------------"
    print_message info "             Source Repository Verification"
    print_message info "---------------------------------------------------------"
    echo

    print_message info "Listing Local & Global Repositories..."
    command_output=$(mvn dependency:list-repositories)
    print_message info "Repositories Listed."
    IFS=$'\n' # To take newline as a separator in array elements.
    print_message info "Getting Repo Ids..."
    # Repository IDs
    repo_ids=( $(echo "$command_output" | grep "id:" | awk '{print $3}') )
    print_message info "Getting Repo Urls..."
    # Repository URLs
    repo_urls=( $(echo "$command_output" | grep "url:" | awk '{print $2}') )
    print_message info "Getting Repo Layouts..."
    # Repository Layouts
    repo_layouts=( $(echo "$command_output" | grep "layout:" | awk '{print $2}') )
    print_message info "Getting Repo Snapshot Settings..."
    # Repository Snapshot Settings
    repo_snapshots=( $(echo "$command_output" | grep "snapshots:" | gawk 'match($0, /(snapshots: )(.*)/, array) {print array[2]}') )
    print_message info "Getting Repo Release Settings..."
    # Repository Release Settings
    repo_releases=( $(echo "$command_output" | grep "releases:" | gawk 'match($0, /(releases: )(.*)/, array) {print array[2]}') )
    print_message info "Checking if Repo blocked..."
    # Is Repository Blocked
    repo_blocked=( $(echo "$command_output" | grep "blocked:" | awk '{print $2}') )

    # number of repositories
    N=$(echo "${#repo_ids[@]}")

    print_message info "Checking Protocol of Repository Urls..."
    json_string="[]"
    for (( i=0; i<"$N"; i++ ))
    do
        echo
        print_message info "ID: ${repo_ids[$i]}"
        print_message info "URL: ${repo_urls[$i]}"
        print_message info "Layout: ${repo_layouts[$i]}"
        print_message info "Sanpshots: ${repo_snapshots[$i]}"
        print_message info "Releases: ${repo_releases[$i]}"
        print_message info "Blocked: ${repo_blocked[$i]}"
        security=""
        protocol=""
        if ! [[ $i = "http://0.0.0.0/" ]]
        then
            IS_HTTPS=$(echo "${repo_urls[$i]}" | gawk 'match($0, /(https)/, array) {print}')
            if [[ -z "$IS_HTTPS" ]]
            then
                print_message "warning" "The Repository url uses HTTP that is insecure."
                protocol="HTTP"
                security="INSECURE"
            else
                print_message "success" "The Repository url uses HTTPS and is secure."
                protocol="HTTPS"
                security="SECURE"
            fi
        fi

        # Writing JSON Object
        json_string=$(echo "$json_string" | jq ".[.|length] |= .+ { \"id\": \"${repo_ids[$i]}\", \"Url\": \"${repo_urls[$i]}\", \"Layout\": \"${repo_layouts[$i]}\", \"Snapshots\": \"${repo_snapshots[$i]}\", \"Releases\": \"${repo_releases[$i]}\", \"Blocked\": \"${repo_blocked[$i]}\", \"Protocol\": \"$protocol\", \"Security\": \"$security\"}")

    done

    print_message info "Saving Source Repo Verification Results..."
    write_file "source_repo_list" "$json_string" "overwrite" "source-repository-list.js"

    print_message success "Completed Source Repo Verification and results saved."
}

prequisites
verify_secure_repo_connection
