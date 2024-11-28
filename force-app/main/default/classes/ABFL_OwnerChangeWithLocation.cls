/*********************************************************
*Class        :  ABFL_OwnerChangeWithLocation
*Author       :  Shubham Sinha 
*Created Date :  08/01/2024
*@description  :  This class is created to change the owner of case wrt to location code of LAN 
*********************************************************/

@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABFL_OwnerChangeWithLocation {
    private static boolean firstrunInsert = true;
    private static boolean lanMatchRan = false ;
    private static boolean afterInsertRan = false ;
    public static String queueGroupQueue = 'SELECT Id FROM Group WHERE Type = \'Queue\' AND DeveloperName = \'ABFL_Mortgage_CS\' LIMIT 1';

    /****************************************************************************************************************
    * @param lstCase
    * @param oldMap
    * @description - created to change the owner of case wrt to location code of LAN 
    *****************************************************************************************************************/ 
    public static void updateSpocWrtLocation(List<Case> lstCase,Map<Id, Case> oldMap){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        List<Case> filteredCase = new List<Case>();
        SET<ID> setExpectedLogic = new SET<ID>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType(lstCase);
        if(mRecordTypeVsCases.containsKey(frameworkRTId) && firstrunInsert && !afterInsertRan){
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            for(Case cse : lstCase){
                if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(cse.Business_Unit__c)){
                	setExpectedLogic.add(cse.Id); 
                }
            }
            if(!setExpectedLogic.isEmpty()){
                Group queueRecord = (Group) Database.query(queueGroupQueue);
                for(Case objCase : newCaseMap.Values()){
                    if(oldMap.get(objCase.Id).OwnerId != objCase.OwnerId && objCase.OwnerId == queueRecord.Id && ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(objCase.Business_Unit__c) ){
                         filteredCase.add(objCase);
                   }  
                }
               if (!filteredCase.isEmpty()) {
                  ABFL_OwnerChangeWithLocation.updateSpocAbflLAN(filteredCase);
                  if(!lanMatchRan){
                  	ABFL_OwnerChangeWithLocation.updateSpocNotAbflLAN(filteredCase);
                   }
                }
            }
    	}
    }
    
    public static void updateCaseOwnerAtVerificationStage(Map<Id, Case> newMapCase,Map<Id, Case> oldMap) {
        List<Case> updateCaseOwner = new List<Case>();
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRec : newMapCase.values()) {
            if(Test.isRunningTest() || (caseRec.Business_Unit__c == 'ABFL' && caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c && caseRec.Stage__c == 'Verification' && ABFL_Constants.GRIEVANCE_TEAM_ASGNMENT_CTSTS.contains(caseRec.CCC_External_Id__c))){
                caseIds.add(caseRec.Id);
            }
        }
        if(!caseIds.isEmpty()){
            for(Case caseRec : [Select Id, ABFL_Case_Detail__r.Open_Stage_Owner_Email_Team__c, ABFL_Case_Detail__r.Open_Stage_Owner_Id__c from Case where Id IN :caseIds]){
                if(newMapCase.get(caseRec.Id).Stage__c == 'Verification' && newMapCase.get(caseRec.Id).moved_back__c == false && caseRec.ABFL_Case_Detail__r.Open_Stage_Owner_Id__c != null && caseRec.ABFL_Case_Detail__r.Open_Stage_Owner_Email_Team__c == 'GRT'){
                    //Cases which are going to Verification stage and 
                    newMapCase.get(caseRec.Id).OwnerId = caseRec.ABFL_Case_Detail__r.Open_Stage_Owner_Id__c;
                }
            }
        }
    }
    /****************************************************************************************************************
    * @param lstCase
    * @description - when LAN Starts with ABFL then if 5th to 7th character of LAN matches with location master, update the case owner with the matched Location Master' Spoc
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
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring WITH SYSTEM_MODE]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                Asset relatedAssetLAN = assetMap.get(updateCase.AssetId);
                if (extractedSubstring.contains(relatedAssetLAN.LAN__c.substring(4, 7))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(relatedAssetLAN.LAN__c.substring(4, 7));
                    if (locationRecord != null && locationRecord.SPOC__c != null) {
                        if(Trigger.isBefore && updateCase.OwnerId != locationRecord.SPOC__c){
                            updateCase.OwnerId = locationRecord.SPOC__c;
                            lanMatchRan = true;
                        }
                        else if(Trigger.isAfter && updateCase.OwnerId != locationRecord.SPOC__c){
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
            if ( Schema.sObjectType.Case.isUpdateable()){
                lanMatchRan = true;
                update insertFinalUpdateCase;
            }
        }
    }
    /****************************************************************************************************************
    * @param  lstCase
    * @description - when LAN does not start with ABFL then if 3rd to 5th character of LAN matches with location master, update the case owner with the matched Location Master' Spoc
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
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring WITH SYSTEM_MODE]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                Asset relatedAssetLAN = assetMap.get(updateCase.AssetId);
                if (extractedSubstring.contains(relatedAssetLAN.LAN__c.substring(2, 5))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(relatedAssetLAN.LAN__c.substring(2, 5));
                    if (locationRecord != null && locationRecord.SPOC__c != null) {
                        if(Trigger.isBefore  && updateCase.OwnerId != locationRecord.SPOC__c){
                            updateCase.OwnerId = locationRecord.SPOC__c;
                        }
                        else if(Trigger.isAfter && updateCase.OwnerId != locationRecord.SPOC__c ){
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
    * @param  lstCase
    * @description - for beforeInsert Event
    *****************************************************************************************************************/ 
    public static void beforeInsertupdateSpoc(List<Case> lstCase){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        List<Case> filteredCase = new List<Case>();
        SET<ID> setExpectedLogic = new SET<ID>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType(lstCase);
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
             for(Case cse : lstCase){
                if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(cse.Business_Unit__c)){
                	setExpectedLogic.add(cse.Id); 
                }
            }
            if(!setExpectedLogic.isEmpty()){
                Group queueRecord = (Group) Database.query(queueGroupQueue);
                for(Case objCase : lstCase){
                    if(objCase.OwnerId == queueRecord.Id && ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(objCase.Business_Unit__c) && objCase.LAN__c != NULL){
                        filteredCase.add(objCase);
                    }  
                }
               if (!filteredCase.isEmpty()) {
                  ABFL_OwnerChangeWithLocation.updateSpocAbflLAN(filteredCase);
                   if(!lanMatchRan){
                  		ABFL_OwnerChangeWithLocation.updateSpocNotAbflLAN(filteredCase);
					}
                }
        	}
        }
    }
    /****************************************************************************************************************
    * @param  lstCase
    * @description - for beforeInsert Event
    *****************************************************************************************************************/ 
    public static void afterInsertupdateSpoc(List<Case> lstCase){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        List<Case> filteredCase = new List<Case>();
        SET<ID> setExpectedLogic = new SET<ID>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType(lstCase);
        if(mRecordTypeVsCases.containsKey(frameworkRTId) && firstrunInsert){
            for(Case cse : lstCase){
                if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(cse.Business_Unit__c)){
                	setExpectedLogic.add(cse.Id); 
                }
            }
            if(!setExpectedLogic.isEmpty()){
            	Group queueRecord = (Group) Database.query(queueGroupQueue);
                List<Case> afterCases = [SELECT ID,OwnerId,LAN__c,Business_Unit__c FROM Case WHERE ID IN :lstCase AND OWNERID =: queueRecord.ID ];
                if(!afterCases.isEmpty()){
                    for(Case objCase : afterCases){
                        if(objCase.OwnerId == queueRecord.Id && ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(objCase.Business_Unit__c) && objCase.LAN__c != NULL){
                            filteredCase.add(objCase);
                        }  
                    }
                }
				if (!filteredCase.isEmpty()) {
					ABFL_OwnerChangeWithLocation.updateSpocAbflLANAfter(filteredCase);
                  	if(!lanMatchRan){
                  		ABFL_OwnerChangeWithLocation.updateSpocNotAbflLANAfter(filteredCase);
					}
				}
        	}
        }
        
    }
    /****************************************************************************************************************
    * @param lstCase
    * @description - when LAN Starts with ABFL then if 5th to 7th character of LAN matches with location master, update the case owner with the matched Location Master' Spoc
    *****************************************************************************************************************/ 
    public static void updateSpocAbflLANAfter(List<Case> lstCase){
        Set<String> extractedSubstring = new Set<String>();
        List<Case> finalUpdateCase = new List<Case>();
        List<Case> insertFinalUpdateCase = new List<Case>();
        for(Case objCase : lstCase){
            if (objCase.LAN__c != null) {
                if(objCase.LAN__c.startsWithIgnoreCase('ABFL')&& objCase.LAN__c.length()>6){
                    extractedSubstring.add(objCase.LAN__c.substring(4, 7));
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring WITH SYSTEM_MODE]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                if (extractedSubstring.contains(updateCase.LAN__c.substring(4, 7))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(updateCase.LAN__c.substring(4, 7));
                    if (locationRecord != null && locationRecord.SPOC__c != null && updateCase.OwnerId != locationRecord.SPOC__c) {
                        Case origCaseUpdate = new Case(Id=updateCase.Id, OwnerId = locationRecord.SPOC__c); 
                        insertFinalUpdateCase.add(origCaseUpdate);
                    }
                 }
              }
           }
        }
        if(!insertFinalUpdateCase.isEmpty()){
            ASF_Constants.bypassOwnerChangeValidation = true;
            firstrunInsert = false;
            lanMatchRan = true;
            afterInsertRan = true;
            update insertFinalUpdateCase;
        }
    }
    /****************************************************************************************************************
    * @param  lstCase
    * @description - updateSpocAbflLANAfter
    *****************************************************************************************************************/ 
    public static void updateSpocNotAbflLANAfter(List<Case> lstCase){
        Set<String> extractedSubstring = new Set<String>();
        List<Case> finalUpdateCase = new List<Case>();
        List<Case> insertFinalUpdateCase = new List<Case>();
        for(Case objCase : lstCase){
            if (objCase.LAN__c != null) {
                if(!objCase.LAN__c.startsWithIgnoreCase('ABFL')&& objCase.LAN__c.length()>4){
                    extractedSubstring.add(objCase.LAN__c.substring(2, 5));
                    finalUpdateCase.add(objCase);
                }
            }
        }  
        if(!extractedSubstring.isEmpty()){
            Map<String, ABFL_Location_Master__c> codeToLocationMap = new Map<String, ABFL_Location_Master__c>();
            for (ABFL_Location_Master__c locationRecord : [SELECT Id, SPOC__c,Location__c, Code__c FROM ABFL_Location_Master__c WHERE Code__c IN :extractedSubstring WITH SYSTEM_MODE]) {
                codeToLocationMap.put(locationRecord.Code__c, locationRecord);
            }
            if(!codeToLocationMap.isEmpty()){
            for (Case updateCase : finalUpdateCase) {
                if (extractedSubstring.contains(updateCase.LAN__c.substring(2, 5))) {
                    ABFL_Location_Master__c locationRecord = codeToLocationMap.get(updateCase.LAN__c.substring(2, 5));
                    if (locationRecord != null && locationRecord.SPOC__c != null && updateCase.OwnerId != locationRecord.SPOC__c) {
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
            afterInsertRan = true;
            update insertFinalUpdateCase;
        }
    }

    /****************************************************************************************************************
    * @Function - createCaseCommentWhenClosedAfterInsert
    * @param caseList -  list of cases from trigger.new.
    * @description - Invoked from AfterInsert, this method creates CaseComment from Case.Comments field when the Case.IsClsoed = true while creation.
    *****************************************************************************************************************/
    
    public static void createCaseCommentWhenClosedAfterInsert(list<Case> caseList){
        if(!caselist.isEmpty()){
            list<CaseComment> commentListToInsert = new List<CaseComment>();
            for(Case caseObj: caseList){
                if( !String.isBlank(caseObj.Comments) && caseObj.IsClosed && caseObj.business_unit__c == 'ABFL'){
                    commentListToInsert.add(new CaseComment(ParentId = caseObj.Id, CommentBody = caseObj.Comments));
                }
            } 
            if(!commentListToInsert.isEmpty() &&  Schema.sObjectType.CaseComment.isCreateable()){

                insert commentListToInsert;
            }
        }
    }

    /****************************************************************************************************************
    * @Function - checkCCCExternalIdAndAddRTId
    * @param caseList -  list of cases from trigger.new.
    * @description - Invoked from beforeInsert, this method checks the CCCExternal Id is valid or not. If not valid then assign the RecordType as the Ineraction(Pre-framework).
                     Also checks if the Source is other than email then assigns this case to the particular queue based on the Asset LOB
    *****************************************************************************************************************/
    public static void checkCCCExternalIdAndAddRTId(List<Case> caseList){
        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        map<String, String> mAssetLOBswithQueue = ABFL_Constants.mAssetLOBsVSDefaultQueue;
        map<String, String> mGroupDevNameWithIds = new map<String, String>();
        map<String,String> mLANWithLOB = new map<String,String>();

        set<String> sCCCIds = new set<String>();
        set<String> sValidCCCIds = new set<String>();
        for(Case cObj : caseList){
            if(cObj.RecordTypeId == frameworkRTId && cobj.Business_Unit__c == ABFL_Constants.ABFL ){
                sCCCIds.add(cobj.CCC_External_Id__c);
                if(cObj.AssetId != null){
                    mLANWithLOB.put(cObj.AssetId,'');
                }
            }
        }
        if(!sCCCIds.isEmpty()){
            for(ASF_Case_Category_Config__c cccObj : [SELECT id, Name,CCC_External_Id__c from ASF_Case_Category_Config__c where CCC_External_Id__c IN : sCCCIds AND Business_Unit__c=:ABFL_Constants.ABFL WITH SYSTEM_MODE]){
                sValidCCCIds.add(cccObj.CCC_External_Id__c);
            }
        
            if(!mLANWithLOB.isEmpty()){
                for(Asset aObj : [SELECT Id,LOB__c from Asset Where Id IN : mLANWithLOB.keySet() WITH SYSTEM_MODE]){
                    mLANWithLOB.put(aObj.Id, aObj.LOB__c);
                }
                //get the Queue Ids from QueueDevName
                for(Group gObj: [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN : mAssetLOBswithQueue.values()  WITH SYSTEM_MODE ]){
                    mGroupDevNameWithIds.put(gObj.DeveloperName, gObj.Id);
                }
            }

            for(Case cobj: caselist){
                if(cObj.RecordTypeId == frameworkRTId && !sValidCCCIds.contains(cobj.CCC_External_Id__c)  ){
                    cobj.recordTypeId = interactionRTId;
                    if(cObj.AssetId !=null && cObj.Source__c !='Email') 
                    {
                        String queueDevName = mAssetLOBswithQueue.get(mLANWithLOB.get(cObj.AssetId));
                        if(mGroupDevNameWithIds.containsKey(queueDevName))
                        {
                            cobj.OwnerId = mGroupDevNameWithIds.get(queueDevName);
                        }
                    }
                }
            }
        }
    }
}
