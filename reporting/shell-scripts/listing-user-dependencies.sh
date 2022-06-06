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

# Show the dependency details having version declaration issues
show_package() {
    package_tag=$1

    printf "\n%s\n" "-------------------------------------------------------------"
    echo "groupId: $GROUPID"
    echo "artifactId: $ARTIFACTID"
    echo "version: $VERSION"
    echo "type: $TYPE"
    printf "%s\n\n" "-------------------------------------------------------------"

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

list_package_in_pom() {
    type=$1
    xml_tag=$2
    expression=$3
    xml_path=$4
    package_type_variable=$5

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

        # Saving Count of this type of Package
        print_message info "Count: $COUNT"
        # eval "$package_type_variable+=$COUNT"
        
        # Iterating over all the tags
        for (( i=1; i<=COUNT; i++ ))
        do
            GROUPID=$(echo "$xml_required" | xpath -e "$xml_path[position()=$i]/groupId/text()" 2>/dev/null)
            ARTIFACTID=$(echo "$xml_required" | xpath -e "$xml_path[position()=$i]/artifactId/text()" 2>/dev/null)
            VERSION=$(echo "$xml_required" | xpath -e "$xml_path[position()=$i]/version/text()" 2>/dev/null)
            TYPE="$type"

            show_package "$xml_tag"
        done
    fi
}

scan_packages_pom() {
    list_package_in_pom "Dependency" "dependencies" "project" "dependencies/dependency"
    list_package_in_pom "Plugin-Management Plugin" "pluginManagement" "project.build.pluginManagement" "pluginManagement/plugins/plugin"
    list_package_in_pom "Build Plugin" "build" "project.build" "build/plugins/plugin"
    list_package_in_pom "Reporting Plugin" "reporting" "project.reporting" "reporting/plugins/plugin"
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
        scan_packages_pom
    else
        print_message info "Multi Module Project."

        module_xml_required=$(echo "$module_xml_output" | awk "NR==$M, NR==$N")

        # Getting total number of tags
        MODULE_COUNT=$(echo "$module_xml_required" | xpath -e "count(modules/module)" 2>/dev/null)
        print_message info "No. of Modules in project: $MODULE_COUNT"

        print_message info "Listing Packages in Root POM..."
        # Listing in Root POM
        scan_packages_pom
        print_message info "Root Module POM scanned"

        Iterating over all Modules
        for (( p=1; p<=MODULE_COUNT; p++ ))
        do
            print_message info "$p"
            module_name=$(echo "$module_xml_required" | xpath -e "modules/module[position()=$p]/text()" 2>/dev/null)
            print_message info "Checking in Module: $module_name ..."
            
            cd "$(pwd)/$module_name"
            print_message info "Module Directory: $(pwd)"
            print_message info "pom file path: $(pwd)/pom.xml"

            # Checking Module POM
            scan_packages_pom

            print_message info "Going back to Root Directory..."
            # Back to Root Directory
            cd ..
            print_message info "Current dir: $(pwd)"
        done
    fi
}

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

listing_user_packages() {

    # Initializing User Package List Strings
    user_dependencies=""
    user_pluginManagement=""
    user_build=""
    user_reporting=""

    check_for_multi_module_project

    save_package_details "Dependencies" "user_dependencies" "$user_dependencies" "user_dependencies_count"
    save_package_details "Plugin Management" "user_pluginManagement" "$user_pluginManagement" "user_pluginManagement_count"
    save_package_details "Build" "user_build" "$user_build" "user_build_count"
    save_package_details "Reporting" "user_reporting" "$user_reporting" "user_reporting_count"
}

listing_user_packages