public class ABHI_HhsActiveAgeDetails_Controller {
    
    
   @AuraEnabled
    public static IntegrationResponseWrapper GetHhsActiveAge(string customerId) {
    try{
        String integrationName = 'ABHI_HHS_ActiveAge_Details';
        String activAge = '1187714';
        ABCL_IntegrationCallout.accountId = customerId;
        Account acc = [SELECT id, name, Client_Code__c from Account where Id =: customerId];
        Map<String, String> urlParams = new Map<String, String>();
        urlParams.put('customerId', acc.Client_Code__c);
        urlParams.put('activAge',activAge);
        system.debug('customerId' +acc.Client_Code__c);
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,'',urlParams);
        system.debug('IntegrationResp Code' +integrationResp.statuscode);
        IntegrationResponseWrapper deserializedIntResp = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
        system.debug('deserializedIntResp>>' +deserializedIntResp);
        return deserializedIntResp;
           
        } catch (Exception e) {
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    
    public class IntegrationResponseWrapper {
            
       @AuraEnabled public String operationStatus;
       @AuraEnabled public List<serviceMessagesWrapper> serviceMessages;
       @AuraEnabled public responseMapWrapper responseMap;
       @AuraEnabled public infoWrapper info;
       @AuraEnabled public activeAgeWrapper activeAge;
       @AuraEnabled public String StatusCode;	
	   @AuraEnabled public String Message;
                public IntegrationResponseWrapper(String statusCode, String responseBody){
            this.StatusCode = statusCode;
            this.Message = responseBody;
        }
        
    }
    
    
    public class serviceMessagesWrapper{
        
        @AuraEnabled public String systemCode;
        @AuraEnabled public String businessCode;
        @AuraEnabled public String businessDesc;
        @AuraEnabled public String serviceMessageType;
        @AuraEnabled public String messageTime;
       
    }
    
    public class responseMapWrapper{
        @AuraEnabled public resultsListWrapper resultsList;
       
        
    }
    
    public class resultsListWrapper {
        @AuraEnabled public String gender;
        @AuraEnabled public Integer totalFsScore;
        @AuraEnabled public String startDate;
        @AuraEnabled public String expiryDate;
        @AuraEnabled public String scoreDate;
        @AuraEnabled public String tierLevelName;
        @AuraEnabled public String customerNumber;
        @AuraEnabled public List<activitiesWrapper> activities;
        
    }
    
    public class activitiesWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public String value;
        @AuraEnabled public Integer score;
        @AuraEnabled public String effFromDate;
        @AuraEnabled public String effToDate;
        @AuraEnabled public List<attributesWrapper> attributes;
        
    }
    public class attributesWrapper{
        @AuraEnabled public String SYSTOLIC;
        @AuraEnabled public String EA_DATE_OF_BIRTH;
        @AuraEnabled public String BMI;
        @AuraEnabled public String AGE;
        @AuraEnabled public String DIASTOLIC;
        @AuraEnabled public String SOURCENAME;
        @AuraEnabled public String EA_GENDER;
        @AuraEnabled public String SMOKING_STATUS;
        @AuraEnabled public String DIABETES;

    }
    
    public class infoWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public Integer code;
        @AuraEnabled public String value;
        @AuraEnabled public String score; 
    }
    
    public class activeAgeWrapper{
        @AuraEnabled public Integer CustomerNo;
        @AuraEnabled public Integer ActualAge;
        @AuraEnabled public Integer MultiplyAge;
        @AuraEnabled public double HeartAge;
        @AuraEnabled public String CalculationDate; 
    }

}