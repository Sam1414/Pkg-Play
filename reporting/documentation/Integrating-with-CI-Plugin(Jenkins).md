# Dependency Analysis Integration with CI Workflow Plugin (Jenkins)

## Enabling CSS and JavaScript in Jenkins

### Enabling Temporarily

Figured out the issue. Sharing it here for other users.

CSS is stripped out because of the Content Security Policy in Jenkins. (https://wiki.jenkins-ci.org/display/JENKINS/Configuring+Content+Security+Policy)

The default rule is set to:

`sandbox; default-src 'none'; img-src 'self'; style-src 'self';`

This rule set results in the following:
- No JavaScript allowed at all
- No plugins (object/embed) allowed
- No inline CSS, or CSS from other sites allowed
- No images from other sites allowed
- No frames allowed
- No web fonts allowed
- No XHR/AJAX allowed, etc.
- To relax this rule, go to

**Manage Jenkins->
Manage Nodes->
Click settings(gear icon)->**

Click Script console on left and type in the following command:

```
System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "")
```

and Press Run. 

If you see the output as 'Result:' below "Result" header then the protection disabled. 

Re-Run your build and you can see that the new HTML files archived will have the CSS enabled.

---

### Enabling Permanently

#### On RedHat/CentOS

Edit `/etc/sysconfig/jenkins` by changing the entry...

```
JENKINS_JAVA_OPTIONS="..."
```

To

```
JENKINS_JAVA_OPTIONS="... -Dhudson.model.DirectoryBrowserSupport.CSP="
```

#### On Debian/Ubuntu

Edit `/etc/default/jenkins` by changing the entry...

```
JAVA_ARGS="..."
```

To

```
JAVA_ARGS="... -Dhudson.model.DirectoryBrowserSupport.CSP="
```

#### On Windows

On Windows there may be a file called `jenkins.xml` in the Jenkins installation where this can be added to the arguments tag:

```
<arguments>
    -Xrs -Xmx256m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle
    "-Dhudson.model.DirectoryBrowserSupport.CSP=" 
    -jar "%BASE%\jenkins.war" --httpPort=8080
</arguments>
```

<br>

**Restart Jenkins for changes to take effect**

<br>

### Verify current Content Security Policy

To verify current Content Security Policy go to `Manage Jenkins -> Script Console` and type into console the following command:

```
println(System.getProperty("hudson.model.DirectoryBrowserSupport.CSP"))
```

For More Content Security Options visit: [Configuring Content Security Policy | Jenkins](https://www.jenkins.io/doc/book/security/configuring-content-security-policy/)

