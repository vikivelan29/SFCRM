/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 07-01-2024
* @last modified by  : rsinghnagar@salesforce.com
**/
public without sharing class ASF_CaseSLAHandlerV1 {    
    
    private static Boolean isFromOmniChannel = false;

    private static ASF_SLAWrapper prepareSLAConfigMap(Set<string> externalIds,Set<string> stageNames){
        ASF_SLAWrapper slaObject = new ASF_SLAWrapper();
        List<ASF_Case_Stage_Config__c> caseStageConfigs = new List<ASF_Case_Stage_Config__c>();
        map<string,ASF_Case_Stage_Config__c> tempMap = new map<string,ASF_Case_Stage_Config__c>();
        if(externalIds.size() >0 && stageNames.size()>0){
            System.debug('@@@externalIds'+externalIds);
            System.debug('@@@stageNames'+stageNames);
            caseStageConfigs = [SELECT Id, 
                                Stage_SLA_1__c,
                                Stage_SLA_2__c,
                                Stage_SLA_3__c,
                                Stage_Reopen_SLA_1__c, 
                                Stage_Reopen_SLA_2__c, 
                                Stage_Reopen_SLA_3__c,
                                StageName__c,
                                Is_Approval_Stage__c, 
                                Case_Category_Config__r.CCC_External_Id__c, 
                                Case_Category_Config__r.Overall_Case_Closure_SLA__c,
                                Case_Category_Config__r.Reopened_Case_Closure_SLA__c,
                                SLA_Target_1__c,
                                SLA_Target_2__c,
                                SLA_Target_3__c,
                                SLA_Override_Enabled__c,
                                Parent_C3_Record__c
                                FROM ASF_Case_Stage_Config__c 
                                WHERE Case_Category_Config__r.CCC_External_Id__c IN :externalIds 
                                AND StageName__c IN :stageNames];
            System.debug('@@@caseStageConfigs'+caseStageConfigs);
            if(caseStageConfigs.size() >0){
                for(ASF_Case_Stage_Config__c csc: caseStageConfigs){
                    string mapKey = csc.Parent_C3_Record__c + csc.StageName__c;
                    tempMap.put(mapKey,csc);
                }
                slaObject.externalIdStageNameCaseStageConfigMap = tempMap;
            }
        }
        return slaObject;
    }
    /*
    this method should return Stage SLA and Case SLA. 
    When reopened , This can be different, 
    Today it does not have SLA override rules. But logic needs to be added here.
    */
    private static map<String,long> getSLAFieldValues(ASF_SLAWrapper s, Case c,Case oldCase){
        
        map<string,long> resultMap = new map<string,long>();
        long slaIdentifier = 3600000;
        long sla1Sec;
        long sla2Sec;
        long sla3Sec;
        long closeSlaSec;  
        Map<string,ASF_Case_Stage_Config__c> externalIdStageNameCaseStageConfigMap = s.externalIdStageNameCaseStageConfigMap;
        string mapKey = c.CCC_External_Id__c+c.stage__c;
        if(c.Reopened__c){
            if(externalIdStageNameCaseStageConfigMap != null && externalIdStageNameCaseStageConfigMap.containsKey(mapKey)){
                sla1Sec = externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_Reopen_SLA_1__c != null ? Integer.valueOf(externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_Reopen_SLA_1__c) * slaIdentifier : null;
                sla2Sec = externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_Reopen_SLA_2__c != null ? Integer.valueOf(externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_Reopen_SLA_2__c) * slaIdentifier : null;
                sla3Sec = externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_Reopen_SLA_3__c != null ? Integer.valueOf(externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_Reopen_SLA_3__c) * slaIdentifier : null;
                closeSlaSec = externalIdStageNameCaseStageConfigMap.get(mapKey).Case_Category_Config__r.Reopened_Case_Closure_SLA__c != null ? Integer.valueOf( externalIdStageNameCaseStageConfigMap.get(mapKey).Case_Category_Config__r.Reopened_Case_Closure_SLA__c) * slaIdentifier  : null;
            }
            // If this has been Just Reopened in this update, then aslo set the Overall Case Closure
            // to the Reopen Case Closure
            //TBD ritika
            // if(oldCase != null && !oldCase.Reopened__c){
            //     closeSlaSec = BusinessHours.add(c.BusinessHoursId,c.Case_Stage_Change_Date__c,Integer.valueOf(externalIdStageNameCaseStageConfigMap.get(mapKey).Case_Category_Config__r.Reopened_Case_Closure_SLA__c)* slaIdentifier );
            // }
        }
        else { 
            map<String,long> slaValues = (ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods != null && ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods.containsKey(c.Id) &&
                                        ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods.get(c.Id) != null) ? 
                                        ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods.get(c.Id).slaCaseAndStageOverrideValues : null;
            
            if(slaValues != null){
                //case SLA override
                if(slaValues.get('caseOverride') != null){
                    closeSlaSec =  slaValues.get('caseOverride') * slaIdentifier;  
                }
                else if (externalIdStageNameCaseStageConfigMap != null && s.externalIdStageNameCaseStageConfigMap.get(mapKey).Case_Category_Config__r.Overall_Case_Closure_SLA__c != null) { // Added null check on 
                    closeSlaSec =  Integer.valueOf( s.externalIdStageNameCaseStageConfigMap.get(mapKey).Case_Category_Config__r.Overall_Case_Closure_SLA__c) * slaIdentifier;
                }
                //Stage SLA 1 overirde
                if(slaValues.get('stageSLA1Override') != null){
                    sla1Sec =  slaValues.get('stageSLA1Override') * slaIdentifier ;
                }
                else {
                    if(externalIdStageNameCaseStageConfigMap != null)
                      sla1Sec =  s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_1__c != null ? Integer.valueOf(s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_1__c) * slaIdentifier : null;
                } 
                //Stage SLA 2 overirde
                if(slaValues.get('stageSLA2Override') != null){
                    sla2Sec =  slaValues.get('stageSLA2Override') * slaIdentifier;
                }
                else {
                    if (externalIdStageNameCaseStageConfigMap != null)
                      sla2Sec =  s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_2__c != null ? Integer.valueOf(s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_2__c) * slaIdentifier : null;
                } 
                //Stage SLA 2 overirde
                if(slaValues.get('stageSLA3Override') != null){
                    sla3Sec =  slaValues.get('stageSLA3Override') * slaIdentifier;
                }
                else { 
                    if (externalIdStageNameCaseStageConfigMap != null)  
                      sla3Sec =  s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_3__c != null ? Integer.valueOf(s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_3__c) * slaIdentifier : null;
                } 

            }
            else if (externalIdStageNameCaseStageConfigMap != null){
                sla1Sec = s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_1__c != null ? Integer.valueOf(s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_1__c) * slaIdentifier : null;
                sla2Sec = s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_2__c != null ? Integer.valueOf(s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_2__c) * slaIdentifier : null;
                sla3Sec = s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_3__c != null ? Integer.valueOf(s.externalIdStageNameCaseStageConfigMap.get(mapKey).Stage_SLA_3__c) * slaIdentifier : null;
                closeSlaSec = Integer.valueOf( s.externalIdStageNameCaseStageConfigMap.get(mapKey).Case_Category_Config__r.Overall_Case_Closure_SLA__c) * slaIdentifier;
            }
            
        }    
        resultMap.put('sla1',sla1Sec);
        resultMap.put('sla2',sla2Sec);
        resultMap.put('sla3',sla3Sec);
        resultMap.put('caseClosureSLA',closeSlaSec);
        //SLA override rules will come here.
        return resultMap;
        
    }
    
    /* this method is called during case Insert. 
    Core logic to calculate SLA1 and Case SLA resides here.
    SLA_target which is basically who should get email when SLA is breached is also here
    */
    
    private static Map<Id, Case> calculateSLA(List<Case> newCases,ASF_SLAWrapper s, Map<Id, Case> casesToUpdate){
        ASF_CaseHistoryPercentageCalc percntCls = new ASF_CaseHistoryPercentageCalc();
        //Map<String,ASF_Case_Stage_Config__c> externalIdStageMap = s.externalIdStageMap;
        map<string,ASF_Case_Stage_Config__c> externalIdStageNameCaseStageConfigMap = s.externalIdStageNameCaseStageConfigMap;
        
        Map<Integer,ASF_SLABusinessHoursWrapper> businesssHrsMap = getCaseOwnerBusinessHours(null,newCases);
        //String defaultBusinessHrs = [SELECT id FROM businesshours WHERE IsDefault=true LIMIT 1].id;
        
        Integer index = 0;
        for(Case c: newCases){
            if(c.CCC_External_Id__c != null && c.stage__c != null){
                if(externalIdStageNameCaseStageConfigMap != null && externalIdStageNameCaseStageConfigMap.containsKey(c.CCC_External_Id__c+c.stage__c)){
                    if(!casesToUpdate.containsKey(c.Id)){
                        casesToUpdate.put(c.Id, new Case(Id=c.Id));
                    }
                    Case updatedCase = casesToUpdate.get(c.Id);
                    map<string,long> slaMap = getSLAFieldValues(s,c,null);
                    long sla1Sec;
                    long sla2Sec;
                    long sla3Sec;
                    long closeSlaSec ;  
                    updatedCase.BusinessHoursId = c.BusinessHoursId;
                    updatedCase.SLA_Target_1__c = null;
                    updatedCase.SLA_Target_2__c = null;
                    updatedCase.SLA_Target_3__c = null;
                    if(businesssHrsMap.containsKey(index)){
                        // if(string.valueOf(c.OwnerId).startsWith('005')){
                        //     if(businesssHrsMap.get(index).caseUserOwnerBusinessHoursMap != null){
                        //         updatedCase.BusinessHoursId = businesssHrsMap.get(index).caseUserOwnerBusinessHoursMap;
                        //     }
                        // }
                        // //queue
                        // else {
                        //     if(businesssHrsMap.get(index).caseQueueOwnerBusinessHourMap != null){
                        //         updatedCase.BusinessHoursId = businesssHrsMap.get(index).caseQueueOwnerBusinessHourMap;
                        //     }
                        // }
                        if( businesssHrsMap.get(index).ownerUserRecordorQueueOwnerEmailUserRecord != null){
                            if(businesssHrsMap.get(index).ownerUserRecordorQueueOwnerEmailUserRecord.manager != null){
                                updatedCase.SLA_Target_1__c = businesssHrsMap.get(index).ownerUserRecordorQueueOwnerEmailUserRecord.manager.email;
                            }
                            if(businesssHrsMap.get(index).ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager != null){
                                updatedCase.SLA_Target_2__c = businesssHrsMap.get(index).ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.email;
                            }
                            if(businesssHrsMap.get(index).ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager != null){
                                updatedCase.SLA_Target_3__c = businesssHrsMap.get(index).ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager.email;
                            }    
                        }
                    }
                    
                    sla1Sec = slaMap.get('sla1');
                    sla2Sec = slaMap.get('sla2');
                    sla3Sec = slaMap.get('sla3');
                    closeSlaSec = slaMap.get('caseClosureSLA');

                    /*
                    Percentage is to calculate fields which is available in List view.
                    Example if Over all Case closure is 31-Dec , then we get calculate what s
                    75% of target of Date of 31-Dec , what is 90% and more.
                    Since we are using businss hrs , we cannot use case age in list view.
                    Hence this work around. agents will pick cases which are closure for SLA.
                    More of proactove way of selecting cases to work on and avoiding SLA breach
                    */

                    // Added null check on closeSlaSec
                    if(closeSlaSec != null) {
                        updatedCase.Overall_Case_Closure_SLA__c =BusinessHours.add(updatedCase.BusinessHoursId, system.now(), closeSlaSec);
                        percntCls.setOverallPercSLAFields(closeSlaSec,updatedCase.BusinessHoursId,system.now(),updatedCase);
                    }
                    
                    if(sla1Sec != null){
                        updatedCase.Stage_SLA_1__c = BusinessHours.add(updatedCase.BusinessHoursId, system.now(), sla1Sec);
                        percntCls.setStagePercSLAFields(sla1Sec,updatedCase.BusinessHoursId,system.now(),updatedCase);
                    }
                    
                    if(sla2Sec != null){
                        updatedCase.Stage_SLA_2__c = BusinessHours.add(updatedCase.BusinessHoursId, system.now(), sla2Sec);
                    }
                    
                    if(sla3Sec != null){
                        updatedCase.Stage_SLA_3__c = BusinessHours.add(updatedCase.BusinessHoursId, system.now(), sla3Sec);
                    }
                }
            }
            
            index++;
        }
        return casesToUpdate;
    }
    
    public static Map<Id, Case> calculateSLAOnCaseInsert(List<Case> newCases){
        //For Case coming check external ID -> get the stage ->SLA for the stage
        Set<string> externalIdList = new set<string>();
        set<string> caseStageList = new set<String>();
        List<ASF_Case_Stage_Config__c> caseStageConfigs = new list<ASF_Case_Stage_Config__c>();
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();
        Integer index=0;
        for( Case c:newCases){
            Case updatedCase = new Case(Id=c.Id);
            resetSLAFields(c,null, updatedCase);
            casesToUpdate.put(c.Id, updatedCase);
            if(c.CCC_External_Id__c != null){
                externalIdList.add(c.CCC_External_Id__c);
            }
            if(c.Stage__c != null){
                caseStageList.add(c.Stage__c);
            }
        }
        ASF_SLAWrapper slaObject = prepareSLAConfigMap(externalIdList,caseStageList);
        casesToUpdate = calculateSLA(newCases,slaObject,casesToUpdate);
        return casesToUpdate;
    }
    
    /*
    When owner changes or Stage chages , SLA history is record.
    Latest record has running record true which means it has start date but not end Date.
    When someone changes owner or Stage , previous record end date gets populated
    and runing record becomes false and new record gets inserted.
    Cycle continues
    */
    public static void insertSLAHistory(map<Id, Case> oldCases,map<Id, Case> newCases){
        map<id,Boolean> caseBackStageMovementCheck = new  map<id,Boolean>();
        //during insert , old will be null. hence does not matter to call method and waste 25ms
        if(oldCases!=null){
            caseBackStageMovementCheck = getMovedBackCases(oldCases,newCases);
        }
        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        Map<Id, Case> internalCaseUpdateMap = ASF_CaseTriggerModularHelper.getCaseFinalDMLMap();
        //without query, owner.name will not come  . hence this query is needed 
        for(Case c : [SELECT Id, Owner.Name, BusinessHoursId,Status, Stage__c, PlatformEventInitiatedBy__c,Case_Assigned_Team__c FROM Case WHERE Id IN: newCases.values()]){
            Case updatedCase = internalCaseUpdateMap.get(c.Id);
            //Not coming from Omnichannel
            //pure insert and
            //(updatecase present and owner id is populated & stage is not changing - means assigment yet to happen during insert
            //or skipsla is populated)
            //then skip
            if(!ASF_CaseSLAHandlerV1.isFromOmniChannel && oldCases == null &&
            (
                (updatedCase != null && updatedCase.OwnerId != null && updatedCase.Stage__c == null)
                ||
                newCases.get(c.Id).SkipModifyingSLAHistory__c != null
            )
            ){
                continue;
            }
            ASF_Case_SLA_History__c slaHistory = new ASF_Case_SLA_History__c();
            slaHistory.Current_Owner__c = c.Owner.Name;
            slaHistory.Current_Owner_Id__c = c.OwnerId;
            slaHistory.Case__c = c.Id;
            slaHistory.Stage__c = c.Stage__c;
            slaHistory.Status__c = c.Status;
            // VIRENDRA - 11 June 2024 - To STAMP CASE ASSIGNED TEAM DURING THE SLA CREATION.
            slaHistory.Case_Assigned_Team__c = c.Case_Assigned_Team__c;
            // VIRENDRA - ENDS HERE.
            slaHistory.FromStage__c = (oldCases != null && c.Stage__c!=oldCases.get(c.Id).Stage__c)?oldCases.get(c.Id).Stage__c:'';
            slaHistory.Actioned_By__c = c.Stage__c == 'Resolved'?c.Owner.Name:UserInfo.getName();
            slaHistory.Actioned_By__c = ASF_CaseSLAHandlerV1.isFromOmniChannel?Label.ASF_Omnichannel_ActionedBy_Username:slaHistory.Actioned_By__c;
            if(ASF_BulkCaseProcessorUtility.isBulkProcessing && (UserInfo.getName() == 'Platform Integration User' || UserInfo.getUserType() == 'AutomatedProcess')){
                slaHistory.Actioned_By__c = c.PlatformEventInitiatedBy__c;
            }
            
            //if stage is blank , then probbaly email2Case
            if(String.isBlank(slaHistory.Stage__c)){
                slaHistory.Stage__c = slaHistory.Status__c;    
            }
            slaHistory.Stage_Start_Date__c = system.now();
            slaHistory.is_Running_Record__c = true;
            slaHistory.BusinessHoursId__c = c.BusinessHoursId;
            if(oldCases != null ){
                if(caseBackStageMovementCheck.containsKey(c.Id)){
                    // Defensive in case of Email to Case.
                    slaHistory.Is_Move_Back__c = caseBackStageMovementCheck.get(c.Id);
                }
            }
            
            slaHistoryList.add(slaHistory);
        }
        
        if(!slaHistoryList.isEmpty()){
            insert slaHistoryList;
        }
    }
    /*
    when Case is moved back to previous stages , then on SLA history we need flag.
    This is needed for reporting purpose.
    we thought of using running record logic. But when case goes backward and comes , target stage also gets moved - true.
    Thats inocrrect.
    hence logic is to check if desitnation stage order is > current stage order only 
    example : Open--Inprogress-PendingApproal--Closed
    from Open--Inprogress , isMovedback is false
    Inprogress --> Open - is moved back is true
    */
    
    private static map<Id, Boolean> getMovedBackCases(map<Id, Case> currentCasesMap,map<Id, Case> newCasesMap) {
        map<Id, boolean> caseBackMovementCheckMap = new Map<Id, Boolean>();
        list<string> externalIdList = new List<string>();
        list<string> oldCaseStages = new List<string>();
        boolean isMoveBack = false;
        for (Id i : currentCasesMap.keyset()) {
            externalIdList.add(currentCasesMap.get(i).CCC_External_Id__c);
        }
        
        list<ASF_Case_Stage_Config__c> caseStages = [ SELECT Id,
                                                     Order__c,
                                                     StageName__c,
                                                     Case_Category_Config__r.CCC_External_Id__c
                                                     FROM ASF_Case_Stage_Config__c
                                                     WHERE Parent_C3_Record__c IN :externalIdList
                                                     ORDER BY Order__c
                                                    ];
        
        map<string, list<ASF_Case_Stage_Config__c>> c3CscRecords = new Map<string, list<ASF_Case_Stage_Config__c>>();
        for (ASF_Case_Stage_Config__c csc : caseStages) {
            string mapKey = csc.Case_Category_Config__r.CCC_External_Id__c;
            if (c3CscRecords.containsKey(mapKey)) {
                c3CscRecords.get(mapKey).add(csc);
            } else {
                list<ASF_Case_Stage_Config__c> tempStages = new List<ASF_Case_Stage_Config__c>();
                tempStages.add(csc);
                c3CscRecords.put(mapKey, tempStages);
            }
        }
        
        for (Id i : currentCasesMap.keyset()) {
            if (c3CscRecords.containsKey(currentCasesMap.get(i).CCC_External_Id__c)) {
                Double Order1;
                Double Order2;
                
                for (ASF_Case_Stage_Config__c csc : c3CscRecords.get(currentCasesMap.get(i).CCC_External_Id__c)) {
                    if (csc.StageName__c == newCasesMap.get(i).Stage__c) {
                        Order1 = csc.Order__c;
                    }
                    
                    if (csc.StageName__c == currentCasesMap.get(i).Stage__c) {
                        Order2 = csc.Order__c;
                    }
                }
                if (Order1 < Order2) {
                    caseBackMovementCheckMap.put(i, true);
                } else {
                    caseBackMovementCheckMap.put(i, false);
                }
            }
        }
        return caseBackMovementCheckMap;
    }
    
    public static Decimal calculateBusinessHoursPerDay(Id businesshourId){
        Decimal businessHoursPerDay = 9;
        
        for(BusinessHours BhRec : [SELECT Id, MondayStartTime, MondayEndTime FROM BusinessHours WHERE Id =: businesshourId]){
            Decimal startMinutes = BhRec.MondayStartTime.hour() * 60 + BhRec.MondayStartTime.minute();
            Decimal endMinutes = BhRec.MondayEndTime.hour() * 60 + BhRec.MondayEndTime.minute();
            Decimal hoursPerDay = (endMinutes - startMinutes) / 60; 
            
            if(hoursPerDay == 0){
                businessHoursPerDay = 24;     
            }else{
                businessHoursPerDay = hoursPerDay;
            }
        }
        return businessHoursPerDay;
    }
    
    public static Boolean updateOldCaseSLAHistory(List<Case> newCases){
        Set<Id> caseIdSet = new Set<Id>();
        Id businesshourId;
        Decimal businessHoursPerDay = 9;
        
        for(Case c:newCases){
            caseIdSet.add(c.Id);
            businesshourId = c.BusinessHoursId;
        }
        businessHoursPerDay = calculateBusinessHoursPerDay(businesshourId);
        
        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        //take running record and make it false
        if(!caseIdSet.isEmpty()){
            for(ASF_Case_SLA_History__c slaHistory :[SELECT Id, 
                                                     Current_Owner__c,
                                                     Level__c, 
                                                     Stage_End_Date__c, 
                                                     Stage_Start_Date__c,
                                                     BusinessHoursId__c, 
                                                     Case__c, Stage__c, 
                                                     Overdue__c, 
                                                     Status__c, 
                                                     Stage_Violation_Start_Date__c, 
                                                     Current_Owner_Id__c,
                                                     Case__r.Stage_SLA_1__c,
                                                     Case__r.Stage_SLA_2__c,
                                                     Case__r.Stage_SLA_3__c,
                                                     Breached_User_Level3__c,
                                                     Breached_User_Level2__c,
                                                     Breached_User_Level1__c,
                                                     SLA_3_Email_Sent__c, 
                                                     SLA_2_Email_Sent__c 
                                                     FROM  ASF_Case_SLA_History__c 
                                                     WHERE Case__c IN: caseIdSet 
                                                     AND is_Running_Record__c = TRUE
                                                     ORDER BY CreatedDate DESC]){
                                                         
                                                        if(slaHistory.Stage_End_Date__c == null){
                                                            slaHistory.Stage_End_Date__c = System.now();
                                                            slaHistory.is_Running_Record__c = false;
                                                            slaHistory.Actual_Time_Taken__c = ((slaHistory.Stage_End_Date__c).getTime() - (slaHistory.Stage_Start_Date__c).getTime())/3600000 ;
                                                            if(slaHistory.BusinessHoursId__c != null){
                                                                if(slaHistory.Stage_Violation_Start_Date__c != null){
                                                                    slaHistory.Overdue__c = BusinessHours.diff(slaHistory.BusinessHoursId__c, slaHistory.Stage_Violation_Start_Date__c, System.now())/(1000*60*60);
                                                                }
                                                                slaHistory.Time_Taken_In_Business_Hour__c = (BusinessHours.diff(slaHistory.BusinessHoursId__c, slaHistory.Stage_Start_Date__c, slaHistory.Stage_End_Date__c));
                                                                Long milliseconds = BusinessHours.diff(slaHistory.BusinessHoursId__c, slaHistory.Stage_Start_Date__c, slaHistory.Stage_End_Date__c);
                                                                
                                                                long seconds = milliseconds / 1000;
                                                                long minutes = seconds / 60;
                                                                long hours = minutes / 60;
                                                                Integer days = Integer.valueOf (Math.floor(hours / businessHoursPerDay));
                                                                if(days < 1){
                                                                    slaHistory.Time_Taken__c = ( Math.mod(hours, 24) + 'hr ' +  Math.mod(minutes, 60)  + 'min ' + Math.mod(seconds, 60)  )+'s';   
                                                                }else{
                                                                    slaHistory.Time_Taken__c = (days + 'days ' + Math.mod(hours, 24) + 'hr ' +  Math.mod(minutes, 60)  + 'min ' + Math.mod(seconds, 60) + 's '  ); 
                                                                }
                                                            }
                                                            slaHistoryList.add(slaHistory);
                                                        }
                                                     }
        }
        if (!slaHistoryList.isEmpty()) {
            update slaHistoryList;
            return true;
        }
        return false;
    }
    
    /*
    When Case owner changes or Stage Changes, 2 things Should Happen
    New row should be inserted in case History. 
    Old Row Should be updated with Running record = false and  end date should be populated.
    */
    
    public static void updateSLAHistory(map<Id, Case> oldCases,map<Id, Case> newCases){
        List<Case> modifiedCases= new List<Case>();
        Map<Id,Case> modifiednewCasesMap = new Map<Id,Case>();
        Map<Id,Case> modifiedoldCasesMap = new Map<Id,Case>(); 
        for(Case c : newCases.values() ){
            if(newCases.get(c.Id).SkipModifyingSLAHistory__c != oldCases.get(c.Id).SkipModifyingSLAHistory__c){
                //Change in this flag indicates internal case updates, which doesnt require SLA history evalutation/creation.
                continue;                
            }
            if(newCases.get(c.Id).OwnerId != oldCases.get(c.Id).OwnerId || 
            newCases.get(c.Id).Stage__c != oldCases.get(c.Id).Stage__c){
                modifiedCases.add(c);  
                modifiednewCasesMap.put(c.Id,c);  
                modifiedoldCasesMap.put(c.Id,oldCases.get(c.Id)); 
            }    
        }
        //send only cases which are modified with owners and Stages
        if(modifiedCases != null && modifiedCases.size() > 0 ){
            updateOldCaseSLAHistory(modifiedCases);
            insertSLAHistory(modifiedoldCasesMap,modifiednewCasesMap);
        }
    }

    /**
     * When cases are assigned to users from Omnichannel - case trigger is not invoked, hence SLA history is also not modified
     * As remedy, ASF_AgentWorkTrigger is implemented, which runs when Omnichannel assigns case to user(creates an entry on AgentWork object)
     * From that trigger, below method is invoked to update old SLA history and insert new one
     */
    public static void modifySLAHistoryOnOmnichannelAssignment(Map<Id, List<Id>> assignedUserIdToCaseIdsMap) {
        List<Case> cases = new List<Case>();
        Set<Id> allCaseIds = new Set<Id>();

        for(Id userId : assignedUserIdToCaseIdsMap.keySet()){
            allCaseIds.addAll(assignedUserIdToCaseIdsMap.get(userId));
        }
        for(Case caseRec : [Select Id, OwnerId, SkipModifyingSLAHistory__c, BusinessHoursId from Case where Id IN : allCaseIds]){
            caseRec.Last_Owner_Change_Date__c = System.now();
            cases.add(caseRec);
        }
        Map<Integer,ASF_SLABusinessHoursWrapper> resultMap = getCaseOwnerBusinessHours(null,cases);
        if(resultMap != null){
            Integer index = 0;
            for(Case updatedCase : cases){
                updatedCase.SLA_Target_1__c = null;
                updatedCase.SLA_Target_2__c = null;
                updatedCase.SLA_Target_3__c = null;
                ASF_SLABusinessHoursWrapper wrapper = resultMap.get(index);
                if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord != null){
                    if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager != null){
                        updatedCase.SLA_Target_1__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.email;
                    }
                    if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager != null){
                        updatedCase.SLA_Target_2__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.email;
                    }
                    if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager != null){
                        updatedCase.SLA_Target_3__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager.email;
                    }
                }
                index++;
            }
        }
        updateOldCaseSLAHistory(cases);
        ASF_CaseSLAHandlerV1.isFromOmniChannel = true;
        insertSLAHistory(null,new Map<Id, Case>(cases));
        ASF_CaseSLAHandlerV1.isFromOmniChannel = false;

        //update cases
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update cases;

    }

    /*
    When SLA is violated , SLA violated date gets carried over for calculation.
    There might be 3 history for Stages. If one is violated, take that for calculation.
    Hence you would see order by created asc. 
    Same with Start date also
    The intent of this method is to get for given stage , get total time spent , 
    last stage violated date and earlier start date.
    Very equal to summarizing by stage. 

    */
    
    private static map<String,ASF_SLAHistoryWraper> getCaseStageSummarizedView(map<Id,Case> newCases){
        
        map<String,ASF_SLAHistoryWraper> resultMap = new map<String,ASF_SLAHistoryWraper>();
        List<String> caseStagesStartDate = new List<String>();
        List<String> caseStagesViolatedDate = new List<String>();
        List<id> changedCaseList = new List<Id>();
        Long overallTimeSpent = 0;
        
        for(Case c : newCases.values()){
            changedCaseList.add(c.Id);
        }
        
        
        for (ASF_Case_SLA_History__c slaHistory : [SELECT Id, 
                                                   Current_Owner__c, 
                                                   Stage_Start_Date__c, 
                                                   Stage_End_Date__c, 
                                                   Case__c,
                                                   Case__r.Stage__c, 
                                                   Stage__c, Overdue__c, 
                                                   Status__c, 
                                                   Stage_Violation_Start_Date__c, 
                                                   Current_Owner_Id__c, 
                                                   BusinessHoursId__c 
                                                   FROM ASF_Case_SLA_History__c 
                                                   WHERE Case__c IN: changedCaseList
                                                   ORDER BY Case__c, Stage_Start_Date__c asc]) {
            //Loop through the loop get the stage to which case is going and calculate the time consumed in business hours
            if(slaHistory.BusinessHoursId__c != null){
                if(slaHistory.Stage__c == newCases.get(slaHistory.Case__c).Stage__c){
                    //get first stage and get Start Date of Stage 
                    if(!caseStagesStartDate.contains(slaHistory.Case__c + slaHistory.Case__r.Stage__c)){
                        if (!resultMap.containsKey(slaHistory.Case__c + slaHistory.Stage__c )){
                            ASF_SLAHistoryWraper c = new ASF_SLAHistoryWraper();
                            c.stageStartTime = slaHistory;
                            resultMap.put(slaHistory.Case__c + slaHistory.Stage__c,c);
                            caseStagesStartDate.add(slaHistory.Case__c + slaHistory.Case__r.Stage__c);
                        }
                    }
                    if(slaHistory.Stage_End_Date__c == null){
                        slaHistory.Stage_End_Date__c = system.now();
                    }
                    
                    long previousTimeSpent =  resultMap.get(slaHistory.Case__c+slaHistory.stage__c).totalTimeSpent;
                    Long stageConsumedMilliSeconds = BusinessHours.diff(slaHistory.BusinessHoursId__c, slaHistory.Stage_Start_Date__c, slaHistory.Stage_End_Date__c);
                    long totalConsumed = previousTimeSpent + stageConsumedMilliSeconds;
                    resultMap.get(slaHistory.Case__c+slaHistory.stage__c).totalTimeSpent = totalConsumed;
                    
                    

                    if(slaHistory.Stage_Violation_Start_Date__c != null && !caseStagesViolatedDate.contains(slaHistory.Case__c + slaHistory.Stage__c ) ){
                        ASF_SLAHistoryWraper r = resultMap.get(slaHistory.Case__c+slaHistory.Stage__c);
                        r.violatedTime = slaHistory;
                        caseStagesViolatedDate.add(slaHistory.Case__c + slaHistory.Case__r.Stage__c); 
                    }
                }
                //Overall - run for all slaHistories
                if(!resultMap.containsKey(slaHistory.Case__c+'overallTimeSpent')){
                    ASF_SLAHistoryWraper c = new ASF_SLAHistoryWraper();
                    resultMap.put(slaHistory.Case__c+'overallTimeSpent', c);
                }
                long currentOverallSpent =  resultMap.get(slaHistory.Case__c+'overallTimeSpent').totalTimeSpent;
                Datetime endDate = slaHistory.Stage_End_Date__c == null ? System.now() : slaHistory.Stage_End_Date__c;
                Long stageConsumedMilliSeconds = BusinessHours.diff(slaHistory.BusinessHoursId__c, slaHistory.Stage_Start_Date__c, endDate);
                currentOverallSpent += stageConsumedMilliSeconds;
                resultMap.get(slaHistory.Case__c+'overallTimeSpent').totalTimeSpent = currentOverallSpent;
            }
        }
        return resultMap;
    }
    
    /*
    Few fields needs to be reset. One dedicated method to populate values on Caes. 
    Business hrs is not pre populated here. Its lot more complex. That you will see in next methods
    */
    private static Case resetSLAFields(Case newCase, Case oldCase, Case updatedCase){
        //if(newCase.Stage__c == 'Closed' || newCase.Stage__c == 'Rejected'){
        if(ASF_Constants.CASECLOSEREJECTEDSTATUSES.contains(newCase.Stage__c)){
            // updatedCase.Stage_SLA_1__c = null;
            // updatedCase.Stage_SLA_2__c = null;
            // updatedCase.Stage_SLA_3__c = null;
        }
        else{
            //during insert old Case will be null
            if(oldCase == null){
                updatedCase.Case_Stage_Change_Date__c = system.now();
                updatedCase.Last_Owner_Change_Date__c = system.now();
            }else{
                if(newCase.Stage__c != oldCase.Stage__c || newCase.CCC_External_Id__c != oldCase.CCC_External_Id__c){
                    updatedCase.Case_Stage_Change_Date__c = system.now();
                }
                if(oldCase != null && oldCase.ownerId != newCase.ownerID){
                    updatedCase.Last_Owner_Change_Date__c = system.now();
                }
            }
        }
        return updatedCase;    
    }
    
    /*
    Case owner can be queue or User. If user , take it from Business Hrs field which is on User object.
    Each user can his own business hrs. 
    if its queue , on queue owner email is considered as owner. If there is business hrs for queue email,
    then take it. 
    If nothing there , take default business hrs
    */
    private static Map<Integer,ASF_SLABusinessHoursWrapper> getCaseOwnerBusinessHours(Map<Id,Case> oldCases, List<Case> newCases){
        Map<Integer,ASF_SLABusinessHoursWrapper> resultMap =  new map<Integer,ASF_SLABusinessHoursWrapper>();
        List<String> ownerUserList = new List<String>();
        List<String> ownerQueueList = new List<String>();
        Map<String,String> userBusinessHrMap = new Map<String,String>();
        List<String> ownerEmailList = new List<String>();
        
        for(case c: newCases){
            //owner change loop
            //Removed the below if conditions code to accomodate SLA Target stamping 
            //when converting from Interaction to framework    
            //if(oldCases == null || c.OwnerId != oldCases.get(c.id).OwnerId){
                if(string.valueOf(c.OwnerId).startsWith('005')){
                    ownerUserList.add(c.OwnerId); 
                }else if(string.valueOf(c.OwnerId).startsWith('00G')){
                    ownerQueueList.add(c.OwnerId);
                }
            //}
        }  
        Integer index = 0;
        for(Case c: newCases){
            ASF_SLABusinessHoursWrapper wrapper =new ASF_SLABusinessHoursWrapper();
            wrapper.caseObject = c;
            resultMap.put(index,wrapper);
            index++;
        }
        if(!ownerUserList.isEmpty() || !ownerQueueList.isEmpty()){
            resultMap = getOwnerHierarchy(newCases, ownerUserList, ownerQueueList);
        }
        return resultMap;
    }

    public static Map<Integer,ASF_SLABusinessHoursWrapper> getOwnerHierarchy(List<Case> newCases, List<String> ownerUserList, List<String> ownerQueueList) {
        Map<Integer,ASF_SLABusinessHoursWrapper> resultMap =  new map<Integer,ASF_SLABusinessHoursWrapper>();
        Map<String,String> queueEmailMap = new Map<String,String>();
        Map<String,String> queueOwnerUserBusinessHrMap = new Map<String,String>();
        map<String,User> userEmailMangerMap = new Map<String,User>();
        Map<Id, String> userIdToEmailMap = new Map<Id, String>();
        /* there are Cases which are owned by Queue. 
        When Case is owned by Queue , Owner of Queue email's business hrs is considered
        */
        if(!ownerQueueList.isEmpty()){
            for(Group ownerQueue : [SELECT Id, Email FROM Group WHERE Type = 'Queue' AND Id IN :ownerQueueList]){
                if(ownerQueue.Email != NULL){
                    queueEmailMap.put(ownerQueue.Id,ownerQueue.Email);
                    //take queue email as owner . in future when new object is configured to get queue emails, 
                    // lets pick there
                }
            }
        }
        for (User userObj : [SELECT Id, Business_Hour_Id__c,Email, manager.email,
                             manager.manager.email,
                             manager.manager.manager.email FROM User 
                             WHERE (Email IN: queueEmailMap.values() OR Id IN :ownerUserList) AND IsActive = true]) {
                                 if( userObj.Business_Hour_Id__c != NULL){
                                     queueOwnerUserBusinessHrMap.put(userObj.Email,userObj.Business_Hour_Id__c);
                                 }
                                 userEmailMangerMap.put(userObj.Email, userObj);
                                 userIdToEmailMap.put(userObj.Id, userObj.Email);
                             }
        
        
        Integer index = 0;
        for(Case c: newCases){
            ASF_SLABusinessHoursWrapper wrapper =new ASF_SLABusinessHoursWrapper();
            wrapper.caseObject = c;
            Id owner = c.ownerId;
            if(String.valueOf(owner).startsWith('005')){
                wrapper.ownerType = 'User';
                String emailid = userIdToEmailMap.get(c.ownerId);
                wrapper.caseUserOwnerBusinessHoursMap = queueOwnerUserBusinessHrMap.get(emailId);
                wrapper.ownerUserRecordorQueueOwnerEmailUserRecord =  userEmailMangerMap.get(emailId);     
            }
            else {
                wrapper.ownerType = 'Queue';
                String email1 = queueEmailMap.get(owner);
                wrapper.caseQueueOwnerBusinessHourMap = queueOwnerUserBusinessHrMap.get(email1);
                wrapper.ownerUserRecordorQueueOwnerEmailUserRecord =  userEmailMangerMap.get(email1);
            }
            
            resultMap.put(index,wrapper);
            index++;
        }     
        
        return resultMap;
    }
    
    /* call this on Case update.
    This should recaluclate SLA . Time remaining SLA should be calculated.
    */
    public static Map<Id, Case> calculateSLAOnCaseUpdate(map<Id, Case> newCases, map<Id, Case> oldCases){
        
        Set<string> externalIdList = new Set<String>();
        Set<string> caseNewStatusList = new Set<String>();
        List<Case> changedCaseList = new List<Case>();
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();
        ASF_CaseHistoryPercentageCalc percntCls = new ASF_CaseHistoryPercentageCalc();
        
        Boolean anyOwnerUpdate = false;
        Boolean anyStageUpdate = false;
        for(Id i: newCases.keyset()){
            //Stage Change Loop or change in external Id. Recategrize changes external Id
            if(oldCases.containsKey(i) &&
                (newCases.get(i).Stage__c != oldCases.get(i).Stage__c ||
                newCases.get(i).OwnerId != oldCases.get(i).OwnerId || 
                newCases.get(i).CCC_External_Id__c != oldCases.get(i).CCC_External_Id__c)){
                Case updatedCase = new Case(Id=newCases.get(i).Id,Case_Stage_Change_Date__c=newCases.get(i).Case_Stage_Change_Date__c);
                resetSLAFields(newCases.get(i),oldCases.get(i),updatedCase);
                casesToUpdate.put(newCases.get(i).Id, updatedCase);
                if(newCases.get(i).CCC_External_Id__c != null &&  (newCases.get(i).Stage__c != 'Closed' && newCases.get(i).Stage__c != 'Rejected' && newCases.get(i).Stage__c != 'Resolved' && newCases.get(i).Stage__c != 'Unresolved' && newCases.get(i).Stage__c != 'Duplicate')){
                    externalIdList.add(newCases.get(i).CCC_External_Id__c);    
                    caseNewStatusList.add(newCases.get(i).Stage__c);
                    changedCaseList.add(newCases.get(i)); 
                }
                if(newCases.get(i).Stage__c != oldCases.get(i).Stage__c){anyStageUpdate=true;}
                if(newCases.get(i).OwnerId != oldCases.get(i).OwnerId){anyOwnerUpdate=true;}
                if(newCases.get(i).CCC_External_Id__c != oldCases.get(i).CCC_External_Id__c){anyStageUpdate=true;anyOwnerUpdate=true;}
            }
        }
        
        if(!changedCaseList.isEmpty()){
            map<Integer,ASF_SLABusinessHoursWrapper> resultMap;
            if(anyOwnerUpdate){
                resultMap = getCaseOwnerBusinessHours(oldCases,changedCaseList);
            }
            //BusinessHours bh = [SELECT id FROM businesshours WHERE IsDefault=true LIMIT 1];
            
            Integer index = 0;
            if(!changedCaseList.isEmpty()){
                for(Case caseRec : changedCaseList){
                    Id caseId = caseRec.Id;
                    if(!casesToUpdate.containsKey(caseId)){
                        casesToUpdate.put(caseId, new Case(Id=caseId));
                    }
                    Case updatedCase = casesToUpdate.get(caseId);
                    updatedCase.BusinessHoursId  = caseRec.BusinessHoursId;
                    System.debug('BH'+updatedCase.BusinessHoursId);
                    //if(resultMap != null && resultMap.containsKey(index)){
                        //only if owner is changing , touch business hrs. else not need. 
                        /*  Stage change need not be owner change. Example : When stage is changed to approvalstage,
                        then ownership retains with previous ownrr. so owner change is not happenig.
                        Same with integration stages also.
                        Concept is , in parking stages , there is no owner change. but stage change.
                        owner change can be to user or queue. and then business hrs changes
                        */
                        // if(newCases.get(caseId).ownerId != oldCases.get(caseId).ownerId ){
                        //     if(String.valueOf(newCases.get(caseId).ownerId).startsWith('005')){
                        //         String userBusinessHrs = resultMap.get(index).caseUserOwnerBusinessHoursMap;
                        //         if(userBusinessHrs!=null){
                        //             updatedCase.BusinessHoursId = userBusinessHrs;
                        //             System.debug('BH'+updatedCase.BusinessHoursId);
                        //         } 
                        //     }
                        //     else {
                        //         String queueBusinessHrs = resultMap.get(index).caseQueueOwnerBusinessHourMap;
                        //         if(queueBusinessHrs!=null){
                        //             updatedCase.BusinessHoursId = queueBusinessHrs;
                        //             System.debug('BH'+updatedCase.BusinessHoursId);
                        //         }
                        //     }
                        // }
                    //}
                    index++;
                }
            }

            ASF_SLAWrapper slaObject;
            Map<String,ASF_SLAHistoryWraper> caseStageSummarizedViewMap = new Map<String,ASF_SLAHistoryWraper>();
            if(anyStageUpdate){
                slaObject = prepareSLAConfigMap(externalIdList,caseNewStatusList);
                //map<string,ASF_Case_Stage_Config__c> externalIdStageNameCaseStageConfigMap = slaObject.externalIdStageNameCaseStageConfigMap;
                
                caseStageSummarizedViewMap = getCaseStageSummarizedView(newCases);
                System.debug('caseStageSummarizedViewMap'+caseStageSummarizedViewMap);
            }
            index = 0;
            for(Case caseRec : changedCaseList){
                Id i = caseRec.Id;
                if(!casesToUpdate.containsKey(caseRec.Id)){
                    casesToUpdate.put(caseRec.Id, new Case(Id=caseRec.Id));
                }
                Case updatedCase = casesToUpdate.get(caseRec.Id);
                string mapKey = newCases.get(i).CCC_External_Id__c + newCases.get(i).Stage__c;

                Long sla1Sec;
                long sla2Sec;
                long sla3Sec;
                long closeSlaSec;
                if(slaObject != null){
                    map<string,long> slaMap = getSLAFieldValues(slaObject,newCases.get(i),oldCases.get(i));
                    
                    sla1Sec = slaMap.get('sla1');
                    sla2Sec = slaMap.get('sla2');
                    sla3Sec = slaMap.get('sla3');
                    closeSlaSec = slaMap.get('caseClosureSLA');
                }
                long slaIdentifier = 3600000;
                //If the overallsla is not configured, empty the field
                //if(closeSlaSec == null){
                  //  updatedCase.Overall_Case_Closure_SLA__c = null;
                  //  updatedCase.Overall_SLA_plus_X_days__c = null;
                  //  updatedCase.Case_SLA_Threshold_1__c = null;
                  //  updatedCase.Case_SLA_Threshold_2__c = null;
                  //  updatedCase.Case_SLA_Threshold_3__c = null;
                //}

                if(oldCases.get(caseRec.id).CCC_External_Id__c != newCases.get(caseRec.id).CCC_External_Id__c ){
                    //If the overallsla is not configured, empty the field
                    if(closeSlaSec == null){
                        updatedCase.Overall_Case_Closure_SLA__c = null;
                        updatedCase.Overall_SLA_plus_X_days__c = null;
                        updatedCase.Case_SLA_Threshold_1__c = null;
                        updatedCase.Case_SLA_Threshold_2__c = null;
                        updatedCase.Case_SLA_Threshold_3__c = null;
                    }
                    //If the stage sla are not configured, empty the field
                    if(sla1Sec == null){
                        updatedCase.Stage_SLA_1__c = null;
                    } 
                    if(sla2Sec == null){
                        updatedCase.Stage_SLA_2__c = null;
                    }
                    if(sla3Sec == null){
                        updatedCase.Stage_SLA_3__c = null;
                    }
                    if(closeSlaSec != null){
                        //When case is recategorizzed. Take difference between Case created date.
                        //this is slightly different during case insert where we take systemnow
                        //when external id is changed , case can get changed after 2 days , so take 
                        //created date,.
                        updatedCase.Overall_Case_Closure_SLA__c =BusinessHours.add(updatedCase.BusinessHoursId, caseRec.CreatedDate, closeSlaSec);
                        if(ASF_RecategoriseCaseController.requestFromRecat == true && updatedCase.Overall_Case_Closure_SLA__c <= system.now()){
                            updatedCase.SLA_Broken__c = true;
                            updatedCase.SLA_Broken_DateTime__c = System.now();
                        }
                    }
                }

                // updatedCase.Stage_SLA_1__c = null; 
                // updatedCase.Stage_SLA_2__c = null; 
                // updatedCase.Stage_SLA_3__c = null; 
                String businessHrsusedForcalcuation ; 
                
                //owner change or Stage change . enter
                if(caseStageSummarizedViewMap.isEmpty() 
                || !caseStageSummarizedViewMap.containsKey(i + newCases.get(i).Stage__c)
                || (sla1Sec != null && caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).totalTimeSpent < sla1Sec)){
                    if(newCases.get(i).Stage__c != oldCases.get(i).Stage__c 
                    || newCases.get(i).CCC_External_Id__c != oldCases.get(i).CCC_External_Id__c  ){
                    // if(newCases.get(i).OwnerId != oldCases.get(i).OwnerId){
                    //    if(String.valueOf(newCases.get(i).ownerId).startsWith('005')){
                    //        businessHrsusedForcalcuation = resultMap.get(index).caseUserOwnerBusinessHoursMap;
                    //        System.debug('BH'+businessHrsusedForcalcuation);
                    //    }else{
                    //        businessHrsusedForcalcuation = resultMap.get(index).caseQueueOwnerBusinessHourMap;
                    //        System.debug('BH'+businessHrsusedForcalcuation);
                    //    }
                    // } 
                    // else {
                    //     businessHrsusedForcalcuation = newCases.get(i).BusinessHoursId;
                    //     System.debug('BH'+businessHrsusedForcalcuation);
                    // }
                    // if(businessHrsusedForcalcuation == null){
                    //     businessHrsusedForcalcuation = newCases.get(i).BusinessHoursId;
                    // }
                        String timeSpent = '0';
                        long timeSpentInLong = 0;
                        long overallTimeSpent = 0;
                        if(caseStageSummarizedViewMap.containsKey(i + newCases.get(i).Stage__c) 
                            && sla1Sec != null && caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).totalTimeSpent < sla1Sec){
                                timeSpent = string.valueOf(caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).totalTimeSpent/1000).substringBefore('.');
                                timeSpentInLong = caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).totalTimeSpent == null?0:
                                caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).totalTimeSpent;
                            }
                        if(caseStageSummarizedViewMap.containsKey(caseRec.Id+'overallTimeSpent')){
                            overallTimeSpent = caseStageSummarizedViewMap.get(caseRec.Id+'overallTimeSpent').totalTimeSpent;
                        }
                        if(closeSlaSec != null){
                            updatedCase.Overall_Case_Closure_SLA__c = BusinessHours.add(updatedCase.BusinessHoursId,updatedCase.Case_Stage_Change_Date__c, closeSlaSec - overallTimeSpent);
                            if(ASF_RecategoriseCaseController.requestFromRecat == true && updatedCase.Overall_Case_Closure_SLA__c <= system.now()){
                                updatedCase.SLA_Broken__c = true;
                                updatedCase.SLA_Broken_DateTime__c = System.now();
                            }
                            percntCls.setOverallPercSLAFields(closeSlaSec,updatedCase.BusinessHoursId,updatedCase.Case_Stage_Change_Date__c.addSeconds(- Integer.valueOf(overallTimeSpent)),updatedCase);
                        }
                        updatedCase.Stage_SLA_1__c = null;
                        updatedCase.Stage_SLA_2__c = null;
                        updatedCase.Stage_SLA_3__c = null;
                        if(sla1Sec != null){
                            updatedCase.Stage_SLA_1__c = BusinessHours.add(updatedCase.BusinessHoursId, updatedCase.Case_Stage_Change_Date__c, (sla1Sec - timeSpentInLong));
                            percntCls.setStagePercSLAFields(sla1Sec,updatedCase.BusinessHoursId,updatedCase.Case_Stage_Change_Date__c.addSeconds(- Integer.valueOf(timeSpent!=null?timeSpent:'0')),updatedCase);
                        } 
                        if(sla2Sec != null){
                            updatedCase.Stage_SLA_2__c = BusinessHours.add(updatedCase.BusinessHoursId, updatedCase.Case_Stage_Change_Date__c, (sla2Sec - timeSpentInLong));
                        }
                        if(sla3Sec != null){
                            updatedCase.Stage_SLA_3__c = BusinessHours.add(updatedCase.BusinessHoursId, updatedCase.Case_Stage_Change_Date__c, (sla3Sec - timeSpentInLong));
                        }      
                    }
                }
                //Loop to check if the Case Id + Stage__c consumed is more than SLA 1
                else if(sla1Sec != null && caseStageSummarizedViewMap.containsKey(i + newCases.get(i).Stage__c) && caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).totalTimeSpent > sla1Sec){
                    if(caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).violatedTime != null){
                        updatedCase.Stage_SLA_1__c = null;
                        //On SLA 1 get the Violation Date Time populated when SLA 1 is breached through flow
                        updatedCase.Stage_SLA_1__c = caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).violatedTime.Stage_Violation_Start_Date__c ;
                        percntCls.setStagePercSLAFields(sla1Sec,caseStageSummarizedViewMap.get(i + newCases.get(i).Stage__c).violatedTime.BusinessHoursId__c,newCases.get(i).Stage_SLA_1__c,updatedCase);
                        if(sla2Sec == null){
                            updatedCase.Stage_SLA_2__c = null;
                        }
                        if(sla3Sec == null){
                            updatedCase.Stage_SLA_3__c = null;
                        }
                        //To check if stage is same and owner is changed
                        if(sla2Sec != null && sla3Sec != null){
                            // string businessHrsusedForcalcuation1 = resultMap.get(index).caseUserOwnerBusinessHoursMap;
                            // if (businessHrsusedForcalcuation1 == null){
                            //     businessHrsusedForcalcuation1 = bh.id; 
                            // }
                            if(sla2Sec != null){
                                updatedCase.Stage_SLA_2__c = BusinessHours.add(updatedCase.BusinessHoursId, newCases.get(i).Stage_SLA_1__c, (sla2Sec - sla1Sec));
                            }
                            if(sla3Sec != null){
                                updatedCase.Stage_SLA_3__c = BusinessHours.add(updatedCase.BusinessHoursId, newCases.get(i).Stage_SLA_1__c, (sla3Sec - sla1Sec));
                            } 
                        }
                        else if(newCases.get(i).Stage__c != oldCases.get(i).Stage__c){
                            if(sla2Sec != null){
                                updatedCase.Stage_SLA_2__c = BusinessHours.add(updatedCase.BusinessHoursId, newCases.get(i).Stage_SLA_1__c, (sla2Sec - sla1Sec));
                            }
                            if(sla3Sec != null){
                                updatedCase.Stage_SLA_3__c = BusinessHours.add(updatedCase.BusinessHoursId, newCases.get(i).Stage_SLA_1__c, (sla3Sec - sla1Sec));
                            }
                        }
                    }
                }
                else{
                    //redundant code
                    // if(newCases.get(i).Stage__c != oldCases.get(i).Stage__c || newCases.get(i).OwnerId != oldCases.get(i).OwnerId ){
                    //     if(newCases.get(i).OwnerId != oldCases.get(i).OwnerId){
                    //         businessHrsusedForcalcuation = resultMap.get(index).caseUserOwnerBusinessHoursMap;
                    //     } 
                    //     else {
                    //         businessHrsusedForcalcuation = newCases.get(i).BusinessHoursId;
                    //     }
                    
                    //     if(sla1Sec != null){
                    //         newCases.get(i).Stage_SLA_1__c = BusinessHours.add(businessHrsusedForcalcuation, newCases.get(i).Case_Stage_Change_Date__c, sla1Sec);
                    //         percntCls.setStagePercSLAFields(sla1Sec,businessHrsusedForcalcuation,newCases.get(i).Case_Stage_Change_Date__c,newCases.get(i));
                    //     } 
                    //     if(sla2Sec != null){
                    //         newCases.get(i).Stage_SLA_2__c = BusinessHours.add(businessHrsusedForcalcuation, newCases.get(i).Case_Stage_Change_Date__c, sla2Sec);
                    //     }
                    //     if(sla3Sec != null){
                    //         newCases.get(i).Stage_SLA_3__c = BusinessHours.add(businessHrsusedForcalcuation, newCases.get(i).Case_Stage_Change_Date__c, sla3Sec);   
                    //     }      
                    // }
                }
                if(resultMap != null){
                    updatedCase.SLA_Target_1__c = null;
                    updatedCase.SLA_Target_2__c = null;
                    updatedCase.SLA_Target_3__c = null;
                    ASF_SLABusinessHoursWrapper wrapper = resultMap.get(index);
                    if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord != null){
                        if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager != null){
                            updatedCase.SLA_Target_1__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.email;
                        }
                        if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager != null){
                            updatedCase.SLA_Target_2__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.email;
                        }
                        if(wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager != null){
                            updatedCase.SLA_Target_3__c = wrapper.ownerUserRecordorQueueOwnerEmailUserRecord.manager.manager.manager.email;
                        }
                    }
                }
                index++;
            }
        }

        return casesToUpdate;
    }    
}