public class Abml_CaseCloseBulkHandler {
    
    @auraenabled(cacheable=true)
    public static list<case> GetFrameworkCases(){
        
        return[select Id , suppliedemail , OwnerText__c, subject ,createddate , Casenumber, description from case where recordtype.name =  'Interaction' and Type_Text__c = '' and Sub_Type_Text__c = '' and status = 'New' and Origin = 'ABML Email' and Business_Unit__c=:System.Label.ABML_BU];
    }
    
     @AuraEnabled
    public static void UpdateCase(list<String>caseId, string Descript) {
        System.debug('caseId Is ::: '+caseId);
        list<case> CasetoUpdate = new list<case>();
        list<case> cclist = [select Id , status, Description, Rejected_Reason__c from case where ID IN:caseId];
            for (case c : cclist) {
            c.status = 'Closed';
            c.Rejected_Reason__c = Descript;
            c.Description = c.Description + '  ' + Descript;
            CasetoUpdate.add(c);
            
        }
        if(!CasetoUpdate.isempty()){
          update CasetoUpdate;   
        }
       System.debug('CasetoUpdate Is ::: '+CasetoUpdate);     
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getSearchRecords(String searchText) {
        if (String.isEmpty(searchText)) {
            
        return[select Id , suppliedemail , OwnerText__c, subject ,createddate , Casenumber, description from case where recordtype.name =  'Interaction' and Type_Text__c = '' and Sub_Type_Text__c = '' and status = 'New' and Origin = 'ABML Email' and Business_Unit__c=:System.Label.ABML_BU];

        }        
        return [ SELECT Id, CaseNumber, Subject, Status, CreatedDate, Owner.Name, SuppliedEmail, OwnerText__c, Description FROM Case WHERE Subject!=null and Status ='New' and  recordtype.name =  'Interaction' and Type_Text__c = '' and Sub_Type_Text__c = '' and Origin = 'ABML Email' and Business_Unit__c=:System.Label.ABML_BU and (Subject LIKE :('%' + searchText + '%') OR CaseNumber LIKE :('%' + searchText + '%') OR SuppliedEmail LIKE :('%' + searchText + '%')) ORDER BY Subject LIMIT 200 ];
    }
    

}