({
    doInit : function(component, event, helper){
        var pageReference = component.get("v.pageReference");
        if(pageReference!==undefined && pageReference!==null && pageReference.state!=null)
        {
            var recordId=pageReference.state.c__recordId; 
            component.set("v.recordId",recordId);
        }
        },

        closeWorkSpaceTab : function(component, event, helper) {
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({tabId: focusedTabId});
            })
            .catch(function(error) {
                console.log(error);
            });
        }
})