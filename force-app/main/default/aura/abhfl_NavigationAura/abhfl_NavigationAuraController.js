({
    doInit : function(component, event, helper) {
        //setTimeout(() => {
        /**const params = event.getParam('state');
        console.log('params>>>>',params);
        if (params) {
            console.log('Params>>',params);
            component.set('v.accountId', params.c__accountId);
        }**/
        var myPageRef = component.get("v.pageReference");
        var recordId = myPageRef.state.c__accountId;
        component.set("v.accountId", recordId);
        console.log('Aura cmp JS > recordId>>>',component.get("v.accountId"));
    //}, 2000);
    const tabName='Survey Response';
    /*const workspaceAPI = component.find("workspace");
        if (workspaceAPI) {
            workspaceAPI.getFocusedTabInfo().then(function (response) {
                const tabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: tabId,
                    label: tabName
                });
                workspaceAPI.setTabIcon({
                    tabId: tabId,
                    icon: 'standard:metrics',
                    iconAlt: tabName
                });
            })
            .catch(function (error) {
                console.error('Error setting tab label', error);
            });
        }
        */
    }

})