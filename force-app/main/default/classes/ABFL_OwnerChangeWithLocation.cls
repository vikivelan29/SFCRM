/*********************************************************
*Class        :  ABFL_OwnerChangeWithLocation
*Author       :  Shubham Sinha 
*Created Date :  08/01/2024
*Description  :  This class is created to change the owner of case wrt to location code of LAN 
*********************************************************/
public with sharing class ABFL_OwnerChangeWithLocation {
    private static boolean firstrunInsert = true;
 /****************************************************************************************************************
* @param  - List<CASE> & Map of Old Cases
* @return - void .
* @Description - created to change the owner of case wrt to location code of LAN 
*****************************************************************************************************************/ 
    public static void updateSpocWrtLocation(List<Case> lstCase,Map<Id, Case> oldMap){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        List<Case> filteredCase = new List<Case>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType(lstCase);
        system.debug('mRecordTypeCase '+mRecordTypeVsCases);
        if(mRecordTypeVsCases.containsKey(frameworkRTId) && firstrunInsert){
            Group queueRecord = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABFL_Mortgage_CS' LIMIT 1];
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            for(Case objCase : newCaseMap.Values()){
                system.debug('objCaseIssd '+objCase.Id);
                if(oldMap.get(objCase.Id).OwnerId != objCase.OwnerId && objCase.OwnerId == queueRecord.Id && objCase.Business_Unit__c == 'ABFL'){
                     filteredCase.add(objCase);
                    system.debug('filteredCase1 '+filteredCase);
               }  
            }
           if (!filteredCase.isEmpty()) {
              ABFL_OwnerChangeWithLocation.updateSpocAbflLAN(filteredCase);
              ABFL_OwnerChangeWithLocation.updateSpocNotAbflLAN(filteredCase);
            }
        }
    }
/****************************************************************************************************************
* @param  - List<CASE> 
* @return - void .
* @Description - when LAN Starts with ABFL then if 5th to 7th character of LAN matches with location master, update the case owner with the matched Location Master' Spoc
*****************************************************************************************************************/ 
    public static void updateSpocAbflLAN(List<Case> lstCase){
        Set<String> extractedSubstring = new Set<String>();
        List<Case> finalUpdateCase = new List<Case>();
        List<Case> insertFinalUpdateCase = new List<Case>();
        Set<Id> assetIds = new Set<Id>();
        for (Case objCase : lstCase){
            if (objCase.AssetId != null) {
                assetIds.add(objCase.AssetId);
            }
        }
        Map<Id, Asset> assetMap = new Map<Id, Asset>([SELECT Id, LAN__c FROM Asset WHERE Id IN :assetIds]);
        for(Case objCase : lstCase){
            if (objCase.AssetId != null) {
                Asset relatedAsset = assetMap.get(objCase.AssetId);
                if(relatedAsset.LAN__c.startsWithIgnoreCase('ABFL')&& relatedAsset.LAN__c.length()>6){
                    extractedSubstring.add(relatedAsset.LAN__c.substring(4, 7));
                    system.debug('extractedSubstringId '+extractedSubstring);
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                Asset relatedAssetLAN = assetMap.get(updateCase.AssetId);
                if (extractedSubstring.contains(relatedAssetLAN.LAN__c.substring(4, 7))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(relatedAssetLAN.LAN__c.substring(4, 7));
                    if (locationRecord != null && locationRecord.SPOC__c != null) {
                        if(Trigger.isBefore){
                            updateCase.OwnerId = locationRecord.SPOC__c;
                            system.debug('OwnerIdtest'+updateCase.OwnerId);
                        }
                        else if(Trigger.isAfter){
                            Case origCaseUpdate = new Case(Id=updateCase.Id, OwnerId = locationRecord.SPOC__c); 
                            insertFinalUpdateCase.add(origCaseUpdate);  
                        }                 
                    }
                 }
              }
           }
        }
         if(!insertFinalUpdateCase.isEmpty()){
            ASF_Constants.bypassOwnerChangeValidation = true;
            //ASF_TriggerSkipperUtility.markTriggerRun('Case');
            firstrunInsert = false;
            update insertFinalUpdateCase;
        }
    }
/****************************************************************************************************************
* @param  - List<CASE> & Map 
* @return - void .
* @Description - when LAN does not start with ABFL then if 3rd to 5th character of LAN matches with location master, update the case owner with the matched Location Master' Spoc
*****************************************************************************************************************/ 
    public static void updateSpocNotAbflLAN(List<Case> lstCase){
        Set<String> extractedSubstring = new Set<String>();
        List<Case> finalUpdateCase = new List<Case>();
        List<Case> insertFinalUpdateCase = new List<Case>();
        Set<Id> assetIds = new Set<Id>();
        for (Case objCase : lstCase){
            if (objCase.AssetId != null) {
                assetIds.add(objCase.AssetId);
            }
        }
        Map<Id, Asset> assetMap = new Map<Id, Asset>([SELECT Id, LAN__c FROM Asset WHERE Id IN :assetIds]);
        for(Case objCase : lstCase){
            if (objCase.AssetId != null) {
                Asset relatedAsset = assetMap.get(objCase.AssetId);
                if(!relatedAsset.LAN__c.startsWithIgnoreCase('ABFL')&& relatedAsset.LAN__c.length()>4){
                    extractedSubstring.add(relatedAsset.LAN__c.substring(2, 5));
                    system.debug('extractedSubstringId '+extractedSubstring);
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                Asset relatedAssetLAN = assetMap.get(updateCase.AssetId);
                if (extractedSubstring.contains(relatedAssetLAN.LAN__c.substring(2, 5))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(relatedAssetLAN.LAN__c.substring(2, 5));
                    if (locationRecord != null && locationRecord.SPOC__c != null) {
                        if(Trigger.isBefore){
                            updateCase.OwnerId = locationRecord.SPOC__c;
                        }
                        else if(Trigger.isAfter){
                        Case origCaseUpdate = new Case(Id=updateCase.Id, OwnerId = locationRecord.SPOC__c); 
                        insertFinalUpdateCase.add(origCaseUpdate);  
                        }
                    }
                 }
              }
           }
        }
        if(!insertFinalUpdateCase.isEmpty()){
            ASF_Constants.bypassOwnerChangeValidation = true;
           // ASF_TriggerSkipperUtility.markTriggerRun('Case');
            firstrunInsert = false;
            update insertFinalUpdateCase;
        }
    }
/****************************************************************************************************************
* @param  - List<CASE> 
* @return - void .
* @Description - for beforeInsert Event
*****************************************************************************************************************/ 
    public static void beforeInsertupdateSpoc(List<Case> lstCase){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        List<Case> filteredCase = new List<Case>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType(lstCase);
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Group queueRecord = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABFL_Mortgage_CS' LIMIT 1];
            for(Case objCase : lstCase){
                system.debug('objCaseId '+objCase.ownerId);
                system.debug('objCaseIdOWNER '+objCase.LAN__c);
                if(objCase.OwnerId == queueRecord.Id && objCase.Business_Unit__c == 'ABFL' && objCase.LAN__c != NULL){
                    filteredCase.add(objCase);
                    system.debug('filteredCase3 '+filteredCase);
                }  
            }
           if (!filteredCase.isEmpty()) {
              ABFL_OwnerChangeWithLocation.updateSpocAbflLAN(filteredCase);
              ABFL_OwnerChangeWithLocation.updateSpocNotAbflLAN(filteredCase);
            }
        }
    }
    /****************************************************************************************************************
* @param  - List<CASE> 
* @return - void .
* @Description - for beforeInsert Event
*****************************************************************************************************************/ 
    public static void afterInsertupdateSpoc(List<Case> lstCase){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        List<Case> filteredCase = new List<Case>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType(lstCase);
        if(mRecordTypeVsCases.containsKey(frameworkRTId) && firstrunInsert){
            Group queueRecord = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABFL_Mortgage_CS' LIMIT 1];
            List<Case> afterCases = [SELECT ID,OwnerId,LAN__c,Business_Unit__c FROM Case WHERE ID IN :lstCase AND OWNERID =: queueRecord.ID ];
            if(!afterCases.isEmpty()){
                for(Case objCase : afterCases){
                    system.debug('objCaseId '+objCase.ownerId);
                    system.debug('objCaseIdOWNER '+objCase.LAN__c);
                    if(objCase.OwnerId == queueRecord.Id && objCase.Business_Unit__c == 'ABFL' && objCase.LAN__c != NULL){
                        filteredCase.add(objCase);
                        system.debug('filteredCase3 '+filteredCase);
                    }  
                }
            }
           if (!filteredCase.isEmpty()) {
              ABFL_OwnerChangeWithLocation.updateSpocAbflLANAfter(filteredCase);
              ABFL_OwnerChangeWithLocation.updateSpocNotAbflLANAfter(filteredCase);
            }
        }
    }
    /****************************************************************************************************************
* @param  - List<CASE> 
* @return - void .
* @Description - when LAN Starts with ABFL then if 5th to 7th character of LAN matches with location master, update the case owner with the matched Location Master' Spoc
*****************************************************************************************************************/ 
    public static void updateSpocAbflLANAfter(List<Case> lstCase){
        Set<String> extractedSubstring = new Set<String>();
        List<Case> finalUpdateCase = new List<Case>();
        List<Case> insertFinalUpdateCase = new List<Case>();
        for(Case objCase : lstCase){
            if (objCase.LAN__c != null) {
                if(objCase.LAN__c.startsWithIgnoreCase('ABFL')&& objCase.LAN__c.length()>6){
                    extractedSubstring.add(objCase.LAN__c.substring(4, 7));
                    system.debug('extractedSubstringIdAfter '+extractedSubstring);
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                if (extractedSubstring.contains(updateCase.LAN__c.substring(4, 7))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(updateCase.LAN__c.substring(4, 7));
                    if (locationRecord != null && locationRecord.SPOC__c != null) {
                        Case origCaseUpdate = new Case(Id=updateCase.Id, OwnerId = locationRecord.SPOC__c); 
                        insertFinalUpdateCase.add(origCaseUpdate);
                    }
                 }
              }
           }
        }
        if(!insertFinalUpdateCase.isEmpty()){
            ASF_Constants.bypassOwnerChangeValidation = true;
           // ASF_TriggerSkipperUtility.markTriggerRun('Case');
            firstrunInsert = false;
            update insertFinalUpdateCase;
        }
    }
     public static void updateSpocNotAbflLANAfter(List<Case> lstCase){
        Set<String> extractedSubstring = new Set<String>();
        List<Case> finalUpdateCase = new List<Case>();
        List<Case> insertFinalUpdateCase = new List<Case>();
        for(Case objCase : lstCase){
            if (objCase.LAN__c != null) {
                if(!objCase.LAN__c.startsWithIgnoreCase('ABFL')&& objCase.LAN__c.length()>4){
                    extractedSubstring.add(objCase.LAN__c.substring(2, 5));
                    system.debug('extractedSubstringId '+extractedSubstring);
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                if (extractedSubstring.contains(updateCase.LAN__c.substring(2, 5))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(updateCase.LAN__c.substring(2, 5));
                    if (locationRecord != null && locationRecord.SPOC__c != null) {
                        Case origCaseUpdate = new Case(Id=updateCase.Id, OwnerId = locationRecord.SPOC__c); 
                        insertFinalUpdateCase.add(origCaseUpdate);                    }
                 }
              }
           }
        }
        if(!insertFinalUpdateCase.isEmpty()){
            ASF_Constants.bypassOwnerChangeValidation = true;
            //ASF_TriggerSkipperUtility.markTriggerRun('Case');
            firstrunInsert = false;
            update insertFinalUpdateCase;
        }
    }
}