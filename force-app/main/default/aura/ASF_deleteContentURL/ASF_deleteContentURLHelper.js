({
	closeTab: function(component, reqFrom) {
       var contentDocId = component.get("v.contentDocId");
       var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo().then(function(response) {
            response.forEach(function(tab) {
                if(tab.focused){
                    if(tab.recordId == contentDocId){
                        workspaceAPI.closeTab({tabId: tab.tabId});
                    }else{
                        tab.subtabs.forEach(function(subtab) {
                            if(subtab.focused){
                                workspaceAPI.closeTab({tabId: subtab.tabId});
                            } else if(subtab.recordId === contentDocId){
                                workspaceAPI.closeTab({tabId: subtab.tabId});
                            }
                        });
                    }  
                }
            });
            if(reqFrom === 'delete'){
                $A.get('e.force:refreshView').fire();
            }
        }).catch(function(error) {
            console.log('error-'+error);
        });
    },
    fetchContentDocId: function(component, event, reqFrom) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.fetchContentDoc");
        action.setParams({ contentVersionId: recordId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.contentDocId",response.getReturnValue());
                if(reqFrom === 'back'){
                    this.closeTab(component, 'back');
                }
                
            } else if (state === "ERROR") {
                // Display error message
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    var errorMessage = errors[0].message;
                    component.set("v.errorMessage", errorMessage);
                }
            }
        });
        $A.enqueueAction(action);
    }
})