public without sharing class ASF_CaseApprovalTriggerHelper {
    
    /*
* 1. pending : Move next Stage
*/ 
    
    public void handleSubmitForApproval (List<ASF_Case_Approv__c> newStageList){ 
        List<ASF_Case_Approv__c> submitForApprovalList = new List<ASF_Case_Approv__c>();
        List<Approval.ProcessSubmitRequest> requestLIst = new List<Approval.ProcessSubmitRequest>();
        //Virendra : 6th March 2023 : Added map of CaseApprovalId to Case Id.
        Map<Id,Id> mCaseApprovToCaseId = new Map<Id,Id>();
        
        for(ASF_Case_Approv__c v:newStageList){
            //if (v.TypeOfApproval__c == 'Auto'){
            submitForApprovalList.add(v);
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();          
            req.setComments(v.Requestor_Comments__c);        
            req.setObjectId(v.id);
            requestLIst.add(req);
            
            if(!mCaseApprovToCaseId.containsKey(v.Id)){
                mCaseApprovToCaseId.put(v.Id,v.SR__c);
            }
            
            
            // }
        }
        if(submitForApprovalList.size() > 0){
            List<Approval.ProcessResult> resultList = new List<Approval.ProcessResult>();
            try{
                resultList = Approval.process(requestLIst);   
            }
            catch(DmlException dEx){
                for(integer i=0;i<dEx.getNumDml();i++){
                    System.debug(dEx.getDmlType (i));
                    if(dEx.getDmlType(i).toString() == 'STRING_TOO_LONG'){
                        for(ASF_Case_Approv__c trg : submitForApprovalList){
                            trg.addError('String too large to save.');
                        }
                    }
                    
                }
            }
            //Virendra : 6th March 2023 : Added code below to update the Is_Approval_Pending__c to True on Case record.
            List<Case> cList = new List<Case>();
            
            for(Approval.ProcessResult res : resultList){
                if(res.isSuccess()){
                    if(res.getEntityId() != null){
                        if(mCaseApprovToCaseId.containsKey(res.getEntityId())){
                            Id cId = mCaseApprovToCaseId.get(res.getEntityId());
                            Case c = new Case(Id = cId);
                            c.Is_Approval_Pending__c = true;
                            if(!cList.contains(c)){
                                cList.add(c);
                            }
                            
                        }
                    }
                }
            }
            if(cList.size()>0){
                ASF_TriggerSkipperUtility.markTriggerRun('Case');
                Database.SaveResult[] saveResults = Database.update(cList,false);                
            }
            
        }
    }
    
    public void prepopupateUnpassedUserNames (List<ASF_Case_Approv__c> newStageList){ 
        
        for(ASF_Case_Approv__c  c: newStageList){
            if(c.Approval_Type__c != 'Sequential'){
                if(String.isBlank(c.Approver_02__c)){
                    c.Approver_02__c = c.Approver_01__c;
                }
                if(String.isBlank(c.Approver_03__c)){
                    c.Approver_03__c = c.Approver_01__c;
                }
                if(String.isBlank(c.Approver_04__c)){
                    c.Approver_04__c = c.Approver_01__c;
                }
                if(String.isBlank(c.Approver_05__c)){
                    c.Approver_05__c = c.Approver_01__c;
                }
            }
        } 
    }
    
    public void handleApprovalActions(Map<Id,ASF_Case_Approv__c> oldApproveMap,Map<Id,ASF_Case_Approv__c> newApproveMap){ 
        checkIfApprovalProcessCommentPresent(oldApproveMap,newApproveMap);//Virendra - 8 Feb 2023.
        Set<Id> caseIds = new Set<Id>();
        Set<Id> rejectedCaseIds = new Set<Id>();
        List<Case> rejectedCaseToUpdate = new List<Case>();
        for(ASF_Case_Approv__c  c: newApproveMap.values()){
            ASF_case_Approv__c newRecord = c;
            ASF_case_Approv__c oldRecord = oldApproveMap.get(c.id);
            if(oldrecord.Approval_Status__c != newRecord.Approval_Status__c ){
                /* Aware of for loop Update. This is by design. 
*/ 
                
                if (c.Approval_Status__c == 'Approved'){
                    if(newRecord.Is_Recategorization_Request__c){
                        caseIds.add(newRecord.SR__c);
                    }else{
                        if(String.isNotBlank(newRecord.Parent_Record_Id_For_Update__c)){
                            Id recId = Id.valueOf(newRecord.Parent_Record_Id_For_Update__c);
                            Schema.SObjectType token = recId.getSObjectType();
                            Sobject s = token.newSobject();
                            s.put('Id',newRecord.Parent_Record_Id_For_Update__c );
                            //now decyper Fields and Make it happen
                            List<String> FieldvaluesList = c.SuccessFieldsUpdate__c.split(',');
                            for(String som : FieldvaluesList){
                                String fieldAPIName = som.split('=')[0];
                                String fieldValue = som.split('=')[1];
                                s.put(fieldAPIName,fieldValue);
                            }
                            ASF_TriggerSkipperUtility.markTriggerRun('Case');
                            update s;
                        } 
                        
                        Case cas = new Case(Id =newRecord.SR__c);
                        
                        ASF_TriggerSkipperUtility.markTriggerRun('Case');
                        update cas;
                	}
                    
                }
                else if(c.Approval_Status__c == 'Rejected'){
                    if(String.isNotBlank(newRecord.Parent_Record_Id_For_Update__c)){
                        Id recId = Id.valueOf(newRecord.Parent_Record_Id_For_Update__c);
                        Schema.SObjectType token = recId.getSObjectType();
                        Sobject s = token.newSobject();
                        s.put('Id',newRecord.Parent_Record_Id_For_Update__c );
                        //now decyper Fields and Make it happen
                        List<String> FieldvaluesList = c.RejectedFieldUpdates__c.split(',');
                        for(String som : FieldvaluesList){
                            String fieldAPIName = som.split('=')[0];
                            String fieldValue = som.split('=')[1];
                            s.put(fieldAPIName,fieldValue);
                        }
                        //object name need not be case. it should be ideally be Case Extension1 or 2. But safer side.
                        ASF_TriggerSkipperUtility.markTriggerRun('Case');
                        update s;
                    }
                    /* bel0w record is to update case. */
                    Case cas = new Case(Id =newRecord.SR__c);
                    //Virendra : Commenting below code : 8th March 2023: On Rejetion, no case change is happening, hence no need to change Is_Approval_Stage__c.
                    //cas.Is_Approval_Stage__c = false;
                    ASF_TriggerSkipperUtility.markTriggerRun('Case');
                    update cas;   
                }
                if(c.Is_Recategorization_Request__c && (c.Approval_Status__c == 'Rejected' || c.Approval_Status__c == 'Recalled' || c.Approval_Status__c == 'Cancelled')){
                    rejectedCaseIds.add(newRecord.SR__c);
                }
            }
        }  
        if(!caseIds.isEmpty()){
            Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, CCC_External_Id__c, Requested_Recat_Json__c, Type_Text__c, Sub_Type_Text__c from Case where ID IN: caseIds]);
            ASF_ApprovalRecatController.updateCCCIdBulk(caseMap);
        } 
        else if(!rejectedCaseIds.isEmpty()){
            Map<Id, Case> caseMap = new Map<Id, Case>();
            for(Case caseRec : [SELECT Id, Requested_CCC_Details__c, Requested_Recat_Json__c from Case where ID IN: rejectedCaseIds]){
                caseRec.Requested_CCC_Details__c = '';
                caseRec.Requested_Recat_Json__c = '';
                rejectedCaseToUpdate.add(caseRec);
            }
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            update rejectedCaseToUpdate;
        }
    }
    
    
    public void moveToSuccessStage(Map<Id,ASF_Case_Approv__c> newApproveMap,Map<Id,ASF_Case_Approv__c> oldApproveMap){  
        list<case> casesToUpdate = new list<Case>();
        Set<id> IsApprovalPendingToUpdate = checkIfLatestRecordIsApproved(newApproveMap,oldApproveMap);
        for(ASF_Case_Approv__c  c: newApproveMap.values()){
            if(newApproveMap.get(c.Id).Approval_Status__c != oldApproveMap.get(c.Id).Approval_Status__c && newApproveMap.get(c.Id).Approval_Status__c=='Approved'){
                case caseRecord = new Case();
                caseRecord.Id = c.SR__c;

                if(c.SuccessStageMovement__c != null){
                    caseRecord.Stage__c = c.SuccessStageMovement__c;
                }
                //Virendra : 6 March 2023 : Added to update Is Approval Pending flag to False, if approval is Approved, Rejected, or Recalled.
                if(IsApprovalPendingToUpdate.contains(c.SR__c)){
                    caseRecord.Is_Approval_Pending__c = false;
                }
                
                casesToUpdate.add(caseRecord);
            }
            if(newApproveMap.get(c.Id).Approval_Status__c != oldApproveMap.get(c.Id).Approval_Status__c && newApproveMap.get(c.Id).Approval_Status__c=='Rejected'){
                case caseRecord = new Case();
                caseRecord.Id = c.SR__c;

                if(c.Case_RejectedStageMovement__c != null){
                    caseRecord.Stage__c = c.Case_RejectedStageMovement__c;
                }

                if(IsApprovalPendingToUpdate.contains(c.SR__c)){
                    caseRecord.Is_Approval_Pending__c = false;
                }
                
                casesToUpdate.add(caseRecord);
            }
            if(newApproveMap.get(c.Id).Approval_Status__c != oldApproveMap.get(c.Id).Approval_Status__c && newApproveMap.get(c.Id).Approval_Status__c=='Recalled'){
                case caseRecord = new Case();
                caseRecord.Id = c.SR__c;
                if(IsApprovalPendingToUpdate.contains(c.SR__c)){
                    caseRecord.Is_Approval_Pending__c = false;
                    casesToUpdate.add(caseRecord);
                }
                
                
            }
        } 
        
        if(casesToUpdate.size() > 0){
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            update casesToUpdate;
        }
    } 
    
    
    
    private void checkIfApprovalProcessCommentPresent(Map<Id,ASF_Case_Approv__c> oldApproveMap,Map<Id,ASF_Case_Approv__c> newApproveMap){
        Set<Id> caseApprId = new Set<Id>();
        for(ASF_Case_Approv__c ca : newApproveMap.values()){
            System.debug(ca.Approval_Status__c + ' - '+oldApproveMap.get(ca.Id).Approval_Status__c);
            if(ca.Approval_Status__c == 'Rejected' && (ca.Approval_Status__c != oldApproveMap.get(ca.Id).Approval_Status__c)){
                caseApprId.add(ca.Id);
            }
        }
        
        for(ProcessInstance pi : [SELECT TargetObjectId,(SELECT ID,StepStatus, Comments FROM Steps Order By CreatedDate DESC LIMIT 1) FROM ProcessInstance
                                  WHERE TargetObjectId =: caseApprId ORDER BY CreatedDate DESC])
        {
            if((pi.Steps[0].comments == null || pi.Steps[0].Comments.trim().length()==0)){
                //newApproveMap.get(pi.TargetObjectId).addError('Operation Cancelled : Please provide a rejection reason !');
            }
        }
    }
    private static Set<id> checkIfLatestRecordIsApproved(Map<Id,ASF_Case_Approv__c> newApproveMap,Map<Id,ASF_Case_Approv__c> oldApproveMap){
        Map<Id,ASF_Case_Approv__c> mLatestRecord = new Map<Id,ASF_Case_Approv__c>();
        Set<Id> caseIsApprovalPendingFlagTobeUpdated = new Set<Id>();
        
        List<String> validStatus = new List<String>{'Approved','Rejected','Recalled'};
            
            for(ASF_Case_Approv__c ca : [SELECT ID,SR__c,Approval_Status__c FROM ASF_Case_Approv__c WHERE Id =: newApproveMap.keySet() ORDER BY CreatedDate DESC]){
                if(!mLatestRecord.containsKey(ca.Id)){
                    mLatestRecord.put(ca.Id,ca);
                }
            }
        for(ASF_Case_Approv__c ca : mLatestRecord.values()){
            if(ca.Approval_Status__c != oldApproveMap.get(ca.Id).Approval_Status__c){
                if(validStatus.contains(ca.Approval_Status__c)){
                    if(!caseIsApprovalPendingFlagTobeUpdated.contains(ca.SR__c)){
                        caseIsApprovalPendingFlagTobeUpdated.add(ca.SR__c);
                    }
                }
            }
        }
        return caseIsApprovalPendingFlagTobeUpdated;
    }
    
}