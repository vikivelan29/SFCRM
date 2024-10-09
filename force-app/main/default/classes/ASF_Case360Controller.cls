/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-09-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('PMD.ClassNamingConventions,PMD.FormalParameterNamingConventions, PMD.ApexSOQLInjection')
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
                caseQuery += String.escapeSingleQuotes(fieldRes.getName()+', '); 
            }
            caseQuery = caseQuery.removeEnd(', ');
            caseQuery += String.escapeSingleQuotes(' from Case where Id = :caseId');
            Case cRec = Database.query(caseQuery);
            wrap.caseRec = cRec;


            String extnObjName = ASF_GetCaseRelatedDetails.getCaseRelatedObjName(cRec.CCC_External_Id__c);
            if(extnObjName != null && cRec.get(extnObjName) != null){
                Id extnId = (Id)cRec.get(extnObjName);
                String caseExtnQuery = 'Select ';
                Schema.DescribeSObjectResult rExtn = extnId.getSObjectType().getDescribe();
                Map<String, Schema.SObjectField> mapOfFieldsExtn = rExtn.fields.getMap();
                for(String fieldName : mapOfFieldsExtn.keySet()) 
                {
                    Schema.DescribeFieldResult fieldRes = mapOfFieldsExtn.get(fieldName).getDescribe();
                    caseExtnQuery += String.escapeSingleQuotes(fieldRes.getName()+', '); 
                }
                caseExtnQuery = caseExtnQuery.removeEnd(', ');
                caseExtnQuery += String.escapeSingleQuotes(' from '+extnObjName+' where Id = :extnId');
                wrap.caseExtnRec = Database.query(caseExtnQuery);
            }
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
    public static void updateCaseWithCaseExtn(SObject caseRec, SObject caseExtn){
        try {
                system.debug('casecaseRec '+caseRec);
                system.debug('casecaseExtn '+caseExtn);
            List<SObject> recordsToUpdate = new List<SObject>();
            if(caseExtn != null){
                recordsToUpdate.add(caseExtn);
            }
            recordsToUpdate.add(caseRec);
            update recordsToUpdate;
        } catch(DmlException dmlE){
            AuraHandledException ex = new AuraHandledException(dmlE.getDMLMessage(0));
            ex.setMessage(dmlE.getDMLMessage(0));
            throw ex;
        }catch (Exception e) {
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
        @AuraEnabled public SObject caseExtnRec{get;set;}
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public String errorMsgIfAny{get;set;}
    }
}