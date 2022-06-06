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

install_xmlPath() {
    echo
    print_message info "-------------------------------------"
    print_message info "Installing XPATH-Perl for XML parsing"
    print_message info "-------------------------------------"
    echo
    sudo apt install libxml-xpath-perl -y
    echo
}

# Check for any version declaration issue
check_any_version_declaration_issue() {
    VER=$1
    ISSUE_FOUND=$(echo "$VER" | gawk 'match($0, /\(|\)|\*|,|(alpha)|(Alpha)|(ALPHA)|((a|A)[0-9])|(beta)|(Beta)|(BETA)|((b|B)[0-9])|(milestone)|(Milestone)|(MILESTONE)|((m|M)[0-9])|(rc|RC)[0-9]|(cr|CR)[0-9]|(SNAPSHOT)|(Snapshot)|(snapshot)|(RELEASE)|(Release)|(release)/, array) {printf("Found issue\n")}')
    if [ -z "$ISSUE_FOUND" ]
    then
      # No Issue found 
      echo "0"
    else
      # Issue Found
      echo "1"
    fi
}

# Function to check version declarations
find_invalid_pattern() {
    VER=$1
    # Find (
    echo "$VER" | gawk 'match($0, /\(/, array) {print "Open Lower Bound --> ("}'
    # Find )
    echo "$VER" | gawk 'match($0, /\)/, array) {print "Open Upper Bound --> )"}'
    # Find *
    echo "$VER" | gawk 'match($0, /\*/, array) {print "Star --> *"}'
    # Find ,
    echo "$VER" | gawk 'match($0, /,/, array) {print "Separator (comma) --> ,"}'
    # Find SNAPSHOT
    echo "$VER" | gawk 'match($0, /(SNAPSHOT)|(Snapshot)|(snapshot)/, array) {print "SNAPSHOT"}'
    # Find RELEASE
    echo "$VER" | gawk 'match($0, /(RELEASE)|(Release)|(release)/, array) {print "RELEASE"}'
    # Find alpha
    echo "$VER" | gawk 'match($0, /(alpha)|(Alpha)|(ALPHA)|((a|A)[0-9])/, array) {print "ALPHA"}'
    # Find beta
    echo "$VER" | gawk 'match($0, /(beta)|(Beta)|(BETA)|((b|B)[0-9])/, array) {print "BETA"}'
    # Find MILESTONE
    echo "$VER" | gawk 'match($0, /(milestone)|(Milestone)|(MILESTONE)|((m|M)[0-9])/, array) {print "MILESTONE"}'
    # Find rc
    echo "$VER" | gawk 'match($0, /(rc|RC)[0-9]/, array) {print "RC"}'
    # Find cr
    echo "$VER" | gawk 'match($0, /(cr|CR)[0-9]/, array) {print "CR"}'
}

# Stores the package details
store_package_list() {
    package_tag=$1

    temp_json="{\"Group ID\": \"$GROUPID\", \"Artifact ID\": \"$ARTIFACTID\", \"Version Defined in pom.xml\": \"$VERSION\", \"Type\": \"$TYPE\"}\n"

    if [[ "$package_tag" = 'dependencies' ]]
    then
        user_dependencies+="$temp_json"
    elif [[ "$package_tag" = 'pluginManagement' ]]
    then
        user_pluginManagement+="$temp_json"
    elif [[ "$package_tag" = 'build' ]]
    then
        user_build+="$temp_json"
    elif [[ "$package_tag" = 'reporting' ]]
    then
        user_reporting+="$temp_json"
    fi
}

# Save All Package Details in File
save_package_details() {
    type=$1
    package_var_name=$2
    user_packages=$3
    package_count_var_name=$4

    print_message info "Getting Unique User $type packages..."
    # Getting Unique Values
    unique_packages=$(echo -e "$user_packages" | sort | uniq)
    echo -e "$unique_packages" | jq -s

    # Creating JSON
    user_packages_json=$(echo -e "$unique_packages" | jq -s)
    print_message info "Storing User $type packages..."
    write_file "$package_var_name" "$user_packages_json" "append" "user-package-list.js"

    # Getting Count
    user_packages_count=$(echo "$user_packages_json" | jq '.|length')
    print_message info "Storing User $type package Count..."
    write_file "$package_count_var_name" "$user_packages_count" "append" "user-package-list.js"
}

# Show the dependency details having version declaration issues
show_dependency_with_version_issue() {
    IFS=$'\n' # To take newline as a separator in array elements.
    invalid_char_list=( $(find_invalid_pattern "$VERSION") )

    printf "\n%s\n" "-------------------------------------------------------------"
    echo "groupId: $GROUPID"
    echo "artifactId: $ARTIFACTID"
    echo "version: $VERSION"
    echo "type: $TYPE"
    echo -e "Invalid Characters: \n${invalid_char_list[@]}"
    printf "%s\n\n" "-------------------------------------------------------------"

    insecure_char_list=""
    for j in "${invalid_char_list[@]}"
    do
        insecure_char_list+="\"$j\","
    done
    insecure_char_list=$(echo "[${insecure_char_list::-1}]")

    temp_json="{\"Group ID\": \"$GROUPID\", \"Artifact ID\": \"$ARTIFACTID\", \"Version Defined in pom.xml\": \"$VERSION\", \"Type\": \"$TYPE\", \"Insecure Declarations Used\": $insecure_char_list}"

    # Appending json elements in String
    version_check_string+="$temp_json\n"
}

