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