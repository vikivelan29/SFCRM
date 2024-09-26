/*********************************************************
*Class        :  Asf_NpsIndicatiorController
*Description  :  Controller class for asf_NdcIndicator LWC
*********************************************************/

public without sharing class Asf_NpsIndicatiorController {
   
    /****************************************************************************************************************
    * @LOB - ALL
    * @Function - genericFetchQuery
    * @param fields - List of fields
    * @param objectName - Object Name
    * @param whereClause - WHERE cluase used in the query.
    * @return - List<SObject>
    * @Description - Generic query to fetch the sobject records.
    *****************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Integer> getCaseCounts(String accountId) {
        Map<String, Integer> counts = new Map<String, Integer>();        
        counts.put('openCases', [SELECT COUNT() FROM Case WHERE AccountID =: accountId and IsClosed = False]);
        counts.put('escalatedCases', [SELECT COUNT() FROM Case WHERE AccountID =: accountId and IsClosed = False and IsEscalated = true]);
        counts.put('complaintCases', [SELECT COUNT() FROM Case WHERE AccountID =: accountId and IsClosed = False and Nature__c = 'Complaint']);
        system.debug('countsasc '+counts);
        return counts;
    }
    @AuraEnabled
    public static Map<String,String> getNpsScore(string customerId) {

        Map<String,String> mapOfBusinessUnitToNpsScore = new Map<String,String>();
        List<Survey_Response__c> surveyResp = [SELECT ID,Primary_Question_NPS__c,Business_Unit__c FROM Survey_Response__c WHERE Client_Code__c =: customerId ORDER BY CreatedDate DESC LIMIT 1];

        if(!surveyResp.isEmpty() && surveyResp[0].Primary_Question_NPS__c !=null){
            mapOfBusinessUnitToNpsScore.put(surveyResp[0]?.Business_Unit__c, String.valueOf(surveyResp[0].Primary_Question_NPS__c));
        }
        else {
            mapOfBusinessUnitToNpsScore.put(surveyResp[0]?.Business_Unit__c, 'null');
        }
        return mapOfBusinessUnitToNpsScore; 
    }
}