/*********************************************************
*Class        :  ABSLAMC_SprinklrHelper
*Author       :  Neeraj Kumar
*Created Date :  07/10/2024
*@description  :  This class is for creating case comments and firing update api call for Sprinklr Cases in ABSLAMC
*********************************************************/

public class ABSLAMC_SprinklrHelper {
    public static List<CaseComment> caseCommentsToInsert = new List<CaseComment>();
    public static List<Case> callSprinklrUpdateAPICases = new List<Case>();
    
    /****************************************************************************************************************
* @param newMapCase,oldMapCase
* @description - for creating case comments based on latest notes for sprinklr/ updated notes for sprinklr
*****************************************************************************************************************/
    
    public static void createCaseComments(Map<Id,Case> newMapCase,Map<Id,Case> oldMapCase){
        String currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        boolean apiUser = true;
        apiUser = (currentUserProfileName == ABSLAMC_Constants.APIUSERPROILENAME) ? true : false;
        
        Map<Id,Case> fireNotificationCases = new Map<Id,Case>();
        for(Case caseRec:newMapCase.values()){
            if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU
               && caseRec.Source__c == 'Social Media'){
                   Case newCase = newMapCase.get(caseRec.Id);
                   Case oldCase = oldMapCase.get(caseRec.Id); 
                   if(String.isNotBlank(newCase.Notes_from_Sprinklr__c) && newCase.Notes_from_Sprinklr__c != oldCase.Notes_from_Sprinklr__c
                      && apiUser){
                          CaseComment cc = new CaseComment(
                              ParentId = newCase.Id,
                              CommentBody = newCase.Notes_from_Sprinklr__c
                          );
                          fireNotificationCases.put(newCase.Id,newCase);
                          caseCommentsToInsert.add(cc);
                      }
                   
               }
        }
        if (!caseCommentsToInsert.isEmpty()) {
            insert caseCommentsToInsert;
        }
        
        if(!callSprinklrUpdateAPICases.isEmpty()){
            callUpdateSprinklrAPI(callSprinklrUpdateAPICases);
        }
        if(!fireNotificationCases.isEmpty()){
            fireSystemNotification(fireNotificationCases,'Notes update'); 
        }
    }
    
    /****************************************************************************************************************
* @param newMapCase,oldMapCase
* @description - for triggering updateSprinklr flow based on latest notes for sprinklr/ updated notes for sprinklr
*****************************************************************************************************************/
    
    public static Map<Id, ASF_IntegrationsController.IntegrationWrapper> callUpdateSprinklrAPI(List<Case> caseMap) {
        Set<String> externalIds = new Set<String>();
        Set<Id> caseStageconfigIds = new Set<Id>();
        Map<Id, Id> stageConfigToCaseMap = new Map<Id, Id>();
        Map<Id, List<ASF_Integration__c>> integRecs = new Map<Id, List<ASF_Integration__c>>();
        
        for (Case caseRec : caseMap) {
            externalIds.add(caseRec.CCC_External_Id__c);
        }
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);
        for (ASF_Case_Stage_Config__c csc : allStageConfigs) {
            for (Case caseRec : caseMap) {
                if (caseRec.CCC_External_Id__c == csc.Case_Category_Config__r.CCC_External_Id__c && caseRec.Stage__c == csc.StageName__c) {
                    stageConfigToCaseMap.put(csc.Id, caseRec.Id);
                    caseStageconfigIds.add(csc.Id);
                    break;  
                }
            }
        }
        List<ASF_Integration__c> asfIntegRecs = [SELECT Id, External_Id__c, Display_Name__c, Case_Stage_Config__c, C3ExternalId__c,Query_Fields__c, Processing_Class__c 
                                                 FROM ASF_Integration__c
                                                 WHERE Display_Name__c = 'Sprinklr-UpdateFlow'
                                                 AND Case_Stage_Config__c = :caseStageconfigIds
                                                 WITH SYSTEM_MODE];
        for (ASF_Integration__c integ : asfIntegRecs) {
            Id caseId = stageConfigToCaseMap.get(integ.Case_Stage_Config__c);
            if (caseId != null) {
                if (!integRecs.containsKey(caseId)) {
                    integRecs.put(caseId, new List<ASF_Integration__c>());
                }
                integRecs.get(caseId).add(integ);
            }
        }
        
        Map<Id, ASF_IntegrationsController.IntegrationWrapper>  mapOfIntWrapper = ASF_IntegrationsController.runIntegration(integRecs, caseMap); 
        return mapOfIntWrapper;
    } 
    
    /****************************************************************************************************************
* @param newMapCase,oldMapCase
* @description - for firing  system notification
*****************************************************************************************************************/
    
    public static void fireSystemNotification(Map<Id, Case> caseMap,string process) {
        
        List<Messaging.CustomNotification> notificationList = new List<Messaging.CustomNotification>();
        Set<String> recipientsIds = new Set<String>();
        String notificationBody = '';
        
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Case_BackStage_Change'];
        
        for (Case caseRecord : caseMap.values()) {
            
            if (caseRecord.OwnerId != null) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Updates from Sprinklr');
                if(process == 'File Upload' ){
                    notificationBody = ABSLAMC_Constants.SPRINKLRFILENOTIF+': '+caseRecord.CaseNumber;
                } else if(process == 'Notes update'){
                    notificationBody = ABSLAMC_Constants.SPRINKLRNOTESNOTIF+': '+caseRecord.CaseNumber;
                }
                notification.setBody(notificationBody);
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(caseRecord.Id);
                recipientsIds.add(caseRecord.OwnerId);
                notificationList.add(notification);
            }
        }
        for(Messaging.CustomNotification notif: notificationList){
            notif.send(recipientsIds);
        }
    }
    
    /****************************************************************************************************************
* @param newMapCase,oldMapCase
* @description - for blanking out the Latest_Notes__c field after creation of cae comments
*****************************************************************************************************************/
    
    public static void blankOutLatestNotes(Map<Id,Case> newMapCase,Map<Id,Case> oldMapCase){
        for(Case caseRec:newMapCase.values()){
            if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU
               && caseRec.Source__c == 'Social Media'){
                   case newCase = newMapCase.get(caseRec.Id);
                   case oldCase = oldMapCase.get(caseRec.Id);
                   if(String.isNotBlank(newCase.Latest_Notes__c) && newCase.Latest_Notes__c != oldCase.Latest_Notes__c){
                       CaseComment cc = new CaseComment(
                           ParentId = newCase.Id,
                           CommentBody = newCase.Latest_Notes__c
                       ); 
                       caseCommentsToInsert.add(cc);
                       if(newCase.Stage__c == oldCase.Stage__c){
                           callSprinklrUpdateAPICases.add(newCase.clone(True,True,True,True));
                       }
                       ABSLAMC_UpdatesForSprinklr.caseLatestNotesMap.clear();
                       ABSLAMC_UpdatesForSprinklr.caseLatestNotesMap.put(newCase.Id, newCase.Latest_Notes__c);
                       newCase.Latest_Notes__c = '';
                   }
                   
               }
        }
    }
    
}