// Total Packages (Dependencies + pluginManagement plugins + ) declared in User POM
var total_user_packages = user_dependencies_count + user_pluginManagement_count + user_build_count + user_reporting_count;

const dependency_table = document.getElementById('dependency-table');
const checksum_table = document.getElementById('checksum-table');
const version_table = document.getElementById('version-table');
const unused_dep_table = document.getElementById('unused-dep-table');
const source_repo_table = document.getElementById('source-repo-table');

function create_fill_table_head(table, data_list, className) {
    // Creating Table Head
    var thead = document.createElement('thead');
    thead.className = className;
    var th_row = document.createElement('tr');
    thead.appendChild(th_row);
    table.appendChild(thead);

    // Filling Table Head
    for (let i = 0; i < data_list.length; i++) {
        var th_cell = document.createElement('th');
        th_cell.innerHTML = data_list[i];
        th_row.appendChild(th_cell);
    }
}

function pgp_signature_verification() {

    // Getting column names for the dependency table
    var keys = Object.keys(signed_package_list[0]);

    // Create and Fill Table Header
    create_fill_table_head(dependency_table, keys, 'table-dark');

    // Creating Table Body
    var tbody = document.createElement('tbody');
    dependency_table.appendChild(tbody);

    var unsigned_dep_count = 0;
    var signed_dep_count = 0;

    /* Filling Table Body */
    // Inserting Rows with Unsigned Packages
    for (var i = 0; i < unsigned_package_list.length; i++) {
        unsigned_dep_count += 1;
        var tb_row = document.createElement('tr');
        tb_row.className = 'table-danger';
        tbody.appendChild(tb_row);
        for (var key in signed_package_list[i]) {
            var tb_cell = document.createElement('td');
            tb_cell.innerHTML = unsigned_package_list[i][key];
            tb_row.appendChild(tb_cell);
        }
    }

    // Inserting Rows with Signed Packages
    for (var i = 0; i < signed_package_list.length; i++) {
        signed_dep_count += 1;
        var tb_row = document.createElement('tr');
        tb_row.className = 'table-success';
        tbody.appendChild(tb_row);
        for (var key in signed_package_list[i]) {
            var tb_cell = document.createElement('td');
            tb_cell.innerHTML = signed_package_list[i][key];
            tb_row.appendChild(tb_cell);
        }
    }

    // Writing PGP Verification Summary Report
    pgp_summary(signed_dep_count, unsigned_dep_count);
}

function pgp_summary(signed_dep_count, unsigned_dep_count) {
    var total_dependencies_checked = unsigned_dep_count + signed_dep_count;
    var percentage_unsigned = unsigned_dep_count / (total_dependencies_checked) * 100;
    percentage_unsigned = Math.round((percentage_unsigned) * 100) / 100;

    var total_deps = summary_writing('Total Dependencies Checked for Signatures: ', total_dependencies_checked);
    var unsigned_deps = summary_writing('Total Unsigned Dependencies: ', unsigned_dep_count);
    var signed_deps = summary_writing('Total Signed Dependencies: ', signed_dep_count);
    var percent_unsigned_deps = summary_writing('Percentage of Unsigned Dependencies: ', percentage_unsigned + '%');
    var pgp_summary = document.getElementById('pgp-summary');

    pgp_summary.appendChild(total_deps);
    pgp_summary.appendChild(unsigned_deps);
    pgp_summary.appendChild(signed_deps);
    pgp_summary.appendChild(percent_unsigned_deps);
}

