@SuppressWarnings('PMD.FormalParameterNamingConventions')
global class ASF_CaseAgeInBusinessDaysBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    private Map<Id, Decimal> BusinessHoursTohoursPerDay = new Map<Id, Decimal>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
              
      calculateBusinessHoursPerDay(); 
      String query = 'SELECT Id, Ageing_Business_Days__c, createddate, BusinessHoursId FROM case WHERE isclosed != true';
      return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        
        for (Case caseRec : scope) {
        	caseRec.Ageing_Business_Days__c = calculateBusinesAge(caseRec);
        }
        
        ASF_TriggerSkipperUtility.markTriggerRun('Case'); 
        Database.SaveResult[] updateResult = Database.update(scope,false); 

        for (Database.SaveResult sr : updateResult) {
            if (!sr.isSuccess()) {
                system.debug('Error in ASF_CaseAgeInBusinessDaysBatch.execute: '+sr.getErrors()[0].getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {}

    private Integer calculateBusinesAge(case caseRec){
        Integer caseAgeInDays = 0;

        // Calculate the difference in business hours between case creation date and current date
        double caseAge = BusinessHours.diff(caseRec.businessHoursId, caseRec.CreatedDate, System.now());
        double hoursPerDay = BusinessHoursTohoursPerDay.containsKey(caseRec.businessHoursId) ? BusinessHoursTohoursPerDay.get(caseRec.businessHoursId) : 9.00; 
        caseAgeInDays = Integer.valueOf (caseAge / (1000 * 60 * 60 * hoursPerDay));
 
        System.debug('Case Age in Business Hours: '+caseRec.businessHoursId+'--' + caseRec.CreatedDate+'--'+System.now()+'--'+BusinessHoursTohoursPerDay.get(caseRec.businessHoursId)+'--'+caseAgeInDays);
        
        return caseAgeInDays;
    }
    
    private void calculateBusinessHoursPerDay(){
                
        for(BusinessHours BhRec : [SELECT Id, MondayStartTime, MondayEndTime FROM BusinessHours]){
            
            if(BhRec.MondayStartTime == null){
                BusinessHoursTohoursPerDay.put(BhRec.Id, 9);
                continue;
            } 

            Decimal startMinutes = BhRec.MondayStartTime.hour() * 60 + BhRec.MondayStartTime.minute();
            Decimal endMinutes = BhRec.MondayEndTime.hour() * 60 + BhRec.MondayEndTime.minute();
            Decimal hoursPerDay = (endMinutes - startMinutes) / 60; 
            
            if(hoursPerDay == 0){
                BusinessHoursTohoursPerDay.put(BhRec.Id, 24);     
            }else{
                BusinessHoursTohoursPerDay.put(BhRec.Id, hoursPerDay);
            }
        }
    }
    
    global void execute(SchedulableContext scon) {
        Database.executeBatch(new ASF_CaseAgeInBusinessDaysBatch(),100);
    }

}