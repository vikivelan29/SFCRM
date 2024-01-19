/*********************************************************
* @Class        :  ABHFL_ICAndPIC_Integration
* @Author       :  Anirudh Raturi
* @Created Date :  13/12/2023
* @Last Modified:  14/12/2023
* @description  :  Helper Class for Interest Certificate And Provisional Interest Certificate Integration
*********************************************************/

public with sharing virtual class ABHFL_ICAndPIC_IntegrationHelper {

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - generateRequest
    * @param caseRecord - Case record from the framework.
    * @param typ - Value for one of the key in JSON Structure of IC and PIC Integration
    * @param finYr - Value of Financial Year
    * @return - ABHFL_ICAndPIC_IntegrationRequestWrapper
    * @description - This method is use to create JSON structure for IC And PIC Integration
    *****************************************************************************************************************/
    public ABHFL_ICAndPIC_IntegrationRequestWrapper generateRequest(Case caseRecord, String typ, String finYr) {

        String lan = caseRecord.Asset.LAN__c;
        String type = typ;

        ABHFL_ICAndPIC_IntegrationRequestWrapper reqBodyObj = new ABHFL_ICAndPIC_IntegrationRequestWrapper();
        reqBodyObj.LAN       = lan;
        reqBodyObj.FIN_YEAR  = finYr;
        reqBodyObj.TYPE      = type;

        return reqBodyObj;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - firePlatformEvtForCallout
    * @param caseInteg - Case Integration record from the framework.
    * @param jsonBody - Value for payload request in JSON Structure of IC and PIC Integration
    * @param caseSubType - Value of Case sub Type
    * @description - Firing Platform Event to make Callout for IC or PIC Integration.
*****************************************************************************************************************/
    public void firePlatformEvtForCallout(ASF_Case_Integration__c caseInteg, String jsonBody, String caseSubType) {

        String integName = String.isNotBlank(getIntegrationName(caseSubType)) ? getIntegrationName(caseSubType) : '';
        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id WITH SECURITY_ENFORCED];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.ServiceName__c  = ABHFL_Constants.REPORTING_SERVICE;
        caseIntOut.Business_Unit__c  = 'ABHFL';
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = integName;
        caseIntOut.Request_Payload__c  =  jsonBody;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
    }

    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - getIntegrationName
    * @param caseSubType - Value of Case sub Type
    * @return - integName
    * @description - Get the name of the Integration on the basis of Case Sub Type.
*****************************************************************************************************************/
    public String getIntegrationName(String caseSubType) {

        String integName = '';

        if(caseSubType == 'Interest Schedule') {
            integName = 'Interest Certificate';
        }
        else if(caseSubType == 'Provisional Interest Certificate') {
            integName = 'Provisional Interest Certificate';
        }
        return integName;
    }

    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - getFinancialYr
    * @param caseRecord - Case record from the framework.
    * @return - financialYr
    * @description - Get the Financial Year on the basis of Integration Name.
*****************************************************************************************************************/
    public String getFinancialYr(Case caseRecord) {

        String financialYr = '', currentFiscalYear;

        Period priod = [SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY WITH SECURITY_ENFORCED];
        currentFiscalYear = priod.FiscalYearSettings.Name;

        String caseSubType = caseRecord.Sub_Type_Text__c;
        String integName = String.isNotBlank(getIntegrationName(caseSubType)) ? getIntegrationName(caseSubType) : '';
        financialYr = caseRecord.ABHFL_Case_Detail__r.Financial_Year__c;
        List<String> finYrList = String.isNotBlank(financialYr) ? financialYr.split('-') : new List<String>();

        if(integName == 'Interest Certificate') {
            if(finYrList.size() > 0) {
                Integer addedfinYr = Integer.valueOf(finYrList[0]) + 1;
                financialYr = finYrList[0] + '-' + String.valueOf(addedfinYr);
            }
        }
        else if(integName == 'Provisional Interest Certificate') {
            Integer addYr = Integer.valueOf(currentFiscalYear) + 1;
            financialYr = currentFiscalYear + '-' + String.valueOf(addYr);
        }

        return financialYr;
    }


/****************************************************************************************************************
    * @description - This is a wrapper class for  JSON structure of IC And PIC Integration.
*****************************************************************************************************************/
    public class ABHFL_ICAndPIC_IntegrationRequestWrapper {
        public String LAN;
        public String FIN_YEAR;
        public String TYPE;
    }
}