function checksum_validation() {
    if (checksum_validation_list.length === 0 || checksum_validation_list === undefined) {
        // Adding just a table row if no data available
        data_not_found(checksum_table, 'No Checksum Data Found', 'table-warning');
    } else {
        // Getting column names for the dependency table
        var keys = Object.keys(checksum_validation_list[0]);

        // Create and Fill Table Header
        create_fill_table_head(checksum_table, keys, 'table-dark');

        var jar_count = 0;
        var pom_count = 0;
        var failed = 0;
        var passed = 0;

        // Creating Table Body
        var tbody = document.createElement('tbody');
        checksum_table.appendChild(tbody);

        /** Filling Table Body */

        // Inserting Rows with Issues
        for (var i = 0; i < checksum_validation_list.length; i++) {

            if (checksum_validation_list[i]['File Type'] === 'jar') {
                jar_count += 1;
            } else if (checksum_validation_list[i]['File Type'] === 'pom') {
                pom_count += 1;
            }

            if (checksum_validation_list[i]['Verification'] === 'Failed') {
                failed += 1;
                var tb_row = document.createElement('tr');
                tb_row.className = 'table-danger';
                tbody.appendChild(tb_row);
                for (var key in checksum_validation_list[i]) {
                    var tb_cell = document.createElement('td');
                    tb_cell.innerHTML = checksum_validation_list[i][key];
                    tb_row.appendChild(tb_cell);
                }
            } else {
                passed += 1;
            }
        }

        // Inserting Rows with No Issues
        for (var i = 0; i < checksum_validation_list.length; i++) {

            if (checksum_validation_list[i]['Verification'] === 'Passed') {
                var tb_row = document.createElement('tr');
                tb_row.className = 'table-success';
                tbody.appendChild(tb_row);
                for (var key in checksum_validation_list[i]) {
                    var tb_cell = document.createElement('td');
                    tb_cell.innerHTML = checksum_validation_list[i][key];
                    tb_row.appendChild(tb_cell);
                }
            }
        }

        // Writing Checksum Verification Summary Report
        checksum_summary(checksum_validation_list.length, jar_count, pom_count, passed, failed);
    }
}

function checksum_summary(total_files, jar_count, pom_count, passed, failed) {
    var total_files_checked = summary_writing('Total Files checked: ', total_files);
    var total_jars = summary_writing('Total JAR Files checked: ', jar_count);
    var total_poms = summary_writing('Total POM Files checked: ', pom_count);
    var total_dependencies = summary_writing('Total Dependencies checked: ', jar_count);
    var total_passed = summary_writing('Total Files with valid checksum: ', passed);
    var total_failed = summary_writing('Total Files with invalid checksum: ', failed);
    var percent_failed_cal = Math.round(((failed / (failed + passed)) * 100) * 100) / 100;
    var percent_failed = summary_writing('Percentage of Files that failed Checksum Validation: ', percent_failed_cal + '%');

    var checksum_summary = document.getElementById('checksum-summary');
    checksum_summary.appendChild(total_files_checked);
    checksum_summary.appendChild(total_dependencies);
    checksum_summary.appendChild(total_jars);
    checksum_summary.appendChild(total_poms);
    checksum_summary.appendChild(total_passed);
    checksum_summary.appendChild(total_failed);
    checksum_summary.appendChild(percent_failed);
}

function summary_writing(message, value) {
    var message_element = document.createElement('b');
    message_element.innerHTML = message;
    var value_element = document.createElement('span');
    value_element.innerHTML = value;

    var result_element = document.createElement('span');
    result_element.appendChild(message_element);
    result_element.appendChild(value_element);
    result_element.appendChild(document.createElement('br'));

    return result_element;
}

function version_declaration_warning() {

    var unsafe_declarations = {
        open_lb_count: 0,
        open_ub_count: 0,
        comma_count: 0,
        release_count: 0,
        milestone_count: 0,
        snapshot_count: 0,
        cr_count: 0,
        rc_count: 0,
        alpha_count: 0,
        beta_count: 0
    }

    var package_count = { dependencyCount: 0, pluginManagementCount: 0, buildPluginCount: 0, reportingPluginCount: 0 };

    // Getting column names for the dependency table
    var keys = Object.keys(version_check_list[0]);

    // Create and Fill Table Header
    create_fill_table_head(version_table, keys, 'table-dark');

    // Creating Table Body
    var tbody = document.createElement('tbody');
    version_table.appendChild(tbody);

    /** Filling Table Body */

    // Inserting Rows with Issues
    for (var i = 0; i < version_check_list.length; i++) {
        var tb_row = document.createElement('tr');
        tb_row.className = "table-danger"
        tbody.appendChild(tb_row);

        switch (version_check_list[i]['Type']) {
            case 'Dependency':
                package_count.dependencyCount += 1;
                break;
            case 'Plugin-Management Plugin':
                package_count.pluginManagementCount += 1;
                break;
            case 'Build Plugin':
                package_count.buildPluginCount += 1;
                break;
            case 'Reporting Plugin':
                reportingPluginCount += 1;
                break;
        }

        for (var key in version_check_list[i]) {
            var tb_cell = document.createElement('td');
            tb_row.appendChild(tb_cell);
            if (typeof(version_check_list[i][key]) === 'string') {
                tb_cell.innerHTML = version_check_list[i][key];
            } else {
                var ul = document.createElement('ul');
                tb_cell.appendChild(ul);
                for (var sub_key in version_check_list[i][key]) {
                    li = document.createElement('li');
                    li.innerHTML = version_check_list[i][key][sub_key];
                    ul.appendChild(li);
                    // Updating counters
                    switch (version_check_list[i][key][sub_key]) {
                        case 'Open Lower Bound --> (':
                            unsafe_declarations.open_lb_count += 1;
                            break;
                        case 'Open Upper Bound --> )':
                            unsafe_declarations.open_ub_count += 1;
                            break;
                        case 'Separator (comma) --> ,':
                            unsafe_declarations.comma_count += 1;
                            break;
                        case 'RELEASE':
                            unsafe_declarations.release_count += 1;
                            break;
                        case 'MILESTONE':
                            unsafe_declarations.milestone_count += 1;
                            break;
                        case 'SNAPSHOT':
                            unsafe_declarations.snapshot_count += 1;
                            break;
                        case 'CR':
                            unsafe_declarations.cr_count += 1;
                            break;
                        case 'RC':
                            unsafe_declarations.rc_count += 1;
                            break;
                        case 'ALPHA':
                            unsafe_declarations.alpha_count += 1;
                            break;
                        case 'BETA':
                            unsafe_declarations.beta_count += 1;
                            break;
                    }
                }
            }
        }
    }

    // Writing Summary for Version Declaration Report
    version_check_summary(package_count, unsafe_declarations);
}

