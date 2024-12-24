global with sharing class RNWL_EmailTemplateVFCController{
    
    global String oppId{get;set;}
    
    global Opportunity objOpp{
        get {
            objOpp = [Select Id, Plan_Name__c, Account.RecordType.Name, Policy_Number__c, Premium_Amount__c FROM Opportunity WHERE Id =: oppId];
            return objOpp; 
        }
        set;
    }
    
    global List<MemberUIResponseWrapper> lstMember{
        get{   
            List<MemberUIResponseWrapper> lstMembers = new List<MemberUIResponseWrapper>();
            String strAPIName;
            String strPolicyKey;
            
            if(objOpp.Account.RecordType.Name == 'Individual'){
                strAPIName = 'Renewal Check';
                strPolicyKey = 'Policy_number';
            }else{
                strAPIName = 'Renewal Group Check';
                strPolicyKey = 'Certificate_number';
            }
            
            Map<String, String> mapAPIResponse = RNWL_StoredResponseUtility.getResponseFromFiles(objOpp.Id , new List<String>{strAPIName});
            String responseBody = mapAPIResponse.containsKey(strAPIName) ? mapAPIResponse.get(strAPIName) : ''  ;
            
            if(!String.isBlank(responseBody)) { 
                
                Map<String, Object> rawResponseMap = new Map<String, Object>(); 
                rawResponseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                
                List<Object> rawPolicyData = (List<Object>)((Map<String, Object>)rawResponseMap.get('response')).get('policyData');
                
                for(object objPolicy : rawPolicyData){ 
                    Map<String, Object> policyData_Map = (Map<String, Object>)objPolicy;
                    List<Object> lstRawMember = (List<Object>) policyData_Map.get('Members');
                    
                    if(objOpp.Policy_Number__c == String.valueOf(policyData_Map.get(strPolicyKey))){
                        
                        for(object member : lstRawMember){   
                            Map<String, Object> member_Map = (Map<String, Object>)member;   
                            MemberUIResponseWrapper objMemberUIResponseWrapper = new MemberUIResponseWrapper();
                            objMemberUIResponseWrapper.Name = String.valueOf(member_Map.get('Name'));
                            objMemberUIResponseWrapper.SumAssured = String.valueOf(member_Map.get('SumInsured'));
                            lstMembers.add(objMemberUIResponseWrapper);
                        } 
                    }
                } 
            } 
            return lstMembers;
        }
        set;
    }
    
    global Integer memSize{
        get{
            return lstMember.size();
        }
        set;
    } 
    
    public class MemberUIResponseWrapper{
        public String Name{get;set;}
        public String SumAssured{get;set;} 
        
    } 
}