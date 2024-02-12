public with sharing class ASF_CasemergeController {
    public ASF_CasemergeController() {

    }
    @AuraEnabled
    public static list<Case> fetchCases(string recordId,string caseSubject, string suppliedEmail){
        try {
            list<Case> cases =new list<Case>();
            map<Id,Case> caseIdMap =new map<Id,Case>([Select Id,CaseNumber,Subject,Description,Client_Code__c ,Origin,Contact.Name,CreatedDate,Customer_name_formula__c,Stage__c,Status,Type_Text__c,Sub_Type_Text__c,SuppliedEmail,Owner.Name From Case Where  Subject =:caseSubject  AND IsClosed =false AND  RecordType.Name ='Interaction'  AND SuppliedEmail =:suppliedEmail]);
            caseIdMap.remove(recordId);
            cases =caseIdMap.values();
            return cases;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string mergeCases(list<Case> selectedRec,String masterRecId, List<Id> selectedCaseIdList){
        try {
            updateCaseParentId(selectedCaseIdList, masterRecId);
            Case masterCase =[select id from case where id=:masterRecId];
            
            list<Id> selectCaseIds =new list<Id>();
            list<Case> casesToUpdate =[Select Id,Status,ParentId From Case Where Id IN:selectedRec FOR UPDATE];
                        
            for(case caseRec :casesToUpdate){
                caseRec.Status ='Merged';
            }
            Database.MergeResult[] results  = Database.merge(masterCase, casesToUpdate, false);
            for(Database.MergeResult result : results){
                if(!result.isSuccess()){
                    for(Database.Error err : result.getErrors()){
                        System.debug('ERROR--'+err.getMessage());
                        throw new DMLException(err.getMessage());
                    }
                }
            } 
            //update casesToUpdate; 
            return 'Success'; 
        } 
        catch (Exception e) {
            //Nebula.LogMessage msg = new Nebula.LogMessage('Failed to Merge Cases', System.today());
            //Nebula.Logger.error(msg, masterRecId, e);
            //Nebula.Logger.saveLog();
            throw e;
        }
    }
    @AuraEnabled
    public static void updateCaseParentId(List<Id> selectedCaseIdList, String newParentId) {
        List<Case> caseListToUpdate = new List<Case>();
        for(Case caseRec : [SELECT Id FROM Case WHERE Id IN: selectedCaseIdList]){
            caseRec.ParentId = newParentId;
            caseListToUpdate.add(caseRec);
        }
        update caseListToUpdate;
    }
}