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
        for(LAN_Mapping__c lan : [select id,Customer__r.Business_Unit__c, LAN__r.Name, LAN__r.Folio__c, Customer__r.Client_Code__c FROM
                                  LAN_Mapping__c WHERE Customer__c = :accRec]) {
            option = new OptionsName();
            option.label = lan.LAN__r.Folio__c;
            option.value = lan.LAN__r.Folio__c;
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
    public static ResponseWrapper getLegacyData(String customerId, String lanNumber, String arnNumber, String lob){
        try{
            ResponseWrapper response = null;
            LegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            String integrationName = 'ABSLAMC_Legacy_Case';
            String conPayload =  JSON.serialize(new LegacyViewRequest(customerId, lanNumber, arnNumber, lob));
            System.debug('Request:'+conPayload);
            ABCL_IntegrationCallout.IntegrationResponseWrapper legacyCaseResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);
            System.debug('Response:'+legacyCaseResponse);
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
        String PAN;
        String ARN;
        String Folio;
        String LOB;
        LegacyViewRequest(String customerId, String FolioNumber, String arnNumber, String lob){
            this.PAN = customerId;
            this.ARN = arnNumber;
            this.Folio = FolioNumber;
            this.LOB = ABSLAMC_Constants.AMCLOB;
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
        
    @AuraEnabled public String CaseNumber;
    @AuraEnabled public String CaseCreatedon;
    @AuraEnabled public String CaseCategorizationDate;
    @AuraEnabled public String CaseTitle;
    @AuraEnabled public String CustomerName;
    @AuraEnabled public String TAT1Date;
    @AuraEnabled public String TAT2Date;
    @AuraEnabled public String TAT3Date;
    @AuraEnabled public String SLADeadline;
    @AuraEnabled public String ResponseTAT;
    @AuraEnabled public String Mobile;
    @AuraEnabled public String IncomingeMailId;
    @AuraEnabled public String ResolveRemark;
    @AuraEnabled public String ccs_Brokerno;
    @AuraEnabled public String ccs_schemecode;
    @AuraEnabled public String ccs_Scheme;
    @AuraEnabled public String ccs_SchemeName;
    @AuraEnabled public String CancelReason;
    @AuraEnabled public String CAMSMessageID;
    @AuraEnabled public String CAMSMessageDESC;
    @AuraEnabled public String LastReplyFromCAMS;
    @AuraEnabled public String AssignedonToAppSuppTeam;
    @AuraEnabled public String ClosureRemarks;
    @AuraEnabled public String FirstResponse;
    @AuraEnabled public String OverallSLAExceedDays;
    @AuraEnabled public String TATBreachRemarks;
    @AuraEnabled public String Remarks;
    @AuraEnabled public String SubSource;
    @AuraEnabled public String SubCategory;
    @AuraEnabled public String ComplaintSource;
    @AuraEnabled public String AdditionalComments;
    @AuraEnabled public String ServiceType;
    @AuraEnabled public String ReplyReceivedbyAppsupportTeam;
    @AuraEnabled public String IntreamResponse;
    @AuraEnabled public String Action;
    @AuraEnabled public String ResolvedOn;
    @AuraEnabled public String Ageing_NumberOfDays = 'Ageing(Number Of Days)'; //check this
    @AuraEnabled public String AgeingByWorkingDays;
    @AuraEnabled public String CAMSClosureDate;
    @AuraEnabled public String TrackId;
    @AuraEnabled public String CustomerType;
    @AuraEnabled public String Description;
    @AuraEnabled public String Interimresponse;
    @AuraEnabled public String CaseStatus;
    @AuraEnabled public String CaseStatusReason;
    @AuraEnabled public String PendingWith;
    @AuraEnabled public String ClosedInCams;
    @AuraEnabled public String SLAStatus;
    @AuraEnabled public String CaseQuickKill;
    @AuraEnabled public String CaseFTR;
    @AuraEnabled public String IssueStatus;
    @AuraEnabled public String IssueCategory;
    @AuraEnabled public String Lob;
    @AuraEnabled public String Initiator;
    @AuraEnabled public String RecaseStatus;
    @AuraEnabled public String StatusinCAMS;
    @AuraEnabled public String PendingAtLevel;
    @AuraEnabled public String Source;
    @AuraEnabled public String Category;
    @AuraEnabled public String CaseType;
    @AuraEnabled public String SubType;
    @AuraEnabled public String Owner;
    @AuraEnabled public String CreatedBy;
    @AuraEnabled public String LastResolvedBy;
    @AuraEnabled public String AssignedTeam;
    @AuraEnabled public String AssignedUser;
    @AuraEnabled public String FolioClientID;
    @AuraEnabled public String PanNumbe;
    @AuraEnabled public String AdditionalDetails1;
    @AuraEnabled public String AdditionalDetails2;
    @AuraEnabled public String EmailIncomingQueue;
    @AuraEnabled public String CamsNotes;
    @AuraEnabled public String CamsCretatedDate;
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