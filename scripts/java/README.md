# Java Scripts

Java has been "scriptivized" via [JBang](https://www.jbang.dev/documentation/guide/latest/index.html).

## Requirements

Pre-requisites:

- Java
- JBang

I recommend using [asdf](https://asdf-vm.com/guide/getting-started.html) to manage your Java versions. You can install Java with asdf via:

```bash
# Add Java plugin and install Java
asdf plugin-add java https://github.com/halcyon/asdf-java.git
asdf install java adoptopenjdk-jre-21.0.2+13.0.LTS
asdf global java adoptopenjdk-jre-21.0.2+13.0.LTS
# Add Jbang
asdf plugin-add jbang
asdf install jbang latest
asdf global jbang latest
```

## Examples

### xxtemplate-java.java

This script will print the arugments provided to it.
