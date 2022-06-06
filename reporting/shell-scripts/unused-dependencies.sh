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


list_unused_dependencies() {

    echo
    print_message info "---------------------------------------------------------"
    print_message info "             Checking Unused Dependencies"
    print_message info "---------------------------------------------------------"
    echo

    print_message info "Analysing Unused Dependencies..."
    # Unused Dependency Check
    cmd_output=$(mvn dependency:analyze | grep WARNING)

    # Line Number
    unused_dep_found=$(echo "$cmd_output" | grep "Unused declared dependencies found:")

    if ! [[ -z "$unused_dep_found" ]]
    then
        print_message info "Getting Details of Unused Dependencies..."

        IFS=$'\n'
        unused_dep_array=( $(printf "$cmd_output" | gawk 'match($0, /(^\[WARNING\]\s{4})(.+:.+:\w{3}:.+:\w+)/, array) {print array[2]}' | sort | uniq) )

        # Save Dependency details in json objects
        unused_dep_detail_list=( $(echo "${unused_dep_array[@]}" | tr ' ' '\n' | gawk 'match($0, /(.+):(.+):(\w{3}):(.+):(\w+)/, array) {printf("{\"groupId\": \"%s\", \"ArtifactId\": \"%s\", \"Packaging\": \"%s\", \"Version\": \"%s\", \"Scope\": \"%s\"}\n", array[1], array[2], array[3], array[4], array[5])}') )

        # Building JSON
        unused_dep_list_json=$(echo "${unused_dep_detail_list[@]}" | jq -s)
        echo "$unused_dep_list_json" | jq

        print_message info "Saving Unused Dependency Checking Results..."
        # Saving json as a js object in file
        write_file "unused_dependency_list" "$unused_dep_list_json" "overwrite" "unused-dep-list.js"

        print_message success "Unused Dependencies Listed and results saved for reporting"
    else
        print_message info "No Unused Dependencies Found"
        write_file "unused_dependency_list" "[]" "overwrite" "unused-dep-list.js"
    fi
}

prequisites
list_unused_dependencies