/**
 * @description       Legacy View 
 * @author            : santanu.halder@salesforce.com
 * @group             : 
 * @last modified on  : 10-17-2024
 * @last modified by  : santanu.halder@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   10-17-2024   santanu.halder@salesforce.com   Initial Version
**/
public with sharing class ABSLAMC_LegacyView {
    /* @LOB - ABSLAMC
    * @Function - getLANRelatedAccount
    * @param accRec
    * @return List<OptionsName>
    * @description This method will be used to get LANs related to Account
    *****************************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<OptionsName> getLANRelatedAccount(Id accRec){
        List<OptionsName> optionList = new List<OptionsName>();
        OptionsName option = null;
        for(LAN_Mapping__c lan : [select id,Customer__r.Business_Unit__c, LAN__r.Name, LAN__r.LAN__c, Customer__r.Client_Code__c FROM
                                  LAN_Mapping__c WHERE Customer__c = :accRec]) {
            option = new OptionsName();
            option.label = lan.LAN__r.LAN__c;
            option.value = lan.LAN__r.LAN__c;
            optionList.add(option);
        }
        return optionList;
    }
    /* @LOB - ABSLAMC
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
            String integrationName = 'ABSLAMC_Legacy_Case';
          	startDate = startDate != null?startDate:'';
            endDate = endDate != null?endDate:'';
            String conPayload =  JSON.serialize(new LegacyViewRequest(customerId, lanNumber, startDate, endDate, lob));
            ABCL_IntegrationCallout.IntegrationResponseWrapper legacyCaseResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);

            if(legacyCaseResponse.statusCode == 200 && String.isNotBlank(legacyCaseResponse.responseBody)) {
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
                response = new ResponseWrapper(0, '');
				response.returnMessage = Label.ASF_Error_Case_Merge ;
            }
            return response;
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    public class LegacyViewRequest{
        String CustomerNumber;
        String FolioNumber;
        String FromDate;
        String ToDate;
        String LOB;
        LegacyViewRequest(String customerId, String FolioNumber, String fromDate, String toDate, String lob){
            this.CustomerNumber = customerId;
            this.FolioNumber = FolioNumber;
            this.FromDate = fromDate;
            this.ToDate = toDate;
            this.LOB = lob;
        }
    }
    
    public class ResponseWrapper{
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
        @AuraEnabled public String ResolvedDate;
        @AuraEnabled public String Case_TAT;
        @AuraEnabled public String Ageing_by_working_days;
        @AuraEnabled public String Assigned_to;
        @AuraEnabled public String Case_Title;
        @AuraEnabled public String Product_Name;
        @AuraEnabled public String Assign_to_dept;
        @AuraEnabled public String Priority;
        @AuraEnabled public String Assigned_Date;
        @AuraEnabled public String Case_Closed_By;
        @AuraEnabled public String Summary;
        @AuraEnabled public String LOB;	
        @AuraEnabled public String Closure_Description;
        @AuraEnabled public String Created_By;	
        @AuraEnabled public String Case_Open_DateTime;
        @AuraEnabled public String Resoltion_Remarks;
        @AuraEnabled public String No_Of_Time_ReOpened;
        @AuraEnabled public String Assigned_Team;
        @AuraEnabled public String Vartical;
        @AuraEnabled public String RM;
        @AuraEnabled public String Holding_Response_SLA;
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