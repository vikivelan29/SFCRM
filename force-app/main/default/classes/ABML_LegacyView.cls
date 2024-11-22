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
     
        Account personAccount = [Select Id,RecordType.Name, Client_Code__c,Line_of_Business__c,ABML_Client_Branch_Franchisee__pr.ABML_Franchisee_Code__c,ABML_Client_Branch_Franchisee__pr.ABML_Branch_Code__c, PAN__c,ABML_Franchisee_Code__c,ABML_Branch_Code__c
                             From Account
                             Where Id =: recordId];
							 
		AbmlPersonAccountWrapper result = new AbmlPersonAccountWrapper();
        result.lob= personAccount.Line_of_Business__c != null ? personAccount.Line_of_Business__c : '';
        If(personAccount.RecordType.Name == 'ABML Franchisee' || personAccount.RecordType.Name == 'ABML Branch'){
            result.branchCode = personAccount.ABML_Branch_Code__c  != null ? personAccount.ABML_Branch_Code__c : '';
            result.franchiseeCode = personAccount.ABML_Franchisee_Code__c  != null ? personAccount.ABML_Franchisee_Code__c : '';
        }
        else if(personAccount.RecordType.Name == 'ABML Branch Employee'){
            result.branchCode = personAccount.ABML_Client_Branch_Franchisee__pr.ABML_Branch_Code__c  != null ? personAccount.ABML_Client_Branch_Franchisee__pr.ABML_Branch_Code__c : '';
            result.franchiseeCode = personAccount.ABML_Client_Branch_Franchisee__pr.ABML_Franchisee_Code__c  != null ? personAccount.ABML_Client_Branch_Franchisee__pr.ABML_Franchisee_Code__c : '';
        }
        else{
            result.clientCode = personAccount.Client_Code__c;
            result.pan = personAccount.PAN__c;
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
        @AuraEnabled public String clientCode;
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
    public static AbmlResponseWrapper abmlGetLegacyData(String clientCode, String pan, String code, String startDate, String endDate, String lob){
        try{
            AbmlResponseWrapper response = null;
            AbmlLegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            String integrationName = 'ABML_Legacy_Case';
          	startDate = startDate != null ? startDate : '';
            endDate = endDate != null ? endDate : '';
            clientCode = clientCode != null ? clientCode : '';
            pan = pan != null ? pan : '';
            code = code != null ? code : '';
            lob = lob != null ? lob : '';
            String conPayload =  JSON.serialize(new AbmlLegacyViewRequest(clientCode, pan, code, startDate, endDate, lob));
            System.debug('Data Request-->'+conPayload);
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
        
        String PAN;
        String ClientId;
        String Branch_franchisee_code;
        String FromDate;
        String ToDate;
        String LOB;
        AbmlLegacyViewRequest(String clientId, String pan, String code, String fromDate, String toDate, String lob){
            this.ClientId = clientId;
            this.PAN = pan;
            this.Branch_franchisee_code = code;
            this.FromDate = fromDate;
            this.ToDate = toDate;
            this.LOB= lob;
            
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