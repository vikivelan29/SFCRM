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
        system.debug('mapSLA_Owner::'+mapSLA_Owner);
        for(Group g : [SELECT Id, DeveloperName FROM Group where DeveloperName in:mapSLA_Owner.keyset() and Type = 'Queue'])
            mapGroupsByName.put(g.Id,g.DeveloperName );
        system.debug('mapGroupsByName::'+mapGroupsByName);
        for(Case cs : newItems){
            if(cs.RecordTypeId == interactionId){
                cs.Source__c = 'Email';
                cs.Channel__c = 'Email';
                cs.BusinessHoursId = bh.Id;
                Long sla1Sec;
                if( mapGroupsByName.get(cs.OwnerId) != NULL && mapSLA_Owner.get(mapGroupsByName.get(cs.OwnerId)) != NULL ){
                    Integer hourVal = Integer.ValueOf(mapSLA_Owner.get(mapGroupsByName.get(cs.OwnerId)));
                    sla1Sec = hourVal*60*1000;
                }
                else{
                    sla1Sec = 60*60*1000;
                }
                
                cs.Pre_framework_SLA__c = BusinessHours.add(cs.BusinessHoursId, system.now(), sla1Sec);
                
                if(cs.Origin == 'Payments Email')
                    cs.Business_Unit__c = 'Payments';
                
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
        for(Case cs : caseList){
            if(cs.RecordTypeId == interactionId){
                cs.Stage__c = (cs.status == 'New' || cs.status == 'Rejected' || cs.status == 'Closed' || cs.status == 'Merged' || cs.status == 'Resolved') ? cs.status : 'In Progress';
            }
        }
    }
    public void caseSLAHistoryAfterInsert(map<Id, Case> newCases){
        
        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        for(Case c : [SELECT Id, Owner.Name, BusinessHoursId,Status, Stage__c,Bulk_Action__c FROM Case WHERE Id IN: newCases.values()]){
            ASF_Case_SLA_History__c slaHistory = new ASF_Case_SLA_History__c();
            slaHistory.Current_Owner__c = c.Owner.Name;
            slaHistory.Current_Owner_Id__c = c.OwnerId;
            slaHistory.Case__c = c.Id;
            slaHistory.Stage__c = c.Stage__c;
            slaHistory.Status__c = c.Status;
            //if stage is blank , then probbaly email2Case
            if(String.isBlank(slaHistory.Stage__c)){
                slaHistory.Stage__c = slaHistory.Status__c;    
            }
            slaHistory.Stage_Start_Date__c = system.now();
            slaHistory.is_Running_Record__c = true;
            slaHistory.BusinessHoursId__c = c.BusinessHoursId;
            
            if(Schema.sObjectType.Case.fields.Bulk_Action__c.isAccessible()){
                if(String.isNotBlank(c.Bulk_Action__c )){
                    slaHistory.Is_Bulk_Updated__c = true;
                    slaHistory.Bulk_Movement_User_Id__c = c.Bulk_Action__c.substringBetween('Logged in User Id : ',' 4.');
                    slaHistory.Bulk_Movement_User__c = c.Bulk_Action__c.substringBetween('Logged-in User Name : ',' 3.');
                    slaHistory.Bulk_Operation__c = c.Bulk_Action__c.substringBetween('Latest Bulk Operation : ',' 2.') + ' on ' + c.Bulk_Action__c.substringAfter('Date and Time of Operation : ') ;
                }
            }
            
            slaHistoryList.add(slaHistory);
        }
        
        if(!slaHistoryList.isEmpty()){
            
            insert slaHistoryList;
            
        }
        
        
    }
    
}