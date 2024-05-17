/**
 * @description       : 
 * @author            : achuriwala@salesforce.com
 * @group             : 
 * @last modified on  : 04-23-2024
 * @last modified by  : achuriwala@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-23-2024   achuriwala@salesforce.com   Initial Version
 * 2.0	 05-15-2024   achuriwala@salesforce.com   Changes according to the API details
**/
public with sharing class ABFL_LegacyView {
    /* @LOB - ABFL
    * @Function - getLANRelatedAccount
    * @param accRec - Account record from the framework.
    * @return - List<LAN_Mapping__c> 
    * @Description - This method will be used to get LANs related to Account
    *****************************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<OptionsName> getLANRelatedAccount(Id accRec){
        List<OptionsName> optionList = new List<OptionsName>();
        OptionsName option = null;
        for(LAN_Mapping__c lan : [select id,Customer__r.Business_Unit__c, LAN__r.Name, Customer__r.Client_Code__c FROM
                                  LAN_Mapping__c WHERE Customer__c = :accRec WITH SECURITY_ENFORCED]) {
            option = new OptionsName();
            option.label = lan.LAN__r.Name;
            option.value = lan.LAN__r.Name;
            optionList.add(option);
        }
        System.debug('@@lan'+optionList);
        return optionList;
    }
    /* @LOB - ABFL
    * @Function - getLegacyData
    * @param customerId
    * @param lanNumber
    * @param startDate
    * @param endDate
    * @param lob
    * @return  ResponseWrapper 
    * @description  This method will get legacy date and display in SF
    *****************************************************************************************************************/
    @AuraEnabled
    public static ResponseWrapper getLegacyData(String customerId, String lanNumber, String startDate, String endDate, String lob){
        try{
            ResponseWrapper response = null;
            LegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            String integrationName = 'ABFL_Legacy_Case';
          	startDate = startDate != null?startDate:'';
            endDate = endDate != null?endDate:'';
            String conPayload =  JSON.serialize(new LegacyViewRequest(customerId, lanNumber, startDate, endDate, lob));
            ABCL_IntegrationCallout.IntegrationResponseWrapper legacyCaseResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);
            if(legacyCaseResponse.statusCode == 200 && String.isNotBlank(legacyCaseResponse.responseBody)) {
                system.debug('legacyCaseResponse.responseBody'+legacyCaseResponse.responseBody);
                legacyCaseResponseWrapper = (LegacyCaseResponseBodyWrapper)JSON.deserialize(legacyCaseResponse.responseBody,LegacyCaseResponseBodyWrapper.class);
            	response = new ResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponseWrapper.lstDetails);     
                response.returnCode = legacyCaseResponseWrapper?.ReturnCode;
				response.returnMessage = legacyCaseResponseWrapper?.ReturnMessage;
            }
			//If status code is not 200, Sending reponse in string
            else if(String.isNotBlank(legacyCaseResponse.responseBody)) {
            	 response = new ResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponse.responseBody);
               	 response.returnCode = legacyCaseResponseWrapper?.ReturnCode;
				 response.returnMessage = legacyCaseResponseWrapper?.ReturnMessage;
            }
            //If no response
            else {
				response.returnMessage = Label.ASF_Error_Case_Merge ;
            }
            return response;
        }catch(exception e){
            System.debug('@@ER'+e.getMessage()+' '+e.getLineNumber());
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }

    public class LegacyViewRequest{
        String CustomerNumber;
        String HoldingNumber;
        String FromDate;
        String ToDate;
        String LOB;
        LegacyViewRequest(String customerId, String holdingNumber, String fromDate, String toDate, String lob){
            this.CustomerNumber = customerId;
            this.HoldingNumber = holdingNumber;
            this.FromDate = fromDate;
            this.ToDate = toDate;
            this.LOB = lob;
        }
    }

    public Class ResponseWrapper{
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String returnCode;
        @AuraEnabled public String returnMessage;
        //Will be used only in case of failure
        @AuraEnabled public String response;
        @AuraEnabled public List<LegacyCaseResponseWrapper> legacyCaseResponse;
        public ResponseWrapper(Integer statusCode, List<LegacyCaseResponseWrapper> legacyCaseResponse){
            this.statusCode = statusCode;
            this.legacyCaseResponse = legacyCaseResponse;
        }
        public ResponseWrapper(Integer statusCode, String response){
            this.statusCode = statusCode;
            this.response = response;
        }
    }
    
    public class LegacyCaseResponseWrapper{
        @AuraEnabled public String Customer;
        @AuraEnabled public String CaseID;
        @AuraEnabled public String Category;
        @AuraEnabled public String CaseType;
        @AuraEnabled public String SubType;
        @AuraEnabled public String Source;
        @AuraEnabled public String LoanAccountNo;
        @AuraEnabled public String CreatedOn;
        @AuraEnabled public String CaseStatus;
        @AuraEnabled public String LastUpdatedOn;
        @AuraEnabled public String Owner;
    }
    public class LegacyCaseResponseBodyWrapper{
		public String ReturnCode;
		public String ReturnMessage;
        public List<LegacyCaseResponseWrapper> lstDetails;
        public LegacyCaseResponseWrapper details;
    }
    public class OptionsName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
}