/*********************************************************
 *Class        :  ABSLAMC_BusinessLogic_HelperClass
 *Author       :  Udit Singhal
 *Created Date :  02/09/2024
 *Description  :  ABSLAMC Business Logic class
 *********************************************************/

public class ABSLAMC_BusinessLogic_HelperClass {

    /****************************************************************************************************************
     * @Function - prePopulateFieldsBeforeInsert
     * @param - newLeadMap
     * @return - void
     * @Description - auto populate fields on lead in before insert context
     ***********************************************************/
    public static void prePopulateFieldsBeforeInsert(List<Lead> newLeadList) {
        Map<Id, Lead> abslamcLeadMap = new Map<Id, Lead>();
        Integer num = 1;
        //creating dummy Lead Id
        Id counter = '00Q'+'0'.repeat(12-String.valueOf(num).length())+String.valueOf(num);
        List<User> userList = [SELECT Id, LOB__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        for (Lead leadRecord : newLeadList){
            if (leadRecord.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU){
                if(String.isNotBlank(userList[0].LOB__c)) {
                    leadRecord.Line_Of_Business__c = userList[0].LOB__c.split(';')[0]; //populate Line_Of_Business__c field
                }
                abslamcLeadMap.put(counter, leadRecord);
                num+=1;
                counter = '00Q'+'0'.repeat(12-String.valueOf(num).length())+String.valueOf(num);
            }
        }

        if(abslamcLeadMap.size() > 0 ) {
            populateAssignedTeam(abslamcLeadMap); //populate queue name if the owner is ever a queue
            populateFieldsFromLeadMetadata(abslamcLeadMap);
        }
    }

    /****************************************************************************************************************
     * @Function - prePopulateFieldsBeforeUpdate
     * @param - newLeadMap
     * @param - oldLeadMap
     * @return - void
     * @Description - auto populate fields on lead in before update context
     ***********************************************************/
    public static void prePopulateFieldsBeforeUpdate(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap) {
        Map<Id, Lead> abslamcLeadToBeUpdatedFromMetadataMap = new Map<Id, Lead>(); //Map of leads to be updated from lead metadata
        Map<Id, Lead> abslamcLeadToUpdateAssignedTeamMap = new Map<Id, Lead>(); //Map of leads where assigned team field needs to be updated

        for (Lead leadRecord : newLeadMap.values()){
            if (leadRecord.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU){
                //populate Lead Status Change date field
                if(leadRecord.Status != oldLeadMap.get(leadRecord.Id).Status) {
                    leadRecord.Lead_Status_Change_date__c = System.now();
                }
                //populate queue name if the owner is a queue
                if(leadRecord.OwnerId != oldLeadMap.get(leadRecord.Id).OwnerId && ((String)leadRecord.OwnerId).startsWithIgnoreCase('00G')) {
                    abslamcLeadToUpdateAssignedTeamMap.put(leadRecord.Id, leadRecord);
                }
                //Sync values with lead metadata on type/subtype change
                if(leadRecord.Lead_Type__c != oldLeadMap.get(leadRecord.Id).Lead_Type__c || leadRecord.Lead_Subtype__c != oldLeadMap.get(leadRecord.Id).Lead_Subtype__c) {
                    abslamcLeadToBeUpdatedFromMetadataMap.put(leadRecord.Id, leadRecord);
                }
            }
        }

        if(abslamcLeadToUpdateAssignedTeamMap.size() > 0) {
            populateAssignedTeam(abslamcLeadToUpdateAssignedTeamMap);
        }

        if(abslamcLeadToBeUpdatedFromMetadataMap.size() > 0) {
            populateFieldsFromLeadMetadata(abslamcLeadToBeUpdatedFromMetadataMap);
        }
    }

    /****************************************************************************************************************
     * @Function - populateAssignedTeam
     * @param - newLeadMap
     * @return - void
     * @Description - populate queue name if the owner is ever a queue
     ***********************************************************/
    public static void populateAssignedTeam(Map<Id, Lead> newLeadMap) {
        Set<Id> queueIdSet = new Set<Id>();

        for (Lead leadRecord : newLeadMap.values()) {
            queueIdSet.add(leadRecord.OwnerId);
        }

        Map<Id, Group> queueIdToRecordMap = new Map<Id, Group>([SELECT Id, Name FROM Group WHERE TYPE = 'Queue' AND Id IN :queueIdSet]);

        for (Lead leadRecord : newLeadMap.values()) {
            leadRecord.Assigned_Team__c = queueIdToRecordMap.get(leadRecord.OwnerId)?.Name;
        }

    }

    /****************************************************************************************************************
     * @Function - populateFieldsFromLeadMetadata
     * @param - newLeadMap
     * @return - void
     * @Description - auto populate fields on lead from lead conversion metadata
     ***********************************************************/
    public static void populateFieldsFromLeadMetadata(Map<Id, Lead> newLeadMap) {
        List<ASF_Lead_Conversion_Metadata__mdt> leadMetadataList = [SELECT Id, Business_Unit__c, LOB__c, Lead_Type__c, Lead_Subtype__c, Track_conversion__c, Auto_Won_Days_Buffer__c FROM ASF_Lead_Conversion_Metadata__mdt WHERE Business_Unit__c =:ABSLAMC_Constants.ABSLAMCBU];
        if(leadMetadataList.size() > 0) {
            Map<String, ASF_Lead_Conversion_Metadata__mdt> typeSubtypeKeyToLeadMetadataMap = new Map<String, ASF_Lead_Conversion_Metadata__mdt>();
            
            for (ASF_Lead_Conversion_Metadata__mdt metadataRecord : leadMetadataList) {
                String key = metadataRecord.LOB__c + '|' + metadataRecord.Lead_Type__c + '|' + metadataRecord.Lead_Subtype__c;
                typeSubtypeKeyToLeadMetadataMap.put(key, metadataRecord);
            }
            for (Lead leadRecord : newLeadMap.values()){
                String leadKey = leadRecord.LOB__c + '|' + leadRecord.Lead_Type__c + '|' + leadRecord.Lead_Subtype__c;
                if (typeSubtypeKeyToLeadMetadataMap.containsKey(leadKey)) {
                    leadRecord.Is_Conversion_Tracked__c = typeSubtypeKeyToLeadMetadataMap.get(leadKey).Track_conversion__c; //populate Is_Conversion_Tracked__c field
                    Integer autoWonDaysBuffer = typeSubtypeKeyToLeadMetadataMap.get(leadKey).Auto_Won_Days_Buffer__c != null ? (Integer)typeSubtypeKeyToLeadMetadataMap.get(leadKey).Auto_Won_Days_Buffer__c : 0;
                    leadRecord.Auto_Won_Update_Datetime__c = Trigger.isInsert ? System.now().addDays(autoWonDaysBuffer) : leadRecord.CreatedDate.addDays(autoWonDaysBuffer); //populate Auto_Won_Update_Datetime__c field
                }
            }
            
        }
    }

    /****************************************************************************************************************
     * @Function - closeEligibleLeads
     * @param - newConversionDetailsMap
     * @return - void
     * @Description - close related lead records if the any of the Conversion_Details__c record has Converted_Flag__c as true
     ***********************************************************/
    public static void closeEligibleLeads(Map<Id, Conversion_Details__c> newConversionDetailsMap) {
        Set<Id> eligibleLeadsSet = new Set<Id>();
        Map<Id, Lead> leasdsToUpdateMap = new Map<Id, Lead>();

        for(Conversion_Details__c conversionDetailRecord :newConversionDetailsMap.values()) {
            if(conversionDetailRecord.Business_Unit__c == 'ABSLAMC' && conversionDetailRecord.Converted_Flag__c == true) {
                eligibleLeadsSet.add(conversionDetailRecord.Lead__c);
            }
        }

        if(eligibleLeadsSet.size() > 0) {
            for(Id leadId :eligibleLeadsSet) {
                Lead leadRecord = new Lead();
                leadRecord.Id = leadId;
                leadRecord.Status = 'Won';
                leasdsToUpdateMap.put(leadRecord.Id, leadRecord);
            }
        }

        if(leasdsToUpdateMap.size() > 0){
            update leasdsToUpdateMap.values();
        }
    }
    /****************************************************************************************************************
     * @Function - validateLeadOwnerChange
     * @param - newLeadMap
     * @param - oldLeadMap
     * @return - void
     * @Description - allows lead owner to be changed only for 
                     1)Current User is the owner of the lead
                     2)Current User is the manager of the lead owner upto 5 levels
                     3)Current User is member of the queue, when Lead is assigned to a queue previously
     *****************************************************************************************************************/ 
    public static void validateLeadOwnerChange(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        
      String userProfile = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
      if (userProfile ==  ABSLAMC_Constants.ADMINUSERPROILENAME || userProfile == ABSLAMC_Constants.APIUSERPROILENAME) {
           return;
       }
        
        Set<Id> userIds = new Set<Id>();
        Set<Id> queueGroupIds = new Set<Id>();
        for (Lead lead : newLeadMap.values()) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.OwnerId != oldLead.OwnerId) {
                userIds.add(lead.OwnerId);
                
                 if (!String.valueOf(oldLead.OwnerId).startsWith('00G')) {
                      userIds.add(oldLead.OwnerId);
                 } else {
                     queueGroupIds.add(oldLead.OwnerId);
                 }
            }
        }
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, ManagerId FROM User WHERE Id IN :userIds]);
        Map<Id, Group> queueGroupMap = new Map<Id, Group>([SELECT Id, Type FROM Group WHERE Id IN :queueGroupIds]);
        
        for (Lead lead : newLeadMap.values()) {
            Lead oldLead = oldLeadMap.get(lead.Id);
             if (lead.OwnerId != oldLead.OwnerId) {
                User newUser = userMap.get(lead.OwnerId);
                User oldUser = userMap.get(oldLead.OwnerId);
                Boolean isAuthorized = false;
                if (oldUser != null) {
                    Set<Id> managerIds = new Set<Id>();
                    Id managerId = oldUser.ManagerId;
                    for (Integer level = 0; level < 5 && managerId != null; level++) {
                        managerIds.add(managerId);
                        managerId = userMap.get(managerId) != null ? userMap.get(managerId).ManagerId : null;
                    }
                    if (oldLead.OwnerId == UserInfo.getUserId() || managerIds.contains(UserInfo.getUserId())) {
                        isAuthorized = true;
                    }
                    if (!isAuthorized) {
                        system.debug('ainside if not authroized');
                        lead.addError(ABSLAMC_Constants.LEADOWNERCHANGEFORUSER);
                    }
                }
                if (String.valueOf(oldLead.OwnerId).startsWith('00G')) {
                    Group oldOwnerGroup = queueGroupMap.get(oldLead.OwnerId);
                    Set<Id> memberIds = new Set<Id>();
                    List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :oldOwnerGroup.Id];
                    for (GroupMember gm : groupMembers) {
                        memberIds.add(gm.UserOrGroupId);
                    }
                    if (!memberIds.contains(lead.OwnerId)) {
                        lead.addError(ABSLAMC_Constants.LEADOWNERCHANGEFORQUEUE);
                    }
                }
                }
            }
        }
    }