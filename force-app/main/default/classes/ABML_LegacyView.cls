/**
 * @description       : ABML Legacy View 
 * @author            : saravpreet.arora@in.ey.com
 * @group             : 
 * @last modified on  : 
 * @last modified by  : 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06/11/2024   Saravpreet Arora             Initial Version
**/
public with sharing class ABML_LegacyView {
    /* @LOB - ABML
    * @Function - abmlGetPersonAccountData
    * @param recordId
    * @return  AbmlPersonAccountWrapper 
    * @description  This method will get Account and Person Account field values
    *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static AbmlPersonAccountWrapper abmlGetPersonAccountData(Id recordId) {
        // Query the Account (Person Account) fields and related Contact fields
        Account personAccount = [SELECT Id,ABML_Branch_Code__c,	ABML_Franchisee_Code__c,Line_of_Business__c,
                                       (SELECT ABML_Client_ID__c, ABML_PAN__c FROM Contacts)
                               FROM Account 
                               WHERE Id = :recordId LIMIT 1];
        
        // Person Account is an Account with a Contact related to it
        AbmlPersonAccountWrapper result = new AbmlPersonAccountWrapper();
            result.branchCode = personAccount.ABML_Branch_Code__c;
            result.franchiseeCode = personAccount.ABML_Franchisee_Code__c;
            result.lob= personAccount.Line_of_Business__c;
        // Since it's a Person Account, there's only one related Contact
        if (!personAccount.Contacts.isEmpty()) {
            result.clientId = personAccount.Contacts[0].ABML_Client_ID__c;
            result.pan = personAccount.Contacts[0].ABML_PAN__c;
            
        }

        return result;
    }
    /*********************************************************
    * @Class           AbmlPersonAccountWrapper
    * @Author          Saravpreet Arora
    * @Created Date    06/11/2024 
    * @Last Modified   06/11/2024 
    * @description     Wrapper class to hold the results (fields we want to send to LWC) */
    public class AbmlPersonAccountWrapper {
        @AuraEnabled public String clientId;
        @AuraEnabled public String pan;
        @AuraEnabled public String branchCode;
        @AuraEnabled public String franchiseeCode;
        @AuraEnabled public String lob;
    }


    /* @LOB - ABML
    * @Function - abmlGetLegacyData
    * @param clientId
    * @param pan
    * @param code
    * @param startDate
    * @param endDate
    * @return  AbmlResponseWrapper 
    * @description  This method will get legacy date and display in SF
    *****************************************************************************************************************/
    @AuraEnabled
    public static AbmlResponseWrapper abmlGetLegacyData(String clientId, String pan, String code, String startDate, String endDate, String lob){
        try{
            AbmlResponseWrapper response = null;
            AbmlLegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            String integrationName = 'ABML_Legacy_Case';
          	startDate = startDate != null?startDate:'';
            endDate = endDate != null?endDate:'';
            String conPayload =  JSON.serialize(new AbmlLegacyViewRequest(clientId, pan, code, startDate, endDate, lob));
           ABCL_IntegrationCallout.IntegrationResponseWrapper legacyCaseResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);

            if(legacyCaseResponse.statusCode == 200 && String.isNotBlank(legacyCaseResponse.responseBody)) {
                legacyCaseResponseWrapper = (AbmlLegacyCaseResponseBodyWrapper)JSON.deserialize(legacyCaseResponse.responseBody,AbmlLegacyCaseResponseBodyWrapper.class);
            	response = new AbmlResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponseWrapper.lstDetails);     
                response.returnCode = legacyCaseResponseWrapper?.ReturnCode;
				response.returnMessage = legacyCaseResponseWrapper?.ReturnMessage;
            }
			//If status code is not 200, Sending reponse in string
            else if(String.isNotBlank(legacyCaseResponse.responseBody)) {
            	 response = new AbmlResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponse.responseBody);
               	 response.returnCode = legacyCaseResponseWrapper?.ReturnCode;
				 response.returnMessage = legacyCaseResponseWrapper?.ReturnMessage;
            }
            //If no response
            else {
                response = new AbmlResponseWrapper(0, '');
				response.returnMessage = Label.ASF_Error_Case_Merge ;
            }
            return response;
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    /*********************************************************
    * @Class           AbmlLegacyViewRequest
    * @Author          Saravpreet Arora
    * @Created Date    06/11/2024 
    * @Last Modified   06/11/2024 
    * @description     AbmlLegacyViewRequest */
    public class AbmlLegacyViewRequest{
        String clientID;
        String panNumber;
        String branchFranchiseeCode;
        String fromDate;
        String toDate;
        String lob;
        AbmlLegacyViewRequest(String clientId, String pan, String code, String fromDate, String toDate, String lob){
            this.clientID = clientId;
            this.panNumber = pan;
            this.branchFranchiseeCode = code;
            this.fromDate = fromDate;
            this.toDate = toDate;
            this.lob= lob;
            
        }
    }
     /*********************************************************
    * @Class           AbmlResponseWrapper
    * @Author          Saravpreet Arora
    * @Created Date    06/11/2024 
    * @Last Modified   06/11/2024 
    * @description     AbmlResponseWrapper */
    public Class AbmlResponseWrapper{
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String returnCode;
        @AuraEnabled public String returnMessage;
        //Will be used only in case of failure
        @AuraEnabled public String response;
        @AuraEnabled public List<AbmlLegacyCaseResponseWrapper> legacyCaseResponse;
        public AbmlResponseWrapper(Integer statusCode, List<AbmlLegacyCaseResponseWrapper> legacyCaseResponse){
            this.statusCode = statusCode;
            this.legacyCaseResponse = legacyCaseResponse;
        }
        public AbmlResponseWrapper(Integer statusCode, String response){
            this.statusCode = statusCode;
            this.response = response;
        }
    }
     /*********************************************************
    * @Class           AbmlLegacyCaseResponseWrapper
    * @Author          Saravpreet Arora 
    * @Created Date    06/11/2024 
    * @Last Modified   06/11/2024 
    * @description     AbmlLegacyCaseResponseWrapper */
    public class AbmlLegacyCaseResponseWrapper{
        @AuraEnabled public String CaseID;
        @AuraEnabled public String Category;
        @AuraEnabled public String CaseType;
        @AuraEnabled public String SubType;
        @AuraEnabled public String Source;
        @AuraEnabled public String ClientID;
        @AuraEnabled public String CreatedOn;
        @AuraEnabled public String CaseStatus;
        @AuraEnabled public String LastUpdatedOn;
        @AuraEnabled public String Owner;
        @AuraEnabled public String ResolvedDate;
        @AuraEnabled public String Case_TAT;
        @AuraEnabled public String Ageing_by_working_days;
        @AuraEnabled public String Assign_to_dept;
        @AuraEnabled public String Case_Closed_By;
	    @AuraEnabled public String Created_By;	
	
    }
     /*********************************************************
    * @Class           AbmlLegacyCaseResponseBodyWrapper
    * @Author          Saravpreet Arora
    * @Created Date    06/11/2024 
    * @Last Modified   06/11/2024 
    * @description     AbmlLegacyCaseResponseBodyWrapper */
    public class AbmlLegacyCaseResponseBodyWrapper{
		public String ReturnCode;
		public String ReturnMessage;
        public List<AbmlLegacyCaseResponseWrapper> lstDetails;
        public AbmlLegacyCaseResponseWrapper details;
    }
    
}