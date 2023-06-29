There are two ways to deploy the managed package from one org to another.

1. Vs code:
Steps:
- Reterieve installed packages
<types>
    <members>name_space_of_managed_package</members>
    <name>InstalledPackage</name>
</types>

- changed the xml meta data file as per your configuration.
ex:
  <?xml version="1.0" encoding="UTF-8"?>
  <InstalledPackage xmlns="http://soap.sforce.com/2006/04/metadata">
  <versionNumber>1.0</versionNumber>
  <password>optional_password</password>
  <securityType>AdminsOnly</securityType>
  <activateRSS>true</activateRSS>
  </InstalledPackage>

- Deploy to another org using package.xml


2. Using package id
- Retrieve the list of managed package using: sfdx force:package:installed:list
- Go to this url:/packaging/installPackage.apexp?p0=<id_of_the_managed_package>
  Note: here the id used in url will come from previous step.
