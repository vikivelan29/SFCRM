public with sharing class ASF_Case360Controller {
    @AuraEnabled(cacheable=true)
    public static UserAndCaseWrapper fetchUserAndCaseDetails(Id caseId){
        UserAndCaseWrapper wrap = new UserAndCaseWrapper();
        try {
            User uRec = [SELECT Id, ManagerId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            wrap.userRec = uRec;
            String caseQuery = 'Select ';
            Schema.DescribeSObjectResult r = caseId.getSObjectType().getDescribe();
            Map<String, Schema.SObjectField> mapOfFields = r.fields.getMap();
            for(String fieldName : mapOfFields.keySet()) 
            {
                Schema.DescribeFieldResult fieldRes = mapOfFields.get(fieldName).getDescribe();
                caseQuery += fieldRes.getName()+', '; 
            }
            caseQuery = caseQuery.removeEnd(', ');
            caseQuery += ' from Case where Id = :caseId';
            Case cRec = Database.query(caseQuery);
            wrap.caseRec = cRec;
            wrap.isSuccess = true;
            return wrap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Consolidate 2 DMLs into 1
     * Return a meaningful wrapper
     * 
     */
    @AuraEnabled
    public static void updateCaseWithCaseExtn(Case caseRec, SObject caseExtn){
        try {
            update caseExtn;
            update caseRec;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    /**
     * This method is called from asf_Case360 LWC component on "Move to forward stage" 
     * and "Move to backward stage" buttons.
     */
    @AuraEnabled
    public static void moveToRequestedStage(string recordId, string requestedStage, Boolean isForward){
        try {
            Case caseRec = new Case(Id = recordId, Stage__c = requestedStage);
            caseRec.pending_clarification__c = isForward?false:true;
            caseRec.moved_back__c = isForward?false:true;
            caseRec.Is_Manual_Moved__c = isForward?true:false;
            update caseRec;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    @AuraEnabled
    public static String moveToNextStage(string recordId){
        try {
            Case caseRec = new Case(Id = recordId, MoveToNext__c = true);
            update caseRec;
            return [Select Stage__c from Case where Id = :recordId].Stage__c;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }
    
    public class UserAndCaseWrapper{
        @AuraEnabled public User userRec{get;set;}
        @AuraEnabled public Case caseRec{get;set;}
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public String errorMsgIfAny{get;set;}
    }
}