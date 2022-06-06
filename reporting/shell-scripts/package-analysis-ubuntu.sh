# Print Messages with colored prefix
print_message() {
    TYPE=$1
    MESSAGE=$2
    if [[ $TYPE = "warning" ]]
    then
        printf "[\e[1;33;40mWARNING\e[0m] %s\n" "$MESSAGE"
    elif [[ $TYPE = "success" ]]
    then
        printf "[\e[1;32;40mSUCCESS\e[0m] %s\n" "$MESSAGE"
    elif [[ $TYPE = "info" ]]
    then
        printf "[\e[1;35;40mINFO\e[0m] %s\n" "$MESSAGE"
    elif [[ $TYPE = "highlight" ]]
    then
        printf "\e[1;37;40m%s\e[0m" "$MESSAGE"
    fi
}

prequisites() {
    print_message info "Current Directory: $(pwd)"

    directory="Package_Management"
    mkdir -p "$directory"

    package_management_path="$(pwd)/$directory"

    print_message info "Dependency Management Path: $package_management_path"

    json_obj_directory="$package_management_path/json-obj"
    mkdir -p "$json_obj_directory"

    print_message info "Clearing previous data in dir: $json_obj_directory/*"
    rm -rf $json_obj_directory/*
}

write_file() {
    variable=$1
    data=$2
    operation=$3
    file=$4

    if [[ $operation = "overwrite" ]]
    then
        echo "$variable = $data;" > "$json_obj_directory/$file"
    elif [[ $operation = "append" ]]
    then
        echo "$variable = $data;" >> "$json_obj_directory/$file"
    fi

    print_message success "Saved in File: $json_obj_directory/$file"
}



####################################################################################################################
#                                            PGP Signature Verification
####################################################################################################################



pgp_signature_verification() {

    echo
    print_message info "---------------------------------------------------------"
    print_message info "             PGP Signature Verification"
    print_message info "---------------------------------------------------------"
    echo

    print_message info "Cleaning Target Folder..."
    mvn clean > /dev/null
    print_message info "Building project to refresh Artifacts and Signatures..."
    mvn install > /dev/null

    print_message info "Getting Signatures for all Dependencies..."
    # Running PGP verification plugin
    pgp_verify_output=$(mvn --no-transfer-progress org.simplify4u.plugins:pgpverify-maven-plugin:check)

    print_message info "Checking for Packages with Valid Signature..."
    # Valid Signatures
    signed_package_array=( $(printf "$pgp_verify_output" | grep "PGP Signature OK" | awk '{print $2}' | sort | uniq) )
    print_message success "Packages with Valid Signatures:"

    signed_package_list_json=$(printf "$pgp_verify_output" | grep "PGP Signature OK" | awk '{print $2}' | sort | uniq | gawk 'match ($0, /(.+):(.+):(\w{3}):(.+)/, array) {printf("{\"Group Id\": \"%s\", \"Artifact Id\": \"%s\", \"Packaging\": \"%s\", \"Version\": \"%s\", \"PGP Signature\": \"OK\"}\n", array[1], array[2], array[3], array[4])}' | jq -s)

    print_message info "Getting UserIds of Signatures..."
    declare -i c=0 #iterator for json obj
    for i in "${signed_package_array[@]}"
    do
        print_message info "Package: $i"
        N=$(echo "$pgp_verify_output" | grep -n -m 1 "$i PGP Signature OK" | cut -d : -f 1)
        user_ids=$(printf "$pgp_verify_output" | awk "NR==$N+1" | gawk 'match($0, /(UserIds: )(\[)(.*)(\])/, array) {print array[3]}')
        user_ids=${user_ids//[<]/(}
        user_ids=${user_ids//[>]/)}
        print_message info "Signature UserIds: $user_ids"
        signed_package_list_json=$(echo $signed_package_list_json | jq ".[$c] |= .+ {\"Signature UserIds\": \"$user_ids\"}")
        c=$(( c + 1 ))
    done

    print_message info "Saving Signed Package Details..."
    write_file "signed_package_list" "$signed_package_list_json" "overwrite" "pgp-signature-list.js"
    print_message info "Signed Package Details Saved."


    print_message info "Checking for Packages with No Signatures..."
    # Invalid Signatures
    unsigned_package_array=( $(printf "$pgp_verify_output" | grep "No signature for" | awk '{print $5}' | sort | uniq) )
    print_message warning "Packages with No Signatures:"
    echo "${unsigned_package_array[@]}" | tr ' ' '\n'

    unsigned_package_list_json=$(printf "$pgp_verify_output" | grep "No signature for" | awk '{print $5}' | sort | uniq | gawk 'match ($0, /(.+):(.+):(\w{3}):(.+)/, array) {printf("{\"Group Id\": \"%s\", \"Artifact Id\": \"%s\", \"Packaging\": \"%s\", \"Version\": \"%s\", \"PGP Signature\": \"NOT FOUND\", \"Signature UserIds\": \"-\"}\n", array[1], array[2], array[3], array[4])}' | jq -s)

    print_message info "Saving Unsigned Package Details..."
    write_file "unsigned_package_list" "$unsigned_package_list_json" "append" "pgp-signature-list.js"
    print_message info "Unsigned Package Details Saved."

    print_message success "PGP Signature Verification completed and results saved."
}



####################################################################################################################
#                                             Checksum Validation
####################################################################################################################



# Compare the equality between generated checksum and stored checksum (sha1)
compare_checksum() {
    FILE_PATH=$1
    FILE_TYPE=$2

    # Generate SHA1 checksum
    GENERATED_CHECKSUM=$(sha1sum $FILE_PATH | awk '{print $1}')
    print_message info "Generated Checksum: $GENERATED_CHECKSUM"
    
    # Get Stored Checksum
    AVAILABLE_CHECKSUM=$(cat $FILE_PATH.sha1 | awk '{print $1}')
    print_message info "Available Checksum: $AVAILABLE_CHECKSUM"

    # compare checksum for dependency's jar file
    if [[ $GENERATED_CHECKSUM = $AVAILABLE_CHECKSUM ]]
    then
        VALIDITY="Passed"
        print_message success "Checksum is Valid"
    else
        VALIDITY="Failed"
        print_message warning "Checksum is Invalid"
    fi
    print_message info "Validity: $VALIDITY"

    checksum_json_obj=$(echo $checksum_json_obj | \
        jq ".[.|length] |= .+ { \
            \"Classpath\": \"$FILE_PATH\", \
            \"File Type\": \"$FILE_TYPE\", \
            \"Generated Checksum\": \"$GENERATED_CHECKSUM\", \
            \"Available Checksum\": \"$AVAILABLE_CHECKSUM\", \
            \"Verification\": \"$VALIDITY\"}")
}

# Validate the checksum of all dependencies' jar and pom files
checksum_validation() {

    echo
    print_message info "---------------------------------------------------------"
    print_message info "                 Checksum Validation"
    print_message info "---------------------------------------------------------"
    echo

    print_message info "Running Maven In-built Checksum Validator..."
    # Maven In-built Checksum Validation
    mvn_checksum_verify_output=$(mvn --lax-checksums --no-transfer-progress -DskipTests verify)
    echo "$mvn_checksum_verify_output" | grep "WARNING"
    echo "$mvn_checksum_verify_output" | grep "ERROR"

    checksum_json_obj=$(echo "[]" | jq)
    export checksum_json_obj

    print_message info "Getting Classpath of All Dependencies..."
    # Maven command to get classpath of all dependencies being used in the project
    OUTPUT=$(mvn dependency:build-classpath)

    M=( $(echo "$OUTPUT" | grep -n "Dependencies classpath:" | cut -d : -f 1) )
    # declare -p M > /dev/null

    # Initialising an empty bash array
    classpath_array=()

    for m in "${M[@]}"
    do
        # Storing all the classpaths in a bash array
        classpath_array+=( $(echo "$OUTPUT" | awk "NR==$m+1" | awk 'BEGIN{RS=":"}{printf $1 "\n"}') )
    done

    # Removing Duplicate Values in case of multi module projects
    classpath_array_uniq=( $(echo "${classpath_array[@]}" | tr ' ' '\n' | sort | uniq) )
    # Iterating through the classpath array
    for i in "${classpath_array_uniq[@]}"
    do
        JAR_FILE_PATH=$i
        print_message info "jar location: $JAR_FILE_PATH"
        
        compare_checksum $JAR_FILE_PATH "jar"

        POM_FILE_PATH=$(echo "${i:0:-3}pom")
        print_message info "pom location: $POM_FILE_PATH"

        compare_checksum $POM_FILE_PATH "pom"
    done

    print_message info "Saving Checksum Validation Results..."
    # Saving the JSON as a JS Object to be used in HTML Report
    write_file "checksum_validation_list" "$checksum_json_obj" "overwrite" "checksum-validation-list.js"

    print_message success "Checksum Validation Completed, and results saved."
}



####################################################################################################################
#                                             Client Side Validation
####################################################################################################################



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
    check_package_version "Dependency" "dependencies" "project.dependencies" "dependencies/dependency"
    check_package_version "Plugin Management Plugins" "pluginManagement" "project.build.pluginManagement" "pluginManagement/plugins/plugin"
    check_package_version "Build Plugins" "build" "project.build" "build/plugins/plugin"
    check_package_version "Reporting Plugins" "reporting" "project.reporting" "reporting/plugins/plugin"
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

    # Defining Empty String
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



####################################################################################################################
#                                             Unused Dependency Check
####################################################################################################################



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
        print_message success "No Unused Package Found"
        write_file "unused_dependency_list" "[]" "overwrite" "unused-dep-list.js"
    fi
}



####################################################################################################################
#                                         Source Repository Verification
####################################################################################################################



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



####################################################################################################################
#                                         MVN Site Plugin Reporting
####################################################################################################################



mvn_site_plugin_reporting() {

    echo
    print_message info "---------------------------------------------------------"
    print_message info "             MVN Site Plugin Reporting"
    print_message info "---------------------------------------------------------"
    echo

    print_message info "Running mvn site for plugin reporting..."
    mvn org.apache.maven.plugins:maven-site-plugin:3.10.0:site

    print_message info "Running dependency-check plugin..."
    mvn org.owasp:dependency-check-maven:6.5.3:aggregate -Dodc.outputDirectory=target/site

    print_message info "Creating site directory in dependency management folder..."
    mkdir -p "$package_management_path/site"
    print_message info "Directory Created: $package_management_path/site"

    print_message info "Clearing previous site reports..."
    rm -rf "$package_management_path/site/*"

    # Checking for Multi Module Projects
    print_message info "Checking for Multi Module Project..."
    module_xml_output=$(mvn --no-transfer-progress help:evaluate -Dexpression=project -q -DforceStdout)
    M=$(echo "$module_xml_output" | grep -n "<modules>" | cut -d : -f 1)
    N=$(echo "$module_xml_output" | grep -n "</modules>" | cut -d : -f 1)

    if [[ -z "$M" ]]
    then
        print_message info "Single POM project."

        print_message info "Getting Reporting HTMLs from target folder..."
        cp -R target/site/* "$package_management_path/site"
    else
        print_message info "Multi Module Project."

        module_xml_required=$(echo "$module_xml_output" | awk "NR==$M, NR==$N")

        # Getting total number of tags
        MODULE_COUNT=$(echo "$module_xml_required" | xpath -e "count(modules/module)" 2>/dev/null)
        print_message info "No. of Modules in project: $MODULE_COUNT"

        print_message info "Getting Reports of Parent Module..."
        # Getting Reports of Root (parent) Module
        cp -R target/site/* "$package_management_path/site"
        print_message info "Parent Module Reports Fetched"

        # Iterating over all Modules
        for (( p=1; p<=MODULE_COUNT; p++ ))
        do
            print_message info "$p"
            module_name=$(echo "$module_xml_required" | xpath -e "modules/module[position()=$p]/text()" 2>/dev/null)
            print_message info "Module: $module_name ..."
            
            cd "$(pwd)/$module_name"
            print_message info "Module Directory: $(pwd)"

            print_message info "Creating module directory in dependency management site folder..."
            mkdir -p "$package_management_path/site/$module_name"

            print_message info "Getting Reports of Module: $module_name ..."
            # Getting Module Reports
            cp -R target/site/* "$package_management_path/site/$module_name"
            print_message info "Module: $module_name Reports Fetched"

            print_message info "Going back to Root Directory..."
            # Back to Root Directory
            cd ..
            print_message info "Current dir: $(pwd)"
        done
    fi
}


# Calling Functions
prequisites
pgp_signature_verification
checksum_validation
client_side_validation
list_unused_dependencies
verify_secure_repo_connection
mvn_site_plugin_reporting