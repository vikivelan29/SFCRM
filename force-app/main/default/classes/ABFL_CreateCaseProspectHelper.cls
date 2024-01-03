/*****************************************************************************
* Class : ABFL_CreateCaseProspectHelper
* Author : Venkata.Tavva
* Description : Inbound API to Create Case
*****************************************************************************/

public class ABFL_CreateCaseProspectHelper {
    public static void beforeInsertMethod(List<Case> newItems){
        // Filter cases based on BU
        Map<String, Case> prospectPanMap = new Map<String, Case>();
        for(Case individualCase : newItems){
            if(individualCase.Business_Unit__c=='ABFL' && individualCase.AccountId == null && individualCase.Prospect_payload__c!=null){
                ProspectSearch prospect = (ProspectSearch)JSON.deserialize(individualCase.Prospect_payload__c,ProspectSearch.class);
                prospectPanMap.put(prospect.PANNO, individualCase);
            }
        }
        System.debug('****prospectPanMap:'+prospectPanMap);
        if(!prospectPanMap.isEmpty()){
            Map<String,String> panLeadMap = new Map<String,String>();
            for(Lead le: [select Id,FirstName,LastName,MobilePhone,Email,PANNO__c from lead where PANNO__c IN :prospectPanMap.keySet()]){
                panLeadMap.put(le.PANNO__c,le.Id);
            }
            System.debug('****panLeadMap:'+panLeadMap);

            List<Lead> newLeadsList = new List<Lead>();
            for(Case individualCase : newItems){
                if(individualCase.AccountId == null && String.isNotBlank(individualCase.Prospect_payload__c)){
                    ProspectSearch res = (ProspectSearch)JSON.deserialize(individualCase.Prospect_payload__c,ProspectSearch.class);
                    if(!panLeadMap.containskey(res.PANNO)){
                        // Create new prospect - Lead
                        Lead newLead = new lead();
                        newLead.FirstName = res.FULLNAME!=null?res.FULLNAME.split(' ')[0]:'';
                        newLead.Lastname = res.FULLNAME!=null?(res.FULLNAME.split(' ').size()>1?res.FULLNAME.split(' ')[1]:res.FULLNAME.split(' ')[0]):'';
                        newLead.MobilePhone = res.MOBILE;
                        newLead.Email = res.Email;
                        newLead.PANNO__c = res.PANNO;
                        newLeadsList.add(newLead);
                    }else{
                        // Stamp lead to existing cases
                        prospectPanMap.get(res.PANNO).Lead__c = panLeadMap.get(res.PANNO);
                    }
                }
            }

            if(newLeadsList.size()>0){
                insert newLeadsList;
                for(Lead recLead: newLeadsList){
                    // Attach Id for new lead to cases
                    prospectPanMap.get(recLead.PANNO__c).Lead__c = recLead.Id;
                }
            }
            
            System.debug('***prospectPanMap:'+prospectPanMap);
        }
    }
    
    public class prospectSearch{
        public String FULLNAME;
        public String MOBILE;
        public String PANNO;
        public String Email;
    }
}