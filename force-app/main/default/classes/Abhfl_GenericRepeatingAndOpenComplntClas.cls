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

         
        String query = 'SELECT ' + fields + ' FROM ' + objectName + ' ' + whereClause;
        system.debug('inside genericFetchQuery query '+query);
        List<SObject> sobjList = Database.query(String.valueOf(query));
        return sobjList;
    }

   
    // Added By Yogesh start[PR970457-2195]
    @AuraEnabled
    public static Survrespwrapper getSurveyResponseFieldsByAccountId(Id accountId) {

        List < String > survrespFldLst = new List < String > ();
        List < String > caseFldLst = new List < String > ();
        Survrespwrapper survwrap = new Survrespwrapper();
        Map < String, String > surveyFieldlabels = new Map < String, String > ();
        if (accountId == null) {
            throw new AuraHandledException('Account ID cannot be null.');
        }
        Survey_Resp_Related__mdt surveyMetadata = Survey_Resp_Related__mdt.getInstance('Onboarding_data');
        survrespFldLst = String.isNotBlank(surveyMetadata.Field_To_Display__c) ? surveyMetadata.Field_To_Display__c.split(',') : survrespFldLst;
        caseFldLst = String.isNotBlank(surveyMetadata.Case_Fields_To_Display__c) ? surveyMetadata.Case_Fields_To_Display__c.split(',') : caseFldLst;
        survwrap.columnwrap = getcolumndata(survrespFldLst, caseFldLst);
        survwrap.rowdata = getrowdata(surveyMetadata, caseFldLst, accountId, surveyMetadata.Journey__c);
        survrespFldLst.clear();
        caseFldLst.clear();
        Survey_Resp_Related__mdt surveyMetadata1 = Survey_Resp_Related__mdt.getInstance('Service_data');
        survrespFldLst = String.isNotBlank(surveyMetadata1.Field_To_Display__c) ? surveyMetadata1.Field_To_Display__c.split(',') : survrespFldLst;
        caseFldLst = String.isNotBlank(surveyMetadata1.Case_Fields_To_Display__c) ? surveyMetadata1.Case_Fields_To_Display__c.split(',') : caseFldLst;
        survwrap.columnwrap1 = getcolumndata(survrespFldLst, caseFldLst);
        survwrap.rowdata1 = getrowdata(surveyMetadata1, caseFldLst, accountId, surveyMetadata1.Journey__c);
        survrespFldLst.clear();
        caseFldLst.clear();
        Survey_Resp_Related__mdt surveyMetadata2 = Survey_Resp_Related__mdt.getInstance('Foreclosure_data');
        survrespFldLst = String.isNotBlank(surveyMetadata2.Field_To_Display__c) ? surveyMetadata2.Field_To_Display__c.split(',') : survrespFldLst;
        caseFldLst = String.isNotBlank(surveyMetadata2.Case_Fields_To_Display__c) ? surveyMetadata2.Case_Fields_To_Display__c.split(',') : caseFldLst;
        survwrap.columnwrap2 = getcolumndata(survrespFldLst, caseFldLst);
        survwrap.rowdata2 = getrowdata(surveyMetadata2, caseFldLst, accountId, surveyMetadata2.Journey__c);
       
        return survwrap;
    }

    public static list < ColumnWrapper > getcolumndata(List < String > survrespFldLst, List < String > caseFldLst) {

        List < ColumnWrapper > columnList = new List < ColumnWrapper > ();
        Map < String, Schema.SObjectField > fieldSchemaMap = Schema.Survey_Response__c.SObjectType.getDescribe().fields.getMap();
        Map < String, Schema.SObjectField > fieldSchemaMap1 = Schema.Case.SObjectType.getDescribe().fields.getMap();
        if (survrespFldLst != null && survrespFldLst.size() > 0) {
            for (String field: survrespFldLst) {
                ColumnWrapper column = new ColumnWrapper();
                Schema.DescribeFieldResult fieldResult = fieldSchemaMap.get(field).getDescribe();
                if(fieldResult.getLabel()=='Primary Question: NPS')
                {
                    column.label = 'Rating';
                }else
                {
                    column.label = fieldResult.getLabel();
                }
                column.fieldName = field;
                column.type = String.valueof(fieldResult.getType());
                 if (column.type == 'PICKLIST') {
                    List < Schema.PicklistEntry > pickListValues = fieldSchemaMap.get(field).getDescribe().getPickListValues();
                    List < PicklistWrapper > enteriesWrapper = new List < PicklistWrapper > ();
                    for (Schema.PicklistEntry entry: pickListValues) {
                        PicklistWrapper entryWrapper = new PicklistWrapper();
                        entryWrapper.label = entry.getLabel();
                        entryWrapper.value = entry.getValue();
                        enteriesWrapper.add(entryWrapper);
                    }
                    column.options = enteriesWrapper;
                }
                columnList.add(column);
            }
        }

        if (caseFldLst != null && caseFldLst.size() > 0) {
            for (String field: caseFldLst) {
                ColumnWrapper column = new ColumnWrapper();
                Schema.DescribeFieldResult fieldResult = fieldSchemaMap1.get(field).getDescribe();
                column.label = fieldResult.getLabel();
                column.fieldName = 'Case__r.' + field;
                column.type = String.valueof(fieldResult.getType());
                if (column.type == 'PICKLIST') {
                    List < Schema.PicklistEntry > pickListValues = fieldSchemaMap1.get(field).getDescribe().getPickListValues();
                    List < PicklistWrapper > enteriesWrapper = new List < PicklistWrapper > ();
                    for (Schema.PicklistEntry entry: pickListValues) {
                        PicklistWrapper entryWrapper = new PicklistWrapper();
                        entryWrapper.label = entry.getLabel();
                        entryWrapper.value = entry.getValue();
                        enteriesWrapper.add(entryWrapper);
                    }
                    column.options = enteriesWrapper;
                }
                columnList.add(column);
            }
        }
        system.debug('columnList-->' + columnList);
        return columnList;
    }

    public static list < Survey_Response__c > getrowdata(Survey_Resp_Related__mdt survrespmetadata, List < String > caseFldLst, Id accountId, String journey) {

        List < String > updatedfieldlst = new List < String > ();
        string updatedval = ',';
        for (string cse: caseFldLst) {
            updatedval += 'case__r.' + cse + ',';
        }
        String clientcodetxt=[Select Id,Client_Code__c from Account where Id =:accountId].Client_Code__c;
        updatedval = updatedval.substring(0, updatedval.length() - 1);
        String respQuery = 'Select Id,' + String.escapeSingleQuotes(survrespmetadata.Field_To_Display__c) + updatedval + ' From Survey_Response__c WHERE Client_Code__c = :accountId AND Journey__c = : journey Order by RespondedOn__c DESC LIMIT 5';
        system.debug('Queryy-->' + respQuery);
        List < sObject > Surveyresplst = Database.Query(respQuery);
        return (List < Survey_Response__c > ) Surveyresplst;
    }

    public class ColumnWrapper {
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string fieldName;
        @AuraEnabled
        public string type;
        @AuraEnabled
        public List < PicklistWrapper > options;
        @AuraEnabled
        public Boolean wrapText = true;
    }
    Public class survrespwrapper {
        @AuraEnabled
        public List < ColumnWrapper > columnwrap;
        @AuraEnabled
        public List < ColumnWrapper > columnwrap1;
        @AuraEnabled
        public List < ColumnWrapper > columnwrap2;
        @AuraEnabled
        public List < Survey_Response__c > rowdata;
        @AuraEnabled
        public List < Survey_Response__c > rowdata1;
        @AuraEnabled
        public List < Survey_Response__c > rowdata2;
    }
    public class PicklistWrapper {
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string value;
    }
    // Added By Yogesh Ends[PR970457-2195]
}