function version_check_summary(package_count, unsafe_declarations) {
    var version_summary = document.getElementById('version-summary');
    total_unsafe_version_packages = package_count.dependencyCount + package_count.pluginManagementCount + package_count.buildPluginCount + package_count.reportingPluginCount;
    version_summary.appendChild(summary_writing('Total Packages in User POM: ', total_user_packages));
    version_summary.appendChild(summary_writing('Total Dependencies: ', user_dependencies_count));
    version_summary.appendChild(summary_writing('Total Plugin Management Plugins: ', user_pluginManagement_count));
    version_summary.appendChild(summary_writing('Total Build Plugins: ', user_build_count));
    version_summary.appendChild(summary_writing('Total Reporting Plugins: ', user_reporting_count));
    version_summary.appendChild(summary_writing('Total Unsafe Version Declarations: ', total_unsafe_version_packages));
    version_summary.appendChild(summary_writing('Total Unsafe Dependency Declarations: ', package_count.dependencyCount));
    version_summary.appendChild(summary_writing('Unsafe Plugin-Management Plugin Declarations: ', package_count.pluginManagementCount));
    version_summary.appendChild(summary_writing('Unsafe Build Plugin Declarations: ', package_count.buildPluginCount));
    version_summary.appendChild(summary_writing('Unsafe Reporting Plugin Declarations: ', package_count.reportingPluginCount));
    version_summary.appendChild(summary_writing('Version Declarations with Open Lower Bound: ', unsafe_declarations.open_lb_count));
    version_summary.appendChild(summary_writing('Version Declarations with Open Upper Bound: ', unsafe_declarations.open_ub_count));
    version_summary.appendChild(summary_writing('Version Declarations with Separator (comma): ', unsafe_declarations.comma_count));
    version_summary.appendChild(summary_writing('RELEASE Versions: ', unsafe_declarations.release_count));
    version_summary.appendChild(summary_writing('MILESTONE Versions: ', unsafe_declarations.milestone_count));
    version_summary.appendChild(summary_writing('SNAPSHOT Versions: ', unsafe_declarations.snapshot_count));
    version_summary.appendChild(summary_writing('CR Versions: ', unsafe_declarations.cr_count));
    version_summary.appendChild(summary_writing('RC Versions: ', unsafe_declarations.rc_count));
    version_summary.appendChild(summary_writing('ALPHA Versions: ', unsafe_declarations.alpha_count));
    version_summary.appendChild(summary_writing('BETA Versions: ', unsafe_declarations.beta_count));
}

function list_unused_dependency() {

    var unused_deps_count = 0;

    if (unused_dependency_list.length === 0 || unused_dependency_list === undefined) {
        // Adding just a table row if no data available
        data_not_found(unused_dep_table, 'No Unused Packages Found', 'table-success');
    } else {
        // Getting column names for the dependency table
        var keys = Object.keys(unused_dependency_list[0]);

        // Create and Fill Table Header
        create_fill_table_head(unused_dep_table, keys, 'table-dark');

        // Creating Table Body
        var tbody = document.createElement('tbody');
        unused_dep_table.appendChild(tbody);

        /** Filling Table Body */

        // Inserting Rows with Issues
        for (var i = 0; i < unused_dependency_list.length; i++) {
            unused_deps_count += 1;
            var tb_row = document.createElement('tr');
            tb_row.className = 'table-danger';
            tbody.appendChild(tb_row);
            for (var key in unused_dependency_list[i]) {
                var tb_cell = document.createElement('td');
                tb_cell.innerHTML = unused_dependency_list[i][key];
                tb_row.appendChild(tb_cell);
            }
        }
    }



    // Writing Summary for Unused Dependencies report
    unused_dependencies_summary(unused_deps_count);
}

