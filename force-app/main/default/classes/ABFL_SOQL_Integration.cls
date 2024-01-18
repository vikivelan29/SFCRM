/**
* @Class name:      ABFL_SOQL_Integration
* @Description:
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee                     1.0       13/12/2023              #
*/
public class ABFL_SOQL_Integration {
	/********************************************************************************************************
    * @author           Salesforce
    * @date             13/12/2023
    * @description      SOQL method for getting integration details
    * @Paramters        String
    * @return           case
    *********************************************************************************************************/
    public static List<ASF_Case_Integration__c> getCaseIntegrationInfo(string caseid, String type){
        return [SELECT Name FROM ASF_Case_Integration__c 
                WHERE Case__c = :caseid 
                AND Status__c = :ABFL_Constants.PENDING
                AND Type__c = :type
                WITH SECURITY_ENFORCED];
    } 
    /********************************************************************************************************
    * @author           Salesforce
    * @date             13/12/2023
    * @description      SOQL method for getting integration details
    * @Paramters        String
    * @return           case
    *********************************************************************************************************/
    public static ASF_Integration__c getIntegrationInfo(string externalId){
        return [SELECT id, STP_API_Identifier__c, STP_Processing_Class__c, 
                External_Id__c,STP_Config_External_Id__c 
                FROM ASF_Integration__c 
                WHERE External_Id__c = :externalId];
    } 
}