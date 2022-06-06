print_message() {
    TYPE=$1
    MESSAGE=$2
    if [[ $TYPE = "warning" ]]
    then
        printf "\e[1;33;40m[WARNING]\e[0m: %s\n" "$MESSAGE"
    elif [[ $TYPE = "success" ]]
    then
        printf "\e[1;32;40m[SUCCESS]\e[0m: %s\n" "$MESSAGE"
    elif [[ $TYPE = "info" ]]
    then
        printf "\e[1;35;40m[INFO]\e[0m: %s\n" "$MESSAGE"
    elif [[ $TYPE = "highlight" ]]
    then
        printf "\e[1;37;40m%s\e[0m" "$MESSAGE"
    fi
}

prequisites() {
    print_message info "Current Directory: $(pwd)"

    mkdir -p maven-dependency-management
}

pgp_signature_verification() {

    echo
    print_message info "---------------------------------------------------------"
    print_message info "            PGP Signature Verification"
    print_message info "---------------------------------------------------------"
    echo

    print_message info "Cleaning Target Folder..."
    mvn clean > /dev/null
    print_message info "Building project to refresh Artifacts and Signatures..."
    mvn install > /dev/null

    print_message info "Getting Signatures for all Dependencies..."
    # PGP verification
    pgp_verify_output=$(mvn --no-transfer-progress org.simplify4u.plugins:pgpverify-maven-plugin:check)

    print_message info "Getting List of all the Dependencies..."
    # Listing all Dependencies
    dep_list=$(mvn dependency:list)
    dep_list_json=$(printf "$dep_list" | gawk 'match($0, /(^\[INFO\]\s{4})(.+):(.+):(\w+):(.+):(\w+)/, array) {printf("{\"groupId\": \"%s\", \"ArtifactId\": \"%s\", \"Packaging\": \"%s\", \"Version\": \"%s\", \"Scope\": \"%s\"},\n", array[2], array[3], array[4], array[5], array[6])}')

    dep_list_json_obj=$(echo "[${dep_list_json::-1}]" | jq)
    echo "$dep_list_json_obj" | jq

    print_message info "Saving Dependency List JSON..."
    # Saving Dependency List as a JS Object
    echo "dependencies = [$dep_list_json_obj];" > maven-dependency-management/dep-list.js
    print_message info "Saved Dependency List JSON in dep-list.js file"

    len=$(echo "$dep_list_json_obj" | jq '. | length')
    print_message info "Number of Dependencies Listed: $len"

    print_message info "Checking Signature Validity against each dependency from dependency list..."
    for (( i=0; i<len; i++ ))
    do 
        groupId=$(echo "$dep_list_json_obj" | jq ".[$i].groupId" | xargs -I {} echo {})
        artifactId=$(echo "$dep_list_json_obj" | jq ".[$i].ArtifactId" | xargs -I {} echo {})
        packaging=$(echo "$dep_list_json_obj" | jq ".[$i].Packaging" | xargs -I {} echo {})
        version=$(echo "$dep_list_json_obj" | jq ".[$i].Version" | xargs -I {} echo {})
        
        print_message info "$groupId:$artifactId:$packaging:$version"
        dep="$groupId:$artifactId:$packaging:$version"

        gawk_query="printf \"$pgp_verify_output\" | gawk 'match(\$0, /$dep PGP Signature OK/, array) {print}'"
        # gawk_query="printf \"\$pgp_verify_output\" | gawk 'match(\$0, /$dep/, array) {print}'"

        sign_found=$(eval "$gawk_query")

        user_ids=""

        if [[ -z "$sign_found" ]]
        then
            # No Signature Found
            print_message warning "No Signature Found"
            dep_list_json_obj=$(echo "$dep_list_json_obj" | jq ".[$i] |= .+ {\"PGP Signature\": \"NOT FOUND\", \"Sign UserIds\": \"-\"}")
        else
            # PGP Signature OK
            print_message success "Valid Signature Found - OK"
            
            N=$(printf "$pgp_verify_output" | grep -n "$dep PGP Signature OK" | cut -d : -f 1)
            user_ids=$(printf "$pgp_verify_output" | awk "NR==$N+1" | gawk 'match($0, /(UserIds: )(\[)(.*)(\])/, array) {print array[3]}')
            user_ids=${user_ids//[<]/(}
            user_ids=${user_ids//[>]/)}
            echo "$user_ids"
            dep_list_json_obj=$(echo "$dep_list_json_obj" | jq ".[$i] |= .+ {\"PGP Signature\": \"OK\", \"Signature UserIds\": \"$user_ids\"}")
        fi

        # mvn --no-transfer-progress org.simplify4u.plugins:pgpverify-maven-plugin:show -Dartifact="$dep"
    done

    print_message info "Saving Results to show in Report..."
    echo "dependencies_pgp = $dep_list_json_obj" > maven-dependency-management/pgp-sign-list.js

    print_message success "PGP Verification Done & Results Saved in Report"
}


prequisites

pgp_signature_verification