check_package_version() {
    type=$1
    xml_tag=$2
    expression=$3
    xml_path=$4
    count_variable=$5

    print_message info "Checking for $type in POM..."
    xml_output=$(mvn --no-transfer-progress help:evaluate -Dexpression=$expression -q -DforceStdout)
    M=$(echo "$xml_output" | grep -n "<$xml_tag>" | cut -d : -f 1)
    N=$(echo "$xml_output" | grep -n "</$xml_tag>" | cut -d : -f 1)

    if [[ -z "$M" ]]
    then
        print_message info "No $type found in current POM: $(pwd)/pom.xml"
    else
        print_message info "$type found in POM"

        xml_required=$(echo "$xml_output" | awk "NR==$M, NR==$N")

        # Getting total number of tags
        COUNT=$(echo "$xml_required" | xpath -e "count($xml_path)" 2>/dev/null)
        
        # Iterating over all the tags
        for (( i=1; i<=COUNT; i++ ))
        do
            GROUPID=$(echo "$xml_required" | xpath -e "$xml_path[position()=$i]/groupId/text()" 2>/dev/null)
            ARTIFACTID=$(echo "$xml_required" | xpath -e "$xml_path[position()=$i]/artifactId/text()" 2>/dev/null)
            VERSION=$(echo "$xml_required" | xpath -e "$xml_path[position()=$i]/version/text()" 2>/dev/null)
            TYPE="$type"

            # Listing User Declared Packages
            store_package_list "$xml_tag"

            # Checking for all invalid patterns in version number
            ISSUE_IN_VERSION_DECLARATION=$(check_any_version_declaration_issue "$VERSION")

            if [ $ISSUE_IN_VERSION_DECLARATION = 1 ]
            then
                show_dependency_with_version_issue
            fi
        done
    fi
}

check_pom() {
    check_package_version "Dependency" "dependencies" "project.dependencies" "dependencies/dependency" "user_dependencies_count"
    check_package_version "Plugin-Management Plugin" "pluginManagement" "project.build.pluginManagement" "pluginManagement/plugins/plugin" "user_pluginManagement_count"
    check_package_version "Build Plugin" "build" "project.build" "build/plugins/plugin" "user_build_count"
    check_package_version "Reporting Plugin" "reporting" "project.reporting" "reporting/plugins/plugin" "user_reporting_count"
}

check_for_multi_module_project() {
    print_message info "Checking for Multi Module Project..."
    module_xml_output=$(mvn --no-transfer-progress help:evaluate -Dexpression=project -q -DforceStdout)
    M=$(echo "$module_xml_output" | grep -n "<modules>" | cut -d : -f 1)
    N=$(echo "$module_xml_output" | grep -n "</modules>" | cut -d : -f 1)

    if [[ -z "$M" ]]
    then
        print_message info "Single POM project."

        print_message info "Checking POM..."
        check_pom
    else
        print_message info "Multi Module Project."

        module_xml_required=$(echo "$module_xml_output" | awk "NR==$M, NR==$N")

        # Getting total number of tags
        MODULE_COUNT=$(echo "$module_xml_required" | xpath -e "count(modules/module)" 2>/dev/null)
        print_message info "No. of Modules in project: $MODULE_COUNT"

        print_message info "Checking Packages in Root POM..."
        # Checking Root POM
        check_pom
        print_message info "Root Module POM checked"

        # Iterating over all Modules
        for (( p=1; p<=MODULE_COUNT; p++ ))
        do
            print_message info "$p"
            module_name=$(echo "$module_xml_required" | xpath -e "modules/module[position()=$p]/text()" 2>/dev/null)
            print_message info "Checking in Module: $module_name ..."
            
            cd "$(pwd)/$module_name"
            print_message info "Module Directory: $(pwd)"
            print_message info "pom file path: $(pwd)/pom.xml"

            # Checking Module POM
            check_pom

            print_message info "Going back to Root Directory..."
            # Back to Root Directory
            cd ..
            print_message info "Current dir: $(pwd)"
        done
    fi
}

client_side_validation() {

    echo
    print_message info "---------------------------------------------------------"
    print_message info "                 Client Side Validation"
    print_message info "---------------------------------------------------------"
    echo

    # Defining Empty Strings
    version_check_string=""

    # Initializing User Package List Strings
    user_dependencies=""
    user_pluginManagement=""
    user_build=""
    user_reporting=""

    # Calling all the functions
    install_xmlPath
    check_for_multi_module_project

    # Saving All Package Details in File
    save_package_details "Dependencies" "user_dependencies" "$user_dependencies" "user_dependencies_count"
    save_package_details "Plugin Management" "user_pluginManagement" "$user_pluginManagement" "user_pluginManagement_count"
    save_package_details "Build" "user_build" "$user_build" "user_build_count"
    save_package_details "Reporting" "user_reporting" "$user_reporting" "user_reporting_count"

    echo
    version_check_json_obj=$(echo -e "$version_check_string" | sort | uniq | jq -s)
    write_file "version_check_list" "$version_check_json_obj" "append" "version-check-list.js"
    print_message success "Client-Side Validation done and results saved"

    echo
    print_message warning "Using a single exact version number within closed range, like [1.2.1] is recommended"
    echo
}

prequisites
client_side_validation