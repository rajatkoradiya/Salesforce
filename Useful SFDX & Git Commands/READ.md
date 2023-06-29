- Validate the deployment
  - with test: sfdx force:source:deploy -c -w 200 -x ./manifest/package.xml -l RunLocalTests -u <user_alias>
  - without test: sfdx force:source:deploy -c -w 200 -x ./manifest/package.xml -l NoTestRun -u <user_alias>
  Note: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_force_source.htm#cli_reference_force_source_deploy

- Get the installed packages with package id in vs code: sfdx force:package:installed:list
