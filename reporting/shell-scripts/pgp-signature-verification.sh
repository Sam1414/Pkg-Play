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
    echo "${signed_package_array[@]}" | tr ' ' '\n'

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

prequisites

pgp_signature_verification