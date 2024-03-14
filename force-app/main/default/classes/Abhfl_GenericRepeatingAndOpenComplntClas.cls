/*********************************************************
*Class        :  Abhfl_GenericRepeatingAndOpenComplntClas
*Author       :  Anirudh Raturi
*Created Date :  07/02/2024
*Last Modified:  07/02/2024
*Description  :  Controller class for abhfl_GenericRepeatingAndOpenComplaintCase LWC
*********************************************************/

public without sharing class Abhfl_GenericRepeatingAndOpenComplntClas {
   
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - genericFetchQuery
    * @param fields - List of fields
    * @param objectName - Object Name
    * @param whereClause - WHERE cluase used in the query.
    * @return - List<SObject>
    * @Description - Generic query to fetch the sobject records.
    *****************************************************************************************************************/
    @AuraEnabled
    public static List<SObject> genericFetchQuery(String fields, String objectName, String whereClause) {

        String escapeSingleQuotesForFields        = String.escapeSingleQuotes(fields);
        String escapeSingleQuotesForObject        = String.escapeSingleQuotes(objectName);
        String escapeSingleQuotesForWhereCalause  = String.escapeSingleQuotes(whereClause);
         
        String query = 'SELECT ' + escapeSingleQuotesForFields + ' FROM ' + escapeSingleQuotesForObject + ' ' + escapeSingleQuotesForWhereCalause;
        system.debug('inside genericFetchQuery query '+query);
        List<SObject> sobjList = Database.query(query);
        return sobjList;
    }
}