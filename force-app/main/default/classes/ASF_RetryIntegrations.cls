/**
* @description       : This class is used for retrying the PROCESS type and EBOT related Integrations.
* @author            : virendra
* @group             : 
* @last modified on  : 05-14-2024
* @last modified by  : rsinghnagar@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   05-14-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public without sharing class ASF_RetryIntegrations {
    public static final integer iRetryInterval = Integer.ValueOf(System.Label.ASF_RetryInterval);
    public static final integer iRetryNumbers = Integer.ValueOf(System.Label.ASF_RetryNumbers);
    /**
* @description 
* @author rsinghnagar@salesforce.com | 05-13-2024 
* @param caseIntegrationRecords 
**/
    @InvocableMethod(label='Retry Integrations' description='This Apex is used to invoke the Failed or Pending Integrations')
    public static void retryIntegration(List<ASF_Case_Integration__c> caseIntegrationRecords) {
        Set<Id> caseIds = new Set<Id>();
        Set<String> intExtIds = new Set<String>();
        List<ASF_Integration__c> intergraionMaster = new List<ASF_Integration__c>();
        List<Case> casesToUpdate = new List<Case>();
        List<Case> caseRecords = new List<Case>();
        Map<Id,Case> mCaseRecords = new Map<Id,Case>();
        Map<String, ASF_Integration__c> mIntegrationRecords = new Map<String,ASF_Integration__c>();
        List<sObject> nonASFIntegrationPlaformEvents = new List<sObject>();
        List<ASF_Case_Integration__c> caseInteToUpdate = new List<ASF_Case_Integration__c>();
        
        List<ASF_Retry_Matrix__mdt> mdtRetryMatrixs = ASF_Retry_Matrix__mdt.getAll().values();
        Map<Integer,String> mHashedMdtVsPlatformEvtName = new Map<Integer,String>();
        
        for(ASF_Retry_Matrix__mdt mdt : mdtRetryMatrixs){
            String tempMdt = mdt.Business_Unit__c +'_'+ mdt.Type__c ;
            integer iHashKey = tempMdt.hashcode();
            mHashedMdtVsPlatformEvtName.put(iHashKey,mdt.Platform_Event_API_Name__c );
        }
        
        
        
        for(ASF_Case_Integration__c cInt : caseIntegrationRecords){
            if(ASF_Constants.RETRY_ENABLEDSTATUESES.contains(cInt.Status__c)){
                caseIds.add(cInt.Case__c);
                intExtIds.add(cInt.Integration_Ext_Id__c);
            }
            
        } 
        if(caseIds.size() < 1){
            return;
        }
        caseRecords = ASF_CaseQueryHandler.getCaseRecordToRetryIntegrations(caseIds);
        mCaseRecords = new Map<Id,Case>(caseRecords);
        
        DateTime startOfLast60Mins = System.now().addMinutes(-60);
        DateTime currentTime = System.now();
        Map<Integer,Integer> mhashCaseCaseIntegrationVsAttempt = new Map<Integer,Integer>();
        
        
        List<ASF_Case_Integration__c> oldCaseInetegrationRecords = new List<ASF_Case_Integration__c> ();
        
        if(ASF_Case_Integration__c.SObjectType.getDescribe().isAccessible()){
            oldCaseInetegrationRecords = [SELECT ID,Case__c,Integration_Ext_Id__c FROM ASF_Case_Integration__c WHERE Case__c =:caseIds AND Case__r.IsClosed = False AND (CreatedDate > :startOfLast60Mins AND CreatedDate <= :currentTime)];
        }
        
        for(ASF_Case_Integration__c oldInt : oldCaseInetegrationRecords){
            
            String tempKey = oldInt.Case__c+'_'+oldInt.Integration_Ext_Id__c;
            integer ihashKey = tempKey.hashCode();
            
            
            if(!mhashCaseCaseIntegrationVsAttempt.containsKey(ihashKey)){
                mhashCaseCaseIntegrationVsAttempt.put(ihashKey,0);
            }
            integer iTempCounter = mhashCaseCaseIntegrationVsAttempt.get(ihashKey);
            iTempCounter++;
            mhashCaseCaseIntegrationVsAttempt.put(ihashKey,iTempCounter);
        }
        
        
        if(intExtIds.size()>0){
            intergraionMaster = ASF_CaseQueryHandler.getASFIntegrationRecordsForRetry(intExtIds);
        }
        
        
        for(ASF_Integration__c integ : intergraionMaster){
            if(integ.External_Id__c != null){
                if(!mIntegrationRecords.containsKey(integ.External_Id__c)){
                    mIntegrationRecords.put(integ.External_Id__c,integ);
                }
            }
        }
        Map<Integer,Integer> mCaseCaseIntegrationIdVsAttempt = new Map<Integer,Integer>();
        Set<Id> caseIdForProcess = new Set<Id>();
        Set<String> caseIntProcess = new Set<String>();
        
        for(ASF_Case_Integration__c cInt : caseIntegrationRecords){
            if(cInt.Case__c != null){
                if(mCaseRecords.containsKey(cInt.Case__c)){
                    Case cRec = mCaseRecords.get(cInt.Case__c);
                    if(cRec.IsClosed){
                        continue;
                    }
                    String tempUniqueKeyForMdt = cRec.Business_Unit__c+'_'+cInt.Type__c;
                    integer iHashUniqueKeyForMdt = 0;
                    if(tempUniqueKeyForMdt != null && tempUniqueKeyForMdt != ''){
                        iHashUniqueKeyForMdt = tempUniqueKeyForMdt.hashCode();
                    }
                    
                    if(mIntegrationRecords.containsKey(cInt.Integration_Ext_Id__c)){
                        ASF_Integration__c integ = mIntegrationRecords.get(cInt.Integration_Ext_Id__c);
                        
                        // CHECK IF THE NUMBER OF ATTEMPTS COMPLETED FOR INTEGRATION OF TYPE PROCESS OR PREPOPULATED                        
                        if(integ.Type__c == ASF_Constants.RETRY_PROCESSTYPEINTEG || integ.Type__c == ASF_Constants.RETRY_PREPOPULATEDTYPEINTEG || 
                           integ.Type__c == ASF_Constants.RETRY_PROCESS_SEQUENTIALTYPEINTEG){
                               String tempKey = cInt.Case__c+'_'+cInt.Integration_Ext_Id__c;
                               integer ihashKey = tempKey.hashCode();
                               
                               integer iAttempts = 0;
                               if(mhashCaseCaseIntegrationVsAttempt.containsKey(ihashKey)){
                                   iAttempts = mhashCaseCaseIntegrationVsAttempt.get(ihashKey);
                               }
                               if(iAttempts <= iRetryNumbers){
                                   retryProcessTypeIntegrations(integ,cRec,casesToUpdate);
                                   
                                   String tempCompositeKeyForCaseIntegration = cInt.Case__c+cInt.Integration_Ext_Id__c;
                                   integer itempCompositeKeyForCaseInt = tempCompositeKeyForCaseIntegration.hashCode();
                                   mCaseCaseIntegrationIdVsAttempt.put(itempCompositeKeyForCaseInt,iAttempts);
                                   
                                   caseIdForProcess.add(cInt.Case__c);
                                   caseIntProcess.add(cInt.Integration_Ext_Id__c);
                                   
                               }
                               
                           }
                    }
                    else if(mHashedMdtVsPlatformEvtName.containsKey(iHashUniqueKeyForMdt)){
                        String platformEventToFire = mHashedMdtVsPlatformEvtName.get(iHashUniqueKeyForMdt);
                        retryNonASFIntegrationRelatedIntegration(cInt,nonASFIntegrationPlaformEvents,platformEventToFire);
                        setNextRetryParametersOnCaseIntegrations(cInt,caseInteToUpdate);
                    }
                }
            }
        }
        
        if(mCaseCaseIntegrationIdVsAttempt.keySet().size()>0){
            List<ASF_Case_Integration__c> asfCaseIntegrations = [SELECT ID,Case__c,Integration_Ext_Id__c FROM ASF_Case_Integration__c WHERE Case__c =: caseIdForProcess AND
                                                                 Integration_Ext_Id__c =:caseIntProcess AND Status__c = 'Pending'];
            for(ASF_Case_Integration__c cInteg : asfCaseIntegrations){
                String tempKey = cInteg.Case__c+cInteg.Integration_Ext_Id__c;
                integer itempKey = tempKey.hashcode();
                if(mCaseCaseIntegrationIdVsAttempt.containsKey(itempKey)){
                    cInteg.Retry_Attempt__c = mCaseCaseIntegrationIdVsAttempt.get(itempKey);
                    if(mCaseCaseIntegrationIdVsAttempt.get(itempKey) <= iRetryNumbers){
                        if(mCaseCaseIntegrationIdVsAttempt.get(itempKey) == iRetryNumbers){
                            cInteg.Next_Retry__c = null;
                            cInteg.Retry__c = false;
                        }
                        
                        caseInteToUpdate.add(cInteg);
                    }
                }
            }
        }
        
        
        
        if(casesToUpdate.size()>0){
            Database.update(casesToUpdate,false);
        }
        if(nonASFIntegrationPlaformEvents.size()>0){
            EventBus.publish(nonASFIntegrationPlaformEvents);
        }
        if(caseInteToUpdate.size()>0){
            Database.update(caseInteToUpdate,false);
        }
    }
    
    /**
* @description : retryNonASFIntegrationRelatedIntegration
* @author rsinghnagar@salesforce.com | 05-13-2024 
* @param cInt 
* @param plaformEventToTrigger 
* @param platformEventToFire 
**/
    private static void retryNonASFIntegrationRelatedIntegration(ASF_Case_Integration__c cInt, List<sObject> plaformEventToTrigger, String platformEventToFire)
    {
        sObject evt = (sObject)JSON.deserialize(cInt.Request__c, sObject.class);
        plaformEventToTrigger.add(evt);
    }
    
    /**
* @description 
* @author rsinghnagar@salesforce.com | 05-13-2024 
* @param integ 
* @param cRec 
* @param casesToUpdate 
**/
    private static void retryProcessTypeIntegrations(ASF_Integration__c integ, Case cRec,List<Case> casesToUpdate){
        ASF_IntegrationsController.IntegrationWrapper intResult = ASF_IntegrationsController.runIntegration(integ, cRec);
        
        if(intResult.status == 'Error' && intResult.assignToId != null){
            cRec.OwnerId = intResult.assignToId;
            casesToUpdate.add(cRec);
        }
    }
    
    /**
* @description 
* @author rsinghnagar@salesforce.com | 05-13-2024 
* @param cInt 
* @param caseInteToUpdate 
**/
    private static void setNextRetryParametersOnCaseIntegrations(ASF_Case_Integration__c cInt,List<ASF_Case_Integration__c> caseInteToUpdate){
        cInt.Status__c = 'Pending';
        cInt.Next_Retry__c = System.now().addMinutes(iRetryInterval);
        if(iRetryInterval == 0){
            cInt.Next_Retry__c = null;
            cInt.Retry__c = false;
        }
        else{
            if(cInt.Retry_Attempt__c != null){
                cInt.Retry_Attempt__c = cInt.Retry_Attempt__c + 1;
            }
            else{
                cInt.Retry_Attempt__c = 1;
            }
            if(cInt.Retry_Attempt__c > iRetryNumbers){
                cInt.Next_Retry__c = null;
                cInt.Retry__c = false;
            }
        }
        
        caseInteToUpdate.add(cInt);
    }
}