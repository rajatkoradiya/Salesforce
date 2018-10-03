# Filter Picklist Values Based on Record Type

-	Retrieving a picklist value based on record type is possible in VF page using standard controller
-	In lightning, Salesforce UI API (https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_resources_picklist_values.htm) supports a functionality to filter a picklist value based on record type based on this idea (https://success.salesforce.com/ideaView?id=08730000000gNpLAAU)

Below is the approach how to leverage Salesforce UI API to retrieve picklist value based on record type:
-	Create connected app
-	Create an Auth Provider
-	Create Named Credentials
-	Create lightning component
-	Create Apex class to call UI API



### 1.	Create connected app:
-	setup > create apps > create new app
-	Provide any URL as a callback URL for now. We will replace it with new URL in later steps when we will create Auth Provider
-	For Oauth scope provide “Full access (full)” & ”Perform requests on your behalf at any time (refresh_token, offline_access)”
 ![connected_app](https://user-images.githubusercontent.com/18682184/46395509-381fab00-c70a-11e8-8579-c276f3595127.PNG)




### 2.	Create an Auth Provider
-	Create Auth Provider from Setup > Security Control > create a new Auth. provider 
-	Set provider type as “Salesforce”
-	Provide consumer key & consumer secret from apps that is created in step 1
-	Set the default scope as a “full refresh_token offline_access”
-	Click save
 ![auth_provider](https://user-images.githubusercontent.com/18682184/46395536-4c63a800-c70a-11e8-82b1-53c4cb15965a.PNG)
 
-	Cope the Callback URL from “Salesforce Configuration” section and paste it to Callback URL in app that you have created in step 1.



### 3.	Create Named Credentials
-	Setup > Named Credentials > Create new named credentials
-	Set the URL as a base URL of your org
-	Set Identity type as a “Named Principal”
-	Set authentication protocol as a “Oauth 2.0”
-	Select Authentication Provider as a Auth. Provider that you created in step 2.
-	Provide the scope as a “full refresh_token offline_access”
-	Select “Start Authentication Flow on Save”
-	Click Save > It will ask for credentials to authenticate, provide that
 ![named_credentials](https://user-images.githubusercontent.com/18682184/46395559-5dacb480-c70a-11e8-81bd-ababad5c92b7.PNG)




### 4.	Create a lightning component
 ```html
<aura:component implements="lightning:availableForFlowScreens,force:appHostable,flexipage:availableForAllPageTypes,forceCommunity:availableForAllPageTypes" 
                access="public" controller="PicklistBasedOnRecordTypeController">
    
    <aura:handler name="init" value="{!this}" action="{!c.doInit}" />
    
    <!-- input attribute  -->
    <aura:attribute name="objectAPIName" type="String" access="public" description="API name of object" />
    <aura:attribute name="fieldAPIName" type="String" access="public" description="API name of field" />
    <aura:attribute name="fieldLabel" type="String" access="public" description="Label of field" />
    <aura:attribute name="recordTypeDeveloperName" type="String" access="public" description="Developer name of Record Type of object" />
    <aura:attribute name="required" type="Boolean" default="false" access="public" description="Picklist is required or not" />
    
    <!-- output attribute  -->
    <aura:attribute name="selectedValue" type="String" access="public" description="Selected picklist value" />
    
    <aura:attribute name="pickListOptions" type="object[]" access="public" description="List of picklist values" />
    
    <lightning:select aura:id="picklist" name="pickListValues" label="{!v.fieldLabel}" required="{!v.required}" value="{!v.selectedValue}">
		<aura:iteration var="option" items="{! v.pickListOptions }">
            <option value="{!option.value}">{!option.label}</option>
        </aura:iteration>
    </lightning:select>
    
</aura:component>
```


### 5.	Create an apex controller
 ```apex
 /**
 * @Author		:		Rajat Koradiya
 * @Date		:		20-Sept-2018
 * @Desc		:		Controller for picklist based on record type lightning component
 * */
public with sharing class PicklistBasedOnRecordTypeController {
	
    @AuraEnabled 
    public static String getPicklistValueBasedonRecordType(String objectAPIName, String fieldAPIName, String recordTypeDeveloperName){
        
        list<PicklistValue> picklistValues = new list<PicklistValue>();
        
        //get record type Id
        list<RecordType> recordTypes = [Select Id, Name From RecordType  Where SobjectType = :objectAPIName and DeveloperName = :recordTypeDeveloperName limit 1];
        Id recordTypeId = (!recordTypes.isEmpty()) ? recordTypes.get(0).Id : null;
        
        if(recordTypeId != null){
            
            String method = 'GET';
            String endpoint = String.format('/services/data/v43.0/ui-api/object-info/{0}/picklist-values/{1}/{2}', new String[]{ objectAPIName, recordTypeId, fieldAPIName });
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:UI_API_Named_Credentials'+endPoint);
            request.setMethod(method);
            
            HTTPResponse response = (new Http()).send(request);
            
            if(response.getStatusCode() == 200){
                
                Map<String,Object> root = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                if(root.containsKey('values')){ 
                    List<Object> picklistVals = (List<Object>)root.get('values');
                    for(Object picklistVal : picklistVals){
                        Map<String,Object> picklistValMap = (Map<String,Object>) picklistVal;
                        picklistValue pickVal = new picklistValue();
                        pickVal.value = (String) picklistValMap.get('value');
                        pickVal.label = (String) picklistValMap.get('label');
                        picklistValues.add(pickVal);
                    }
                }
                
            }
            
        }
        
        return JSON.serialize(picklistValues);
    }
    
    public class PicklistValue{
        public String value {get;set;}
        public String label {get;set;}
    }
}
 ```

