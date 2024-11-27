/*********************************************************
*Class        :  RNWL_EmailMessageTriggerHandler
*Author       :  Raj Raghuwanshi 
*LOB          :  RNWL
*Created Date :  05/11/2024
*Last Modified:  05/11/2024
*@description  : This class is used for validation of Email count sent for Opportunity */

public class RNWL_EmailMessageTriggerHandler {
    
     /****************************************************************************************************************
* @Function - validateEmailCount
* @param newList - EmailMessage 
* @Description - To check if same template email should not be send more than 5 time overall and twice in single day
*****************************************************************************************************************/ 
    public static void validateEmailCount(List<EmailMessage> newList){
        
        Map<String, EmailMessage> mapOfTemplateIdToEM = new Map<String, EmailMessage>(); 
        Date todayDate = Date.today();  
        
        Set<Id> allOppIds = new Set<Id>(); 
        
        for(EmailMessage msg : newList){
            if(msg.RelatedToId != null && msg.RelatedToId.getSObjectType() == Opportunity.sObjectType){
                allOppIds.add(msg.RelatedToId);
                if(mapOfTemplateIdToEM.containsKey(msg.EmailTemplateId + '' + msg.RelatedToId)){ 
                    msg.addError('You have exceeded the daily limit for sending this notification');
                }
                mapOfTemplateIdToEM.put(msg.EmailTemplateId + '' + msg.RelatedToId, msg);
            }
        }
        
        if (!allOppIds.isEmpty()) { 
            
            List<AggregateResult> existingEmailMessages = [SELECT RelatedToId, EmailTemplateId, COUNT(Id) emailCount, MAX(CreatedDate) lastCreatedDate FROM EmailMessage WHERE RelatedToId IN : allOppIds GROUP BY RelatedToId, EmailTemplateId];
            
            for (AggregateResult result : existingEmailMessages) {
                Id relatedToId = (Id) result.get('RelatedToId'); 
                String strTemplateId = (String) result.get('EmailTemplateId');
                Integer count = (Integer) result.get('emailCount');
                DateTime lastCreatedDate = (DateTime) result.get('lastCreatedDate'); 
                
                if(mapOfTemplateIdToEM.containsKey(strTemplateId + '' + relatedToId)){ 
                    if(Date.Today().isSameDay(lastCreatedDate.date())){
                        mapOfTemplateIdToEM.get(strTemplateId + '' + relatedToId).addError('You have exceeded the daily limit for sending this notification');
                    }else if(count >= 5){
                        mapOfTemplateIdToEM.get(strTemplateId + '' + relatedToId).addError('You have exceeded the overall limit for sending this notification');
                    }
                }  
            }    
        } 
    }
}