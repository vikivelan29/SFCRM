({
    doInit: function(component, event, helper) {  
        
        var myPageRef = component.get("v.pageReference");
        var recordId = myPageRef.state.c__recordId;
        component.set("v.recordId", recordId);
        console.log('inside do init-'+JSON.stringify(component.get("v.pageReference")));  
    },
    deleteFile: function(component, event, helper) {
        var comments = component.find("comment");
        if(!comments.checkValidity()) {
            comments.showHelpMessageIfInvalid();
        }else{
            var recordId = component.get("v.recordId");
            var action = component.get("c.deleteFileById");
            action.setParams({ fileId: recordId, comment: component.get("v.comments") });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log("File deleted successfully");
                    if(response.getReturnValue() != 'Error'){
                        component.set("v.contentDocId",response.getReturnValue());
                    }
                    helper.closeTab(component,'delete');
                    
                } else if (state === "ERROR") {
                    // Display error message
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        var errorMessage = errors[0].message;
                        var validationMessage = '';
                        var startIndex = errorMessage.indexOf("FIELD_CUSTOM_VALIDATION_EXCEPTION");
                        errorMessage = errorMessage.split("FIELD_CUSTOM_VALIDATION_EXCEPTION,")[1];
                        errorMessage = errorMessage.split(":")[0];
                        component.set("v.errorMessage", errorMessage);
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },
    goback : function(component, event, helper) {
        helper.fetchContentDocId(component, event, 'back');
	}
})