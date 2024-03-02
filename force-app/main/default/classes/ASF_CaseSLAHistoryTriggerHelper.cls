/*********************************************************
*Name           :   CaseSLAHistoryTriggerHelper
*Author         :   Salesforce
*Description    :   Helper Class which updates CaseSLAHistory when Current_Owner__c is populated with User
*Test Class     :	CaseSLAHistoryTriggerHelperTest

*********************************************************/
public without sharing class ASF_CaseSLAHistoryTriggerHelper {
    
    public static void populateSLAUserDEtails(List<ASF_Case_SLA_History__c> slaRecords){
        Set<Id> currentUserIdSet = new Set<Id>();
        Map<ID, User> userDetails= new Map<ID, User>();
        Set<Id> caseIds = new Set<Id>();
        
        for(ASF_Case_SLA_History__c csla : slaRecords){
            if(String.isNotBlank(csla.Current_Owner_Id__c) && (csla.Current_Owner_Id__c.startsWith('005'))){
                currentUserIdSet.add(Id.valueOf(csla.Current_Owner_Id__c));
                caseIds.add(csla.Case__c);
            }
        }

        if(currentUserIdSet.isEmpty())
            return;

        List<User> userList = [SELECT Id,Business_Unit__c, CC__c, LOB__c, LOC__c From User WHERE id =: currentUserIdSet];
        userDetails.putall(userList);

        Map<String, list<String>> existingDeptNamesByCase = new Map<String, list<String>>();
        Map<String, list<String>> existingCCNamesByCase = new Map<String, list<String>>();

        for(ASF_Case_SLA_History__c csla : [select Case__c, Agent_LOB__c, Agent_LOC__c, Agent_CC__c from ASF_Case_SLA_History__c where Case__c in: caseIds]){
            if(existingDeptNamesByCase.containsKey(csla.Case__c))
            	existingDeptNamesByCase.get(csla.Case__c).add(csla.Agent_LOB__c + csla.Agent_LOC__c);
            else
                existingDeptNamesByCase.put(csla.Case__c, new String[]{csla.Agent_LOB__c + csla.Agent_LOC__c});
            
            if(existingCCNamesByCase.containsKey(csla.Case__c))
            	existingCCNamesByCase.get(csla.Case__c).add(csla.Agent_CC__c);
            else
                existingCCNamesByCase.put(csla.Case__c, new String[]{csla.Agent_CC__c});
        }
        
        for(ASF_Case_SLA_History__c csla : slaRecords){
            if(String.isNotBlank(csla.Current_Owner_Id__c) && (csla.Current_Owner_Id__c.startsWith('005'))){
                User newAgent = userDetails.get(Id.valueOf(csla.Current_Owner_Id__c));

                csla.Agent__c = csla.Current_Owner_Id__c;
                //csla.SLA_LOB__c  = newAgent.LOB__c;
                csla.SLA_LOB__c  = newAgent.Business_Unit__c;
                csla.SLA_LOC__c  = newAgent.LOC__c;
                csla.SLA_CC__c   = newAgent.CC__c;            
                
                if(!existingDeptNamesByCase.containsKey(csla.Case__c) || !existingDeptNamesByCase.get(csla.Case__c)?.contains(newAgent.Business_Unit__c + newAgent.LOC__c)){
                    //csla.Agent_LOB__c  = newAgent.LOB__c;
                    csla.Agent_LOB__c  = newAgent.Business_Unit__c;
                    csla.Agent_LOC__c  = newAgent.LOC__c;
                }
                
                if(!existingCCNamesByCase.containsKey(csla.Case__c) || !existingCCNamesByCase.get(csla.Case__c)?.contains(newAgent.CC__C))
                    csla.Agent_CC__c   = newAgent.CC__c;
            }
        }
    }

    /**
    * @Description - Insert the user in the case team object
    * param newmap - map of recently inserted records.
    * return - null       
    **/
    public static void createCaseTeamMember(List<ASF_Case_SLA_History__c> slarecords) {
        try{
            List<CaseTeamRole> roles = [select id , name from CaseTeamRole where name='Agent'];

            String roleId = roles.isEmpty()?null:roles[0].Id;
            if(roleId != null){
                list<CaseTeamMember> caseTeamMemberlistToInsert = new list<CaseTeamMember>();
                for(ASF_Case_SLA_History__c slahistoryobj : slarecords){
                    if(String.isNotBlank(slahistoryobj.Current_Owner_Id__c) && (slahistoryobj.Current_Owner_Id__c.startsWith('005'))){
                        //userIdsSet.add(slahistoryobj.Current_Owner_Id__c);
                        caseTeamMemberlistToInsert.add(new CaseTeamMember( MemberId = slahistoryobj.Current_Owner_Id__c, ParentId = slahistoryobj.Case__c, TeamRoleId = roleId));
                    }
                }

                if(!caseTeamMemberlistToInsert.isEmpty()){
                    Database.insert(caseTeamMemberlistToInsert,false);
                }
            }
        }
        catch(Exception ex){
            //System.debug('exception e**8 '+e.getMessage());
            //Nebula.LogMessage msg = new Nebula.LogMessage('Failed to create case team member on owner change', System.today());

            //Nebula.Logger.error(msg, slarecords[0].Case__c, ex);
            //Nebula.Logger.saveLog();
        }
    }
}