function unused_dependencies_summary(unused_deps_count) {
    var unused_dep_summary = document.getElementById('unused-dep-summary');
    unused_dep_summary.appendChild(summary_writing('Unused Dependencies: ', unused_deps_count));
    unused_dep_summary.appendChild(summary_writing('Total User Declared Packages: ', total_user_packages));
    var percent_unused = Math.round(((unused_deps_count / total_user_packages) * 100) * 100) / 100;
    unused_dep_summary.appendChild(summary_writing('Percentage of Unused Dependencies: ', percent_unused + '%'));
}

function source_repo_verification() {

    var repos_count = 0;
    var secure_repo_count = 0;
    var insecure_repo_count = 0;

    source_repo_list = remove_duplicate_nodes_json(source_repo_list);

    // Getting column names for the dependency table
    var keys = Object.keys(source_repo_list[0]);

    // Create and Fill Table Header
    create_fill_table_head(source_repo_table, keys, 'table-dark');

    // Creating Table Body
    var tbody = document.createElement('tbody');
    source_repo_table.appendChild(tbody);

    /** Filling Table Body */

    // Inserting Rows with Issues
    for (var i = 0; i < source_repo_list.length; i++) {
        repos_count += 1;
        var tb_row = document.createElement('tr');

        if (source_repo_list[i]['Security'] === 'INSECURE') {

            tb_row.className = 'table-danger';
            insecure_repo_count += 1;

            tbody.appendChild(tb_row);
            for (var key in source_repo_list[i]) {
                var tb_cell = document.createElement('td');
                tb_cell.innerHTML = source_repo_list[i][key];
                tb_row.appendChild(tb_cell);
            }
        }
    }

    // Inserting Rows with No Issues
    for (var i = 0; i < source_repo_list.length; i++) {
        var tb_row = document.createElement('tr');

        if (source_repo_list[i]['Security'] === 'SECURE') {

            tb_row.className = 'table-success';
            secure_repo_count += 1;

            tbody.appendChild(tb_row);
            for (var key in source_repo_list[i]) {
                var tb_cell = document.createElement('td');
                tb_cell.innerHTML = source_repo_list[i][key];
                tb_row.appendChild(tb_cell);
            }
        }

    }

    // Writing Summary for Unused Dependencies report
    source_repo_summary(repos_count, secure_repo_count, insecure_repo_count);
}

function source_repo_summary(repos_count, secure_repo_count, insecure_repo_count) {
    var repo_summary = document.getElementById('source-repo-summary');
    repo_summary.appendChild(summary_writing('Total Source Repositories: ', repos_count));
    repo_summary.appendChild(summary_writing('Source Repositories with Secure Connection: ', secure_repo_count));
    repo_summary.appendChild(summary_writing('Source Repositories with Insecure Connection: ', insecure_repo_count));
    percent_insecure = (insecure_repo_count / repos_count) * 100;
    percent_insecure = Math.round(percent_insecure * 100) / 100;
    repo_summary.appendChild(summary_writing('Percentage of Insecure Source Repositories: ', percent_insecure + '%'));
}

function remove_duplicate_nodes_json(jsonData) {
    jsonObject = jsonData.map(JSON.stringify);
    uniqueSet = new Set(jsonObject);
    uniqueArray = Array.from(uniqueSet).map(JSON.parse);
    return uniqueArray;
}

function data_not_found(accordion_collapse_div, table, message, table_row_className) {
    var tbody = document.createElement('tbody');
    var tb_row = document.createElement('tr');
    var tb_cell = document.createElement('td');

    table.appendChild(tbody);
    tbody.appendChild(tb_row);
    tb_row.appendChild(tb_cell);

    tb_row.className = table_row_className + ' fs-4';
    tb_cell.innerHTML = message;

    accordion_collapse_div.className += 'show';
}

pgp_signature_verification();
checksum_validation();
version_declaration_warning();
list_unused_dependency();
source_repo_verification();