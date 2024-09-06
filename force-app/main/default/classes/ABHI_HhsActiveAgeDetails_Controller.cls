/**************
*Class        :  ABHI_HhsActiveAgeDetails_Controller
*Author       :  Kuldeep Mishra
*Created Date :  12/08/2024
*Last Modified:  15/08/2024
*@description  :  This class is used as controller for the abhi_HHS_Active Component and for calling ActiveHealthdetails API
***************/

public class ABHI_HhsActiveAgeDetails_Controller {
    
    
   @AuraEnabled
    public static IntegrationResponseWrapper GetHhsActiveAge(string customerId) {
    try{
        String integrationName = 'ABHI_HHS_ActiveAge_Details';
        //String activAge = '1187714';
        ABCL_IntegrationCallout.accountId = customerId;
        Account acc = [SELECT id, name, Client_Code__c from Account where Id =: customerId];
        Map<String, String> urlParams = new Map<String, String>();
        urlParams.put('customerId', acc.Client_Code__c);
        //urlParams.put('activAge',activAge);
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
    
    // wrapper class for Integration Response
    public class IntegrationResponseWrapper {
        
       @AuraEnabled public HHSDetailsWrapper HHSDetails;     
       //@AuraEnabled public infoWrapper info;
       @AuraEnabled public activeAgeWrapper activeAge;
       @AuraEnabled public String StatusCode;	
	   @AuraEnabled public String Message;
                public IntegrationResponseWrapper(String statusCode, String responseBody){
            this.StatusCode = statusCode;
            this.Message = responseBody;
        }
        
    }
    
    public class HHSDetailsWrapper {
       @AuraEnabled public String operationStatus;
       @AuraEnabled public List<serviceMessagesWrapper> serviceMessages;
        @AuraEnabled public responseMapWrapper responseMap;
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
        @AuraEnabled public String attributeCode;
        @AuraEnabled public String attributeValue;

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