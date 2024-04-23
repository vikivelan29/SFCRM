public class ASF_CasePreFrameworkTriggerHelper {
    
    public void populatePreFrameworkFields(list<case> newItems){
        
        Id interactionId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
        
        set<String> domainNames = new set<String>();
        set<String> EmailNames = new set<String>();
        list<Case> emailCases = new list<Case>();
        BusinessHours bh = [SELECT id FROM businesshours WHERE IsDefault=true LIMIT 1];
        Map<string,Decimal> mapSLA_Owner = new Map<string,Decimal>();
        Map<ID,String> mapGroupsByName = new Map<ID,String>();
        for(Pre_Framework_SLA_Config__mdt m : [select id,Queue_Name__c,DeveloperName,SLA_In_Minutes__c from Pre_Framework_SLA_Config__mdt])
        {
            mapSLA_Owner.put(m.Queue_Name__c,m.SLA_In_Minutes__c);
        }
        
        for(Group g : [SELECT Id, DeveloperName FROM Group where DeveloperName in:mapSLA_Owner.keyset() and Type = 'Queue'])
            mapGroupsByName.put(g.Id,g.DeveloperName );
        
        Map<String,Id> mBHName = new Map<String,Id>();
        
        for(BusinessHours bhHr : [SELECT ID,Name FROM BusinessHours]){
            if(!mBHName.containsKey(bhHr.Name)){
                mBHName.put(bhHr.Name,bhHr.Id);
            }
        }
        for(Case cs : newItems){
            if(cs.RecordTypeId == interactionId){
                cs.Source__c = 'Email';
                cs.Channel__c = 'Email';
                cs.Technical_Source__c = 'Email';
                cs.BusinessHoursId = bh.Id;
                /*
                 * //PR970457-91 Start -- Added logic to populate business unit on case records for ABFL cases created through E2C
                 * //PR970457-91 Start -- Added logic to populate business unit on case records for ABFL cases created through E2C
                 */
                String caseOrigin = cs.Origin;
                if(caseOrigin != null){
                    if(ASF_Constants.mCaseOriginVsBusinessUnit.containsKey(caseOrigin)){
                        cs.Business_Unit__c = ASF_Constants.mCaseOriginVsBusinessUnit.get(caseOrigin);
                    }
                }
                
                if(mBHName.containsKey(cs.Business_Unit__c)){
                    cs.BusinessHoursId = mBHName.get(cs.Business_Unit__c);
                }
                Long sla1Sec;
                if( mapGroupsByName.get(cs.OwnerId) != NULL && mapSLA_Owner.get(mapGroupsByName.get(cs.OwnerId)) != NULL ){
                    Integer hourVal = Integer.ValueOf(mapSLA_Owner.get(mapGroupsByName.get(cs.OwnerId)));
                    sla1Sec = hourVal*60*1000;
                }
                else{
                    sla1Sec = 60*60*1000;
                }
                
                cs.Pre_framework_SLA__c = BusinessHours.add(cs.BusinessHoursId, system.now(), sla1Sec);
                
                ASF_CaseHistoryPercentageCalc percntCls = new ASF_CaseHistoryPercentageCalc();
                percntCls.setOverallPercSLAFields(sla1Sec,cs.BusinessHoursId,system.now(),cs);
                
                
                
                if(String.isNotBlank(cs.suppliedEmail)){
                    domainNames.add(cs.suppliedEmail.split('@')[1]);
                    EmailNames.add(cs.suppliedEmail);
                    emailCases.add(cs);
                }
            }
        }
        
        set<String> priorityDomainSet; Map<Id,ID> priorityQueueMappings;
        if(!domainNames.isEmpty()){
            priorityDomainSet = getPriorityDomains(domainNames);
            priorityQueueMappings = getPriorityQueueMappings();
        }
        
        set<String> ExclusionEmailSet;
        if(!EmailNames.isEmpty())    
            ExclusionEmailSet = getExclusionEmails(EmailNames);
        
        for(Case cs : emailCases){
            
            if(ExclusionEmailSet?.contains(cs.suppliedEmail.toLowerCase())){
                cs.status = 'Cancelled';
                cs.OwnerId = Exclusion_Email__c.getOrgDefaults().Default_Case_Owner_Id__c ;
                // if(priorityQueueMappings.containsKey(cs.ownerID))
                //   cs.OwnerId = priorityQueueMappings.get(cs.ownerID);
            }else if(priorityDomainSet?.contains(cs.suppliedEmail.split('@')[1])){
                cs.Is_Priority_Customer__c = true;
                
                if(priorityQueueMappings?.containsKey(cs.ownerID))
                    cs.OwnerId = priorityQueueMappings.get(cs.ownerID);
            }
        }
    }
    private set<String> getPriorityDomains(set<String> domainNames){
        
        set<String> priorityDomainSet = new set<String>();
        for(Configuration__c cf : [select domain_name__c from Configuration__c where Active__c = true and domain_name__c in: domainNames and RecordType.DeveloperName = 'Priority_domain'])
            priorityDomainSet.add(cf.domain_name__c);
        
        return priorityDomainSet;
    }
    private Map<ID, ID> getPriorityQueueMappings(){
        list<Email_Priority_Queue_Mapping__mdt> mappings = [select From_Queue_Name__c, To_Priority_Queue__c 
                                                            from Email_Priority_Queue_Mapping__mdt where isActive__c = true];
        
        set<String> queueNames = new set<String>();
        
        for(Email_Priority_Queue_Mapping__mdt mapping : mappings){
            queueNames.add(mapping.From_Queue_Name__c);
            queueNames.add(mapping.To_Priority_Queue__c);
        }
        
        Map<String, ID> mapGroupsByName = new Map<String, ID>();
        for(Group g : [SELECT Id, DeveloperName FROM Group where DeveloperName in:queueNames and Type = 'Queue'])
            mapGroupsByName.put(g.DeveloperName, g.Id);
        
        Map<Id,ID> priorityQueueMappings = new Map<Id,ID>();
        for(Email_Priority_Queue_Mapping__mdt mapping : mappings){
            Id fromQueueID = mapGroupsByName.get(mapping.From_Queue_Name__c);
            Id toQueueID = mapGroupsByName.get(mapping.To_Priority_Queue__c);
            
            if(fromQueueID != null && toQueueID != null)
                priorityQueueMappings.put(fromQueueID, toQueueID);
        }
        
        return priorityQueueMappings;
    }
    private set<String> getExclusionEmails(set<String> EmailNames){
        
        set<String> ExclusionEmailSet = new set<String>();
        for(Configuration__c cf : [select Exclusion_Email__c from Configuration__c where Active__c = true and Exclusion_Email__c in: EmailNames and RecordType.DeveloperName = 'Exclusion_Emails'])
            ExclusionEmailSet.add(cf.Exclusion_Email__c.toLowerCase());
        
        return ExclusionEmailSet;
    }
    public void populateStageFields(list<case> caseList){
        Id interactionId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
        List<String> closedStatuses = new List<String>();
        
        for(CaseStatus cstatus : [SELECT ID,MasterLabel FROM CaseStatus WHERE isClosed = true]){
            closedStatuses.add(cstatus.MasterLabel);
        }
        for(Case cs : caseList){
            if(cs.RecordTypeId == interactionId){
                cs.Stage__c = (cs.status == 'New' || closedStatuses.contains(cs.status)) ? cs.status : 'In Progress';
            }
        }
    }
       
}