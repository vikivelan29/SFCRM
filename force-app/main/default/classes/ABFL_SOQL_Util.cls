/**
* @Class name:      ABFL_SOQL_Util
* @Description:
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee                     1.0       21/12/2023              #
*/
public with sharing class ABFL_SOQL_Util {
	/********************************************************************************************************
    * @author           Salesforce
    * @date             21/12/2023
    * @description      SOQL method for getting fiscal year
    * @Paramters        Integer
    * @return           List<FiscalYearSettings>
    *********************************************************************************************************/
    public static List<FiscalYearSettings> getFiscalYear() {
         return [SELECT Id, PeriodId, StartDate, EndDate, Name FROM FiscalYearSettings WHERE StartDate <= TODAY
                    AND EndDate >= TODAY Order By StartDate ASC];
    } 
}