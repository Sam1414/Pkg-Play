# Dependency Managment 

- [Dependency Managment](#dependency-managment)
  - [Need For Dependency Management](#need-for-dependency-management)
    - [Types of Dependencies](#types-of-dependencies)
      - [Direct Dependencies](#direct-dependencies)
      - [Transitive Dependencies](#transitive-dependencies)
      - [Development Dependencies](#development-dependencies)
      - [Runtime Dependencies](#runtime-dependencies)
    - [Possible Issues](#possible-issues)
      - [Substitution Attack](#substitution-attack)
      - [Unused Packages](#unused-packages)
      - [Outdated Packages](#outdated-packages)
        - [Consequences of keeping outdated dependencies](#consequences-of-keeping-outdated-dependencies)
        - [Security Vulnerabilities](#security-vulnerabilities)
        - [Reduced Performance](#reduced-performance)
        - [Coupled Processes in Apps](#coupled-processes-in-apps)
        - [Overhead Work](#overhead-work)
        - [Expanded Attack Surface](#expanded-attack-surface)
    - [Licensing](#licensing)
      - [Open source license compliance: Don’t put your IP at risk](#open-source-license-compliance-dont-put-your-ip-at-risk)
    - [Vulnerable Dependencies](#vulnerable-dependencies)
      - [What are Vulnerable Dependencies?](#what-are-vulnerable-dependencies)
        - [An Example of a Vulnerability](#an-example-of-a-vulnerability)
      - [Utilize client-side verification features](#utilize-client-side-verification-features)
  - [Proposed Solution / Features](#proposed-solution--features)
      - [Technologies / Frameworks for which our solution is available](#technologies--frameworks-for-which-our-solution-is-available)
      - [Features Covered in each Solution](#features-covered-in-each-solution)
        - [1. Maven Solution](#1-maven-solution)
        - [2. Dotnet Solution](#2-dotnet-solution)
        - [3. NPM Solution](#3-npm-solution)
    - [Tech Stack Used](#tech-stack-used)
  - [Demo](#demo)
    - [1. Dotnet Utility](#1-dotnet-utility)
      - [Installation](#installation)
        - [Add Source](#add-source)
        - [Install Tool Globally](#install-tool-globally)
        - [Install Tool Locally](#install-tool-locally)
      - [Usage](#usage)
      - [CLI Options](#cli-options)
      - [Usage Examples](#usage-examples)
    - [2. NPM Utility](#2-npm-utility)
      - [Installation](#installation-1)
        - [Setup Credentials](#setup-credentials)
          - [Step 1](#step-1)
          - [Step 2](#step-2)
          - [Step 3](#step-3)
          - [Step 4](#step-4)
        - [Install Package](#install-package)
      - [Usage](#usage-1)
      - [CLI Options](#cli-options-1)
      - [Usage Examples](#usage-examples-1)
    - [4. Maven Utility](#4-maven-utility)
      - [Installation](#installation-2)
      - [Usage in POM](#usage-in-pom)
      - [Usage via CLI](#usage-via-cli)
      - [CLI Options / Goals](#cli-options--goals)
      - [Usage Examples](#usage-examples-2)


---

## Need For Dependency Management 

Build automation tools and package managers have a profound influence on software development. They facilitate the reuse of third-party libraries, support a clear separation between the application’s code and its external dependencies, and automate several software development tasks. However, the wide adoption of these tools introduces new challenges related to dependency management. 

Many organizations use public package sources — such as Maven Central, npm, NuGet Gallery, and the Python Package Index (PyPI) — to take advantage of the offered open ecosystem which results in uncurated sources as a potential source of malware.  A critical factor in development of ecosystems around package indexes that allow anyone to publish, such as Maven Central, npm, NuGet Gallery, and Python Package Index. A public, open-package index allows anyone to share their code without proving their identity. Organizations uses private repository source as package index mirrors or to distribute internal packages to protect against upstream compromises, such as package hijacking and typo-squatting. Package management tools typically allow specifying multiple sources from which to download components, making it easy to consume from public and private indexes.

The term “dependencies” can be fundamentally defined as the files, packages, libraries, or plugins integrated into a project to implement a specific task or set of tasks. It is a modern way to leverage code from various developers, but it also creates a reliance on external code for the project to operate properly.

For example, let's suppose you're adding encryption to your application and you include a third-party library to get the job done. The library responsible for handling encryption will be a dependency for your application in this particular case.

If you're working on a large project codebase that introduces new versions of packages for each module, the branches on your dependency tree will continue to multiply until maintenance becomes a total headache. Updating and managing a dependency package, which in turn depends on another package or library, is a complicated process. Dependencies can become locked together and tightly coupled in this way.

### Types of Dependencies
Dependencies come in many varieties across all platforms. Running and maintaining applications on modern development channels usually requires at least a few dependencies. Major dependency types are:

#### Direct Dependencies
These include the direct integration of libraries or plugins within an application. In other words, they have been actually integrated into the app's code. You should avoid using different direct dependencies for the same functionality (such as multiple JSON parsing libraries).

#### Transitive Dependencies
Commonly referred to as a "dependency of a dependency", a transitive dependency is a library called by one of your direct dependencies. Conflicts originate when a direct dependency does not support updated versions of its transitive dependencies. For example, let's say that Library A is dependent on version 0.1 of Library B, but your application requires version 0.2 of Library B. How can you know if Library A is compatible with version 0.2 of Library B?

It is recommended to avoid using implicit transitive dependencies and to explicitly maintain all transitive dependencies that are in use by your direct dependencies.

#### Development Dependencies
Two types of dependencies are included in package.json, one of which is devDependencies. These dependencies are only executed and consumed by files in the development phase. They can be used on remote hosts, e.g. linter packages and presets.

#### Runtime Dependencies
These include both frontend dependencies (executed in the end user's browser) and backend dependencies (running in the backend for http communication).

### Possible Issues

#### Substitution Attack

A substitution attack happens when an attacker discovers that an organization is using a private package that is not present on the public source and after the attacker uploads a higher version of the private package to the public source, the organization downloads it automatically because it has the same file name. Services that merge package repository sources also allow this substitution if packages from public sources may override those from private sources. Not only this, but a related risk with a similar impact can also emerge if the package publisher’s credentials have been compromised.

> Most organizations automatically install the attacker’s package from the public repository source, which presents an attack opportunity.


#### Unused Packages

When using Package Managers to manage our project dependencies, we can lose track of what dependencies are used in our application. 

Whether you’re developing a personal project or a professional one, we all use sometimes a dependency to fix a problem, to try something, or to develop a client use case. However, the last version of the application may contain a variety of dependencies compared to its starting state that we don’t necessarily use finally in the application. For several reasons, clients need changing, fixing problems in the app, and so on.

That’s why checking at some moment the general state of the app is important. It’s really a waste to have dependencies that we don’t use. In the end, it’ll cost in terms of maintenance, optimization and cuts down the performance of your app significantly. Therefore we end up with a bundle size that has what we need and what we don’t.

By removing any unused references in your application, you are preventing the CLR from loading the unused referenced modules at runtime. Which means that you will reduce the startup time of your application, because it takes time to load each module and avoids having the compiler load metadata that will never be used. You may find that depending on the size of each library, your startup time is noticeably reduced. This isn’t to say that your application will be faster once loaded, but it can be pretty handy to know that your startup time might get reduced.

Another benefit of removing any unused references is that you will reduce the risk of conflicts with namespaces. For example, if you have both System.Drawing and System.Web.UI.WebControls referenced, you might find that you get conflicts when trying to reference the Image class. If you have using directives in your class that match these references, the compiler can’t tell which of the ones to use.

#### Outdated Packages

##### Consequences of keeping outdated dependencies
Developers sometimes do not update dependencies out of a fear that they will break their apps, but outdated dependencies can have serious negative impacts on applications. Improperly configured dependencies expose you to the following risks:

##### Security Vulnerabilities
External libraries and frameworks can contain malicious attacks and pass them on to your development environment, exposing your application to vulnerabilities and potentially passing the attacks on to others in the form of security breach.

##### Reduced Performance
Outdated dependencies can cause you to miss out on performance improvements in an application. The inclusion of external code already creates overhead in your app, so you want to ensure that your external code is running optimally. For example, if you use array.prototype.concat instead of load.concat, it degrades performance.

##### Coupled Processes in Apps
Circular dependencies must be handled effectively because they introduce conflicts in various processes of apps. Older or end-of-life versions of libraries should be replaced on time. Updating dependencies also helps in bug fixes.

##### Overhead Work
Delayed dependency upgrades can cost you a lot more effort in the future if you handle them as small, recurring tasks. For example, direct jumping from version 1 to version 4 can drag you into huge overhead maintenance, which could have been avoided if you had upgraded to version 3 and then to 4 within proper time frames.

##### Expanded Attack Surface
Outdated assets and libraries are not effective for any application or project. Implementations need to be either upgraded to recent versions or totally taken out so that they don't expose your development environment to outside attacks. Unused dependencies are considered abandoned, as they no longer serve any purpose in the app's functionality.

The above-mentioned points show that poor handling of dependencies can cause security risks as well as inconvenience.

### Licensing 

#### Open source license compliance: Don’t put your IP at risk
Synopsys tracks over 2,500 open source licenses, and while many are permissive, others, like the GNU General Public License (GPL), are reciprocal, imposing restrictions on the use or transfer of license terms for the software your team writes. Tracking and managing open source helps you avoid license violations that can result in costly litigation or compromise your valuable intellectual property.

### Vulnerable Dependencies

**Source: NVD, National Vulnerability Database** <br>
A Software Vulnerability is a security flaw, glitch or weakness found in software that can lead to security concerns.

#### What are Vulnerable Dependencies?
As applications have grown larger and more complex, the typical number of third-party dependencies has grown as well. This is helpful for developer productivity, since libraries and frameworks are now available to provide common functionality.

One issue with this trend, however, is that the application code base is no longer as opaque as it was when relying less on third-party code. When a security vulnerability is found in a third-party dependency, and a new version with a fix is released, it is the responsibility of the developer learn about this update and get the newly released version.

In addition to vulnerabilities occurring due to errors in the source code of third-party dependencies, there are cases of intentionally malicious packages being released on package management systems in order to exploit misspellings in the name or vacant names left by packages that are no longer maintained.

##### An Example of a Vulnerability
One of the most famous examples is the Heartbleed bug, discovered in 2014. In this case, the OpenSSL library, which is the underlying cryptographic software that is used internally by thousands of other libraries and applications, was found to have a critical security vulnerability.

When announced, this vulnerability forced developers to determine which of their dependencies relied on OpenSSL, verify that they had been updated to use the fixed OpenSSL version and upgrade the dependencies.


#### Utilize client-side verification features

Client-side verification features to protect against supply chain attacks. These include options such as version pinning and integrity verification. **Version pinning** is recommended as the baseline mitigation and is supported by most clients. Specifying precise versions for packages and transitive dependencies, rather than an open range (“3.5.4” rather than “>=3.5” or “3.5.*”), will mitigate forced upgrade or downgrade attacks. However, they will not prevent a compromised index from serving an alternate package and claiming it to be the same version. Specify precise versions for packages and dependencies to mitigate forced upgrade or downgrade attacks.



## Proposed Solution / Features

Using and taking advantage of 3rd party libraries and chunks of codes can be very handy, time saving and efficient, but at the same time they could cause an extra overhead due to all the challenges mentioned above. These challenges can be taken care of much more efficiently if we have the necessary information on the 3rd party and local dependencies that we are using all on one place. And for that comes our solution of **Package Management**. 

#### Technologies / Frameworks for which our solution is available

Our Current Solutions support only **Linux** Based Operating Systems.

**Frameworks supported:**

1. Maven (Java)
2. Dotnet, Nuget (C#)
3. NPM, Node.js (JavaScript)

#### Features Covered in each Solution

##### 1. Maven Solution

- Listing Details on all Direct and Transitive Packages being used
- Listing Unused Packages
- Performing Checksum (Integrity) Validation for all packages
- Performing Signature Validation for all packages
- Performing Client Side Validation for Version Declarations
- Verification of Source Repositories being used for fetching packages
- Generating Report on Vulnerability Analysis for all packages
- Listing License Information available for all packages
- Reporting: Generates a report showing results of all the above mentioned analysis parameters

##### 2. Dotnet Solution

- Listing all Packages (Direct & Transitive)
- Listing Outdated Packages (Direct & Transitive)
- Listing Deprecated Packages
- Performing Signature Validation for all packages
- Performing Client Side Validation for Version Declarations
- Verification of External Sources being used for fetching packages
- Listing Vulnerable Packages
- Listing License Information available for all packages
- Reporting: Generates a report showing results of all the above mentioned analysis parameters

##### 3. NPM Solution

- Performs check on NPM environment on your system (checks npm and node versions, and file permissions)
- Listing Outdated Packages
- Lists Unused Packages
- Performs Client Side Validation for Version Declarations
- Lists Vulnerable Packages, provides info on vulnerability, and possible fixes
- Lists License Information available for all packages
- Reporting: Generates a report showing results of all the above mentioned analysis parameters


### Tech Stack Used

- Shell Scripts
- PowerShell scripts
- Dotnet core, NuGet
- Maven, Maven Plugins
- Node.js, NPM



## Demo

### 1. Dotnet Utility

#### Installation

##### Add Source

- Add the following source to your *Global* or *Local* **NuGet.config** file

    ```
    <add key="NugetPkgManagement" value="https://pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NugetPkgManagement/nuget/v3/index.json" />
    ```

- Add Credentials to Authenticate Feed

    ```
    <packageSourceCredentials>
        <Nuget_Utility_Feed>
            <add key="Username" value="<your_username_here>" />
            <add key="Password" value="<your_token_here>" />
        </Nuget_Utility_Feed>
    </packageSourceCredentials>
    ```

- Sample **NuGet.config** file
  ```
  <?xml version="1.0" encoding="utf-8"?>
  <configuration>
  <packageSources>
          <add key="NugetPkgManagement" value="https://pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NugetPkgManagement/nuget/v3/index.json" />
  </packageSources>
    <packageSourceCredentials>
        <Nuget_Utility_Feed>
            <add key="Username" value="<your_username_here>" />
            <add key="Password" value="<your_token_here>" />
        </Nuget_Utility_Feed>
    </packageSourceCredentials>
  </configuration>
  ```

##### Install Tool Globally

```
dotnet tool install --global package-management --version 1.0.0
```

> Invoking Global Tool: <br>
> `$ package-management` <br>


##### Install Tool Locally

```
dotnet new tool-manifest
dotnet tool install package-management --version 1.0.0
dotnet tool restore
```

> Invoking Local Tool: <br>
> `$ dotnet tool run package-management` <br>
> `$ dotnet package-management`


#### Usage

- `package-managment <INPUT> --[OPTIONS]`

#### CLI Options

Input/Action | Description | Flags/Options
--- | --- | ---
analyze                | Analyzes all Packages and generates a detailed HTML report  | NA
versioning             | Checks Package Versioning in .csproj files                 | json
signature-verification | Checks All Package Signatures in your local repository     | json
license-info           | Lists License Info for all project packages                | json
vulnerable             | Lists Vulnerable Project Packages                          | json
deprecated             | Lists Deprecated Project Packages                          | json
outdated               | Lists Outdated Project Packages                            | json, include-transitive
check-external-sources | Checks all Sources mentioned in Nuget.Config file          | json
list-packages          | Lists Project Packages                                     | json, include-transitive
help                   | Display more information on a specific command.            | NA
version                | Display version information.                               | NA

#### Usage Examples

```
$ package-management license-info

+------------------------------------------------------------------------------------------------------------------+
|                                                   LICENSE Info                                                   |
+-------------------------------------------+----------------+---------------------------------------+-------------+
|                PackageName                | PackageVersion |              LicenseUrl               | LicenseType |
+-------------------------------------------+----------------+---------------------------------------+-------------+
| Microsoft.Extensions.Configuration        | 3.1.8          | https://licenses.nuget.org/Apache-2.0 | Apache-2.0  |
| Microsoft.Extensions.Configuration.Binder | 3.1.8          | https://licenses.nuget.org/Apache-2.0 | Apache-2.0  |
| NLog                                      | 4.0.0.46       |                                       |             |
| RestSharp                                 | 106.11.5       | https://licenses.nuget.org/Apache-2.0 | Apache-2.0  |
+-------------------------------------------+----------------+---------------------------------------+-------------+
```

```
$ package-management vulnerable

+--------------------------------------------------------------------------------------------------------------------------+
|                                                   Vulnerable Packages                                                    |
+------------------+----------+---------------------------------------------------+----------------------+-----------------+
| requestedVersion | severity |                    AdvisoryUrl                    |     packageName      | resolvedVersion |
+------------------+----------+---------------------------------------------------+----------------------+-----------------+
| 1.2.0            | High     | https://github.com/advisories/GHSA-fvpg-qx3g-7mp7 | Microsoft.ChakraCore | 1.2.0           |
| 106.11.5         | High     | https://github.com/advisories/GHSA-9pq7-rcxv-47vq | RestSharp            | 106.11.5        |
+------------------+----------+---------------------------------------------------+----------------------+-----------------+
```

```
$ package-management vulnerable --json

[
  {
    "severity": "High",
    "AdvisoryUrl": "https://github.com/advisories/GHSA-fvpg-qx3g-7mp7",
    "resolvedVersion": "1.2.0",
    "requestedVersion": "1.2.0",
    "packageName": "Microsoft.ChakraCore"
  },
  {
    "severity": "High",
    "AdvisoryUrl": "https://github.com/advisories/GHSA-9pq7-rcxv-47vq",
    "resolvedVersion": "106.11.5",
    "requestedVersion": "106.11.5",
    "packageName": "RestSharp"
  }
]
```

### 2. NPM Utility

#### Installation

- Create a file name **.npmrc** in your project, in the same directory as **package.json** or edit your system's user **~/.npmrc** file, and add the following registry in it.

    ```
    registry=https://pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NpmPkgManagement/npm/registry/ 
                        
    always-auth=true
    ```

##### Setup Credentials

###### Step 1

Copy the code below to your **.npmrc** file

    ```
    ; begin auth token
    //pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NpmPkgManagement/npm/registry/:username=nagarro-devops
    //pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NpmPkgManagement/npm/registry/:_password=[BASE64_ENCODED_PERSONAL_ACCESS_TOKEN]
    //pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NpmPkgManagement/npm/registry/:email=npm requires email to be set but doesn't use the value
    //pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NpmPkgManagement/npm/:username=nagarro-devops
    //pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NpmPkgManagement/npm/:_password=[BASE64_ENCODED_PERSONAL_ACCESS_TOKEN]
    //pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/NpmPkgManagement/npm/:email=npm requires email to be set but doesn't use the value
    ; end auth token
    ```

###### Step 2

Get an Authentication Token with *Packaging* read scopes.

###### Step 3

Base64 encode the personal access token from Step 2.

One safe and secure method of Base64 encoding a string is to:

1. From a command/shell prompt run: <br>
    ```
    node -e "require('readline') .createInterface({input:process.stdin,output:process.stdout,historySize:0}) .question('PAT> ',p => { b64=Buffer.from(p.trim()).toString('base64');console.log(b64);process.exit(); })"
    ```

2. Paste your personal access token value and press Enter/Return
3. Copy the Base64 encoded value

###### Step 4

Replace *both* [BASE64_ENCODED_PERSONAL_ACCESS_TOKEN] values in your user **.npmrc** file with your personal access token from Step 3.

##### Install Package

```
$ npm install package-management@1.0.1
```


#### Usage

- `$ npx package-management <INPUT> [OPTIONS]`


#### CLI Options

Input/Action | Description | Flags/Options
--- | --- | ---
analyze      |  Full Package Analysis and Report generation                         |  output, silent
env-check    |  Perform and Show NPM Environment Checks                             |  json
outdated     |  List all Outdated Packages being used in your project               |  json
unused       |  List all Unused Packages declared in your project                   |  json
vulnerable   |  List Package Vulnerabilities and possible fixes                     |  json
pkg-licenses |  List all the Packages (direct & transitive) with their licenses     |  json
lsc-details  |  List all the Licensed Packages with their License Details           |  json
versioning   |  Look for Unsafe Version Declarations in your package.json files     |  json
-- help      | Display Usage Help                                                   | NA
--version    | Displays Tool Version                                                | NA 

#### Usage Examples

```
$ package-management outdated

***********************
Outdated Packages
***********************

Package             Current  Wanted  Latest  Location                          Depended by
ansi-regex            3.0.0   3.0.0   6.0.1  module1/node_modules/ansi-regex   module1@0.0.1
bluebird              3.6.0   3.6.0   3.7.2  node_modules/bluebird             test-dir
body-parser          1.19.2  1.20.0  1.20.0  node_modules/body-parser          test-dir
browserify            1.0.0   1.0.0  17.0.0  node_modules/browserify           sub_module3@0.0.1
colors                1.0.3   1.0.3   1.4.0  node_modules/colors               sub_module3@0.0.1
grunt                 1.0.4   1.0.4   1.5.2  node_modules/grunt                test-dir
json-schema           0.3.0   0.3.0   0.4.0  module2/node_modules/json-schema  module2@0.0.1
mime                  2.0.0   2.0.0   3.0.0  node_modules/mime                 test-dir
```

```
$ package-management versioning --json
[
  {
    "packageName": "body-parser",
    "userDeclaration": "^1.18.3",
    "versioning": [
      "^ (Caret Range)"
    ],
    "packageType": "dependencies",
    "module": "test-module"
  },
  {
    "packageName": "ejs",
    "userDeclaration": "2.6.*",
    "versioning": [
      "* (Star Range)"
    ],
    "packageType": "dependencies",
    "module": "test-module"
  },
  {
    "packageName": "express",
    "userDeclaration": "~4.16.x",
    "versioning": [
      "~  (Tilde Range)",
      "x (X Range)"
    ],
    "packageType": "dependencies",
    "module": "test-module"
  }
]
```

### 4. Maven Utility

#### Installation 

- Add server in your **~/.m2/settings.xml** file with the **Authentication Token**

    ```
    <!-- For Authentication -->
    <server>
      <id>MavenPkgManagement</id>
      <username>nagarro-devops</username>
      <password>TOKEN</password>
    </server>
    ```

- Add Following Plugin Repository in your **pom.xml** or **~/.m2/settings.xml**

    ```
    <pluginRepositories>
        <pluginRepository>
            <id>MavenPkgManagement</id>
            <url>https://pkgs.dev.azure.com/nagarro-devops/161339b5-99ec-4e5b-a3ff-744c5fcd62b2/_packaging/MavenPkgManagement/maven/v1</url>
            <releases>
                <enabled>true</enabled>
            </releases>
            <snapshots>
                <enabled>true</enabled>
            </snapshots>
        </pluginRepository>
    </pluginRepositories>
    ```

- Add the following plugin in your build or pluginManagement plugins

    ```
    <plugin>
        <groupId>com.nagarro.devops</groupId>
        <artifactId>package-management</artifactId>
        <version>1.0-SNAPSHOT</version>
    </plugin>
    ```

#### Usage in POM

```
<plugin>
    <groupId>com.nagarro.devops</groupId>
    <artifactId>package-management</artifactId>
    <version>1.0-SNAPSHOT</version>
    <executions>
        <execution>
            <goals>
                <goal>aggregate-source-repo-verify</goal>
                <goal>aggregate-unused</goal>
                <goal>aggregate-versioning</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

#### Usage via CLI

- `mvn com.nagarro.devops:package-management:<goal>`
- `mvn com.nagarro.devops:package-management:<version>:<goal>`

#### CLI Options / Goals

Goals | Description
--- | ---
**analyze** | Performs full Package Analysis and Generates a detailed HTML report for each module.
**unused** | List all Unused Packages
**checksum-validation** | Get Checksum Validation Results for packages in your module
**signature-validation** | Get Package Signature Validation Results for packages in your module
**versioning** | Checks Package Versioning for packages declared in POM
**source-repo-verify** | Verifies source repositories being used in your module
**aggregate-analyze** | Performs Full Package Analysis and Generates a detailed HTML report aggregated for all modules `target/maven-package-management/report.html`
**aggregate-unused** | List all Unused Packages aggregated over all modules
**aggregate-checksum-validation** | Get Checksum Validation Results on all packages (jars and poms) aggregated over all modules
**aggregate-signature-validation** | Get Signature Validation Results on all packages aggregated over all modules
**aggregate-versioning** | Checks Versioning of all your package declarations in POM aggregated over all modules
**aggregate-source-repo-verify** | Verifies all your source repositories used to fetch packages aggregated over all modules

#### Usage Examples

```
$ mvn com.nagarro.devops:package-management:aggregate-versioning

[INFO] User Package Versioning

                                                              User Package Versioning
    versioning         |          groupId           |    userDeclaration     |      dependedBy       |        artiactId         |
---------------------------------------------------------------------------------------------------------------------------------
                Loose  |  org.apache.maven.plugins  |                3.11.0  |  pkg-management-test  |       maven-site-plugin  |
                Loose  |    org.simplify4u.plugins  |                1.16.0  |  pkg-management-test  |  pgpverify-maven-plugin  |
                Loose  |                     junit  |                 3.8.1  |              module1  |                   junit  |
                Loose  |          com.google.guava  |                  18.0  |              module1  |                   guava  |
 SNAPSHOT Pre-release  |        com.nagarro.DevOps  |          1.0-SNAPSHOT  |              module2  |                 module1  |
                Exact  |                     junit  |               [3.8.1]  |              module2  |                   junit  |
```


```
$ mvn com.nagarro.devops:package-management:source-repo-verify

[INFO] --- package-management:1.0-SNAPSHOT:source-repo-verify (default-cli) @ module1 ---
[INFO] Source Repo Verification for Project Module: module1
[INFO] Verifying Source Repositories
[INFO] Source Repositories

                                            Source Repositories
 layout   |  protocol  |  security  |          id           |          url                                                    |
-------------------------------------------------------------------------------------------------------------------------------
 default  |     HTTPS  |    SECURE  |         PRIVATE-REPO  | https://raw.github.com/Sam1414/maven-host-example/mvn-artifact  |
 default  |     HTTPS  |    SECURE  |  CLIENT-PRIVATE-REPO  | https://raw.githubusercontent.com/Sam1414/maven-host-example    |
 default  |      HTTP  |  INSECURE  |         Maven-1-repo  | http://repo1.maven.org/maven/                                   |
 default  |     HTTPS  |    SECURE  |              central  | https://repo.maven.apache.org/maven2                            |

[INFO] --- package-management:1.0-SNAPSHOT:source-repo-verify (default-cli) @ module2 ---
[INFO] Source Repo Verification for Project Module: module2
[INFO] Verifying Source Repositories
[INFO] Source Repositories

                                            Source Repositories
 layout   |  protocol  |  security  |          id           |          url                                                               |
------------------------------------------------------------------------------------------------------------------------------------------
 default  |     HTTPS  |    SECURE  |         PRIVATE-REPO  | https://raw.github.com/Sam1414/maven-host-example/mvn-artifact             |
 default  |     HTTPS  |    SECURE  |  CLIENT-PRIVATE-REPO  | https://raw.githubusercontent.com/Sam1414/maven-host-example/mvn-artifact  |
 default  |     HTTPS  |    SECURE  |              central  | https://repo.maven.apache.org/maven2                                       |

```