({
    getPicklistValuesBasednRecordType : function(component) {
        
        var objectAPIName = component.get("v.objectAPIName");
        var fieldAPIName = component.get("v.fieldAPIName");
        var recordTypeDeveloperName = component.get("v.recordTypeDeveloperName");
        
        var action = component.get("c.getPicklistValueBasedonRecordType");
        
        action.setParams({
            objectAPIName : objectAPIName,
            fieldAPIName : fieldAPIName,
            recordTypeDeveloperName : recordTypeDeveloperName
        });
        
        action.setCallback(this, function(response){
            this.handleResponse(response, component);
        });
        
        $A.enqueueAction(action);
        
	},
    
    handleResponse : function(response, component){
        if (response.getState() === "SUCCESS") {
            if (!$A.util.isEmpty(response.getReturnValue())) {
                var picklistOptions = [];
                var noneValue = {};
                noneValue["value"] = "";
                noneValue["label"] = "--None--";
                picklistOptions.push(noneValue);
                var returnedValues = JSON.parse(response.getReturnValue());
                if (!$A.util.isEmpty(returnedValues)) {
                    returnedValues.forEach(function(returnedValue){
                        var picklistValue = {};
                        picklistValue["value"] = returnedValue.value;
                        picklistValue["label"] = returnedValue.label;
                        picklistOptions.push(picklistValue);
                    });
                    component.set("v.pickListOptions", picklistOptions);
                }
            }else{
                console.log("Couldn't find an picklist values.");
            }
        } else if (response.getState() === "ERROR") {
            var errors = res.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    console.log(errors[0].message);
                }
            }
        } else{
            console.log("Unknow error!");
        }
    },
})