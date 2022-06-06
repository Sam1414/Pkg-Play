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



prequisites
checksum_validation