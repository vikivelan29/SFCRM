/**
 * @description       : 
 * @author            : achuriwala@salesforce.com
 * @group             : 
 * @last modified on  : 04-23-2024
 * @last modified by  : achuriwala@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-23-2024   achuriwala@salesforce.com   Initial Version
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
        System.debug('@@evaluate'+accRec);
        List<OptionsName> optionList = new List<OptionsName>();
        OptionsName option = null;
        for(LAN_Mapping__c lan : [select id,Business_Unit__c,LAN__r.Name FROM LAN_Mapping__c WHERE Customer__c = :accRec]) {
            option = new OptionsName();
            option.label = lan.LAN__r.Name;
            option.value = lan.LAN__c;
            optionList.add(option);
        }
        System.debug('@@lan'+optionList);
        return optionList;
    }
    /* @LOB - ABFL
    * @Function - getLegacyData
    * @param accRec - Account record from the framework.
    * @return - ResponseWrapper 
    * @Description - This method will get legacy date and display in SF
    *****************************************************************************************************************/
    @AuraEnabled
    public static ResponseWrapper getLegacyData(String customerId, String lanNumber, String startDate, String endDate){
        try{
            ResponseWrapper response;
           
            LegacyCaseResponseBodyWrapper legacyCaseResponseWrapper;
            String integrationName = 'ABFL_Legacy_Case';
            //ABCL_Integrations__mdt enachStatusIntegrationRec = ABCL_Integrations__mdt.getInstance(integrationName);
            System.debug('payload => '+JSON.serialize(new LegacyViewRequest(customerId, lanNumber))+'dd '+startDate+'ff '+endDate);
            String conPayload =  JSON.serialize(new LegacyViewRequest(customerId, lanNumber));
            ABCL_IntegrationCallout.IntegrationResponseWrapper legacyCaseResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);
            if(legacyCaseResponse.statusCode == 200 && String.isNotBlank(legacyCaseResponse.responseBody)) {
                system.debug('legacyCaseResponse.responseBody'+legacyCaseResponse.responseBody);
                legacyCaseResponseWrapper = (LegacyCaseResponseBodyWrapper)JSON.deserialize(legacyCaseResponse.responseBody,LegacyCaseResponseBodyWrapper.class);
            	response = new ResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponseWrapper.lstDetails);     
            }
			//If status code is not 200, Sending reponse in string
            else if(String.isNotBlank(legacyCaseResponse.responseBody)) {
            	 response = new ResponseWrapper(legacyCaseResponse.statusCode,legacyCaseResponse.responseBody);
            }
			response.returnCode = legacyCaseResponseWrapper.ReturnCode;
			response.returnMessage = legacyCaseResponseWrapper.ReturnMessage;
            
            //Remove start---
           /* String s = '{\"ReturnCode\":\"1\",\"ReturnMessage\":\"Recordretrievedsuccessfully\",\"lstDetails\":[{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2395728-C4Z3V6\",\"Category\":\"Request\",\"CaseType\":\"Pre-Closure\\/Closure\",\"SubType\":\"PreClosure\",\"Source\":\"Walkin\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"08-04-202411:24:20\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"13-04-202409:18:33\",\"Owner\":\"MeghnaKadam\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2389442-V0H3V7\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"ListofDocuments\\/Postdisbursaldocs\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"03-04-202409:12:03\",\"CaseStatus\":\"Canceled\",\"LastUpdatedOn\":\"03-04-202409:12:42\",\"Owner\":\"SunilYadav10\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2342421-D2H4R5\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"StatementofAccount\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"23-02-202414:10:47\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"23-02-202414:10:58\",\"Owner\":\"ABFSSLCRMADMIN03\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2166297-Z9D3V0\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"13-10-202315:07:54\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"13-10-202315:08:03\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2125970-Z8S6T2\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"13-09-202315:54:18\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"13-09-202315:54:27\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-994441-R9Z1G3\",\"Category\":\"Query\",\"CaseType\":\"Campaign\",\"SubType\":\"Non-Contactable\",\"Source\":\"Email\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"25-09-202113:00:37\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"25-09-202113:00:49\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984667-K6K1P3\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:10:54\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"20-09-202109:11:04\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984665-M2B6B1\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:10:28\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"20-09-202109:10:33\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984664-G7B6N3\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:10:13\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"20-09-202109:10:21\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984663-X6R1C0\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"ListofDocuments\\/Postdisbursaldocs\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:09:57\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"28-09-202114:31:26\",\"Owner\":\"GautamSejwal\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984647-K7N9D2\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"InsuranceCopy\",\"Source\":\"CallCentre-Inbound\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:07:05\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"22-09-202105:30:18\",\"Owner\":\"DipeshVarekar\"}]}';
			//String s = '{\"ReturnCode\":\"2\",\"ReturnMessage\":\"Nodatafound\"}';
            System.debug('@@s'+s);
            legacyCaseResponseWrapper = (LegacyCaseResponseBodyWrapper)JSON.deserialize(s,LegacyCaseResponseBodyWrapper.class);
            System.debug('@@legacyCaseResponseWrapper'+legacyCaseResponseWrapper);
            response = new ResponseWrapper(200,legacyCaseResponseWrapper.lstDetails);
            response.returnCode = legacyCaseResponseWrapper.ReturnCode;
			response.returnMessage = legacyCaseResponseWrapper.ReturnMessage;
            System.debug('legacyCaseResponse => '+response);*/
            //Remov End-----
            return response;
        }catch(exception e){
            System.debug('@@ER'+e.getMessage()+' '+e.getLineNumber());
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }

    public class LegacyViewRequest{
        String CustomerNumber;
        String HoldingNumber;
        LegacyViewRequest(String customerId, String holdingNumber){
            this.CustomerNumber = customerId;
            this.HoldingNumber = holdingNumber;
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
    }
    public class OptionsName {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }
}