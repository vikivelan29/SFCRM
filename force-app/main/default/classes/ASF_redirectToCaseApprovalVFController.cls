public class ASF_redirectToCaseApprovalVFController {
    public PageReference init() 
    {
        // other code 
        PageReference caPage;
        id recordId = ApexPages.currentPage().getParameters().get('Id');
        String targetRecordId = '';
        if(recordId.getsObjectType() == ProcessInstanceWorkitem.sObjectType){
            List<ProcessInstanceWorkitem> piwis = [SELECT ID ,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE Id=:recordId];
            if(piwis.size()>0){
                targetRecordId = piwis[0].ProcessInstance.TargetObjectId;
            }
        } else {
            List<ProcessInstanceStep> piwis = [SELECT ID ,ProcessInstance.TargetObjectId FROM ProcessInstanceStep WHERE Id=:recordId];
            if(piwis.size()>0){
                targetRecordId = piwis[0].ProcessInstance.TargetObjectId;
            }
        }
        

        system.debug('targetRecordId'+targetRecordId);
        if(String.isNotBlank(targetRecordId)){
            if(Id.valueOf(targetRecordId).getSobjectType() == ASF_Case_Approv__c.sObjectType){
                ASF_Case_Approv__c ca = [SELECT ID FROM ASF_Case_Approv__c WHERE Id=:targetRecordId];
                caPage = new ApexPages.StandardController(ca).view();
                caPage.setRedirect(true);
            }
            else{
                caPage = null;
            }
        }
        else{
            caPage = null;
        }
        
        
        
        return caPage;
    }
    
    
}