/*********************************************************
*@Class        :  ABHFL_AssignAccountsToCaseBatch 
*@Author       :  Vishal Gangwar
*@Created Date :   01/02/2024
*@Last Modified:  
*@description  :  Batch Class for Assign Account Id to Case
*********************************************************/
public class ABHFL_AssignAccountsToCaseBatch implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String recordTypeName = ABHFL_Constants.INTERACTION_RECORD_TYPE;
        String status = ABHFL_Constants.NEW_STATUS;
        String technicalSource = ABHFL_Constants.EMAIL_TECHNICAL_SOURCE;
        String businessUnit = ABHFL_Constants.BUSINESS_UNIT_ABHFL;
        
        String query = 'SELECT Id,SuppliedEmail FROM Case WHERE RecordType.Name =: recordTypeName '+
        'AND Status =: status AND Technical_Source__c =: technicalSource '+ 
        'AND Business_Unit__c =: businessUnit AND AccountId = null '+
        'AND CreatedDate = LAST_N_DAYS:30';

        return Database.getQueryLocator(query);
    }

   // Execute method
    public void execute(Database.BatchableContext bc, List<Case> scope) {
        Set<String> caseEmailSet = new Set<String>();
        Map<String,Id> accEmailWithAccIdMap = new Map<String,Id>();

    system.debug('scope=='+scope[0].Id);

        for(Case c : scope){
            caseEmailSet.add(c.SuppliedEmail);
        }

        system.debug('caseEmailSet=='+caseEmailSet.size());
        
        if(!caseEmailSet.isEmpty()){
            for(Account acc : [SELECT Id,PersonEmail FROM Account WHERE PersonEmail IN: caseEmailSet]){
                accEmailWithAccIdMap.put(acc.PersonEmail, acc.Id);
                caseEmailSet.remove(acc.PersonEmail);
            }

            if(!caseEmailSet.isEmpty()){
                for(Contact con : [SELECT Id,Email,AccountId FROM Contact WHERE Email IN: caseEmailSet]){
                    accEmailWithAccIdMap.put(con.Email, con.AccountId);
                }
            }

            system.debug('accEmailWithAccIdMap=='+accEmailWithAccIdMap.size());

            if(!accEmailWithAccIdMap.isEmpty()){
                for(Case c : scope){
                    c.AccountId = accEmailWithAccIdMap.get(c.SuppliedEmail);
                }

                system.debug('accEmailWithAccIdMap key=='+accEmailWithAccIdMap.keySet());

                try{
                    system.debug('Inside Update==');
                    UPDATE scope;
                }catch(exception e){
                    System.debug('Error=='+e.getMessage()+ ' Line no=='+e.getLineNumber());
                }
            }
        }
    }

    // Finish Method
    public void finish(Database.BatchableContext bc) {
        //Finish Method
    }
}