/*********************************************************
* @Class        :  ASF_CaseEmailController
* @Author       : 
* @Created Date :  
* @Last Modified:  
* @description  :  Class for Email Templates
*********************************************************/

public class ASF_CaseEmailController {
    /*********************************************************
    * @description - Use for Store case record.    
    *********************************************************/
    public Case caseObject {get;set;} 
   /*********************************************************
    * @description -Use for get case Id from VF Template.
    *********************************************************/
    public string caseId{get;set;}
   /*********************************************************
    * @description - Use for get Lightning Emial Template Body..
    *********************************************************/
    public String emailTemplateName{get;set;}
   /*********************************************************
    * @description - Use for return output/displaying text in email.
    *********************************************************/
    public String outputBody;
    
   /****************************************************************************************************************
    * @Function - getOutputBody
    * @return - String.
    * @description - Invoked from VF Template.
    *****************************************************************************************************************/
    
    public String getOutputBody(){
        CaseObject = [Select id, Subject from Case where Id =:caseId ];
        Emailtemplate emailT = [Select HtmlValue,id, subject  from EmailTemplate where Name = :emailTemplateName WITH SECURITY_ENFORCED];  
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailT.Id, userInfo.getUserId(), caseId);
        String htmlBody = mail.getHtmlBody();
        if(test.isRunningTest()){
            //htmlBody='$$WM_Details__r.Prefrred_Date_Time__c$$';
            htmlBody='$$ABHFL_Case_Detail__r.As_On_Date__c$$ -- $$Asset.Last_Disbursement_Date__c$$.';
        }

        String regExp = '\\$\\$(.*?)\\$\\$';
        htmlBody = generateString(htmlBody, regExp, CaseObject.Id);
        return htmlBody;      
    }


    /****************************************************************************************************************
    * @Function - generateString
    * @return - String.
    * @param inputText - HTML Body.
    * @param regExp - regex pattern.
    * @param caseObjectId - Case record idk.
    * @description - return String inputText = 'This is some $$text$$ between $$symbols$$ that we want to $$capture$$.';
    *****************************************************************************************************************/
    
    public String generateString(String inputText, String regExp, Id caseObjectId){
        Pattern regex = Pattern.compile(regExp);
        Matcher matcher = regex.matcher(inputText);
        
        List<String> dynamicFieldsToReplace = new List<String>();
        Map<String,String> resultMap;
        set<string> objectschemas = new set<string>();
        
        while (matcher.find()) {
            String capturedString = matcher.group(1);
            if (!dynamicFieldsToReplace.contains(capturedString)){
                if(capturedString.contains('__r')){
                    string objectName=capturedString.split('\\.')[0].replace('__r','__c');
                    objectschemas.add(objectName);
                }
                dynamicFieldsToReplace.add(capturedString);
            }
        }

        if (dynamicFieldsToReplace != null && dynamicFieldsToReplace.size() > 0){
            resultMap = getDynamicFields(dynamicFieldsToReplace,caseObjectId,objectschemas);
        }
        if (resultMap != null){
            for (String s : resultMap.keySet()) {
                inputText = inputText.replace('$$' + s + '$$', resultMap.get(s) != null ? resultMap.get(s) : '');
            }
        }
        return inputText; 
    } 

     /****************************************************************************************************************
    * @Function - getDynamicFields
    * @return - Map<String,String>.
    * @param fieldsToQuery - fields for geting field value.
    * @param recordId - Case record Id.
    * @param objectNames - relationship object names which fields are used in HTML body.
    * @description - Use for getting dynamic fields value;
    *****************************************************************************************************************/

    public static Map<String,String> getDynamicFields(List<String> fieldsToQuery, String recordId,set<String> objectNames) {
        Map<String,String> resultMap = new Map<String,String>();
        
       
        Id recordId1 = Id.valueOf(recordId);
        set<String> fieldsToQueryUniqueset = new set<String>();
        fieldsToQueryUniqueset.addAll(fieldsToQuery);
        List<String> fieldsToQuerUiqueList = new List<String>();
        fieldsToQuerUiqueList.addAll(fieldsToQueryUniqueset);
        String sobjectType = recordId1.getSObjectType().getDescribe().getName();
        String dynamicSOQL ;
        
        dynamicSOQL = buildDynamicSOQL(sobjectType, fieldsToQuerUiqueList, recordId1);

        List<sObject> documentGenerationList = Database.query(dynamicSOQL);        
        sObject documentGenObject = documentGenerationList.get(0);
        map<string,Map<String,Schema.SObjectField>> objectSchemas = getObjectSchemas(objectNames);
        for(String s : fieldsToQuerUiqueList){
            //documentGenObject.getSObject('Primary_Borrower__r').get('Full_Name__c')
            //relationship queries need second level. 
            if (s.contains('__r')){
                processRelationshipField(resultMap, s, documentGenObject, objectSchemas);
            }
            else if(s.contains('.')) {
                processNestedField(resultMap, s, documentGenObject);
            }
            else {
                processStandardField(resultMap, s, documentGenObject);
            } 
        }
        return resultMap;
    } 

    private static String buildDynamicSOQL(String sObjectType, List<String> fieldsToQuerUiqueList, Id recordId) {
        return 'Select Id, ' + String.join(fieldsToQuerUiqueList,',') + ' From ' + sobjectType +' Where Id =:recordId1';
    }

    private static void processNestedField(Map<String, String> resultMap, String field, sObject documentGenObject){
        String objectName = field.substring(0,field.indexOf('.'));
        String fieldName = field.substring(field.indexOf('.') + 1);
        String fieldValue = ' --- ';
        if(documentGenObject.getSObject(objectName) != null){
            fieldValue = ((documentGenObject.getSObject(objectName).get(fieldName))!= null)?String.valueOf(documentGenObject.getSObject(objectName).get(fieldName)):fieldValue;
        }
        resultMap.put(field, fieldValue);
    }

    private static void processStandardField(Map<String, String> resultMap, String field, sObject documentGenObject){
        String fieldValue = (String.valueOF(documentGenObject.get(field)) != null)?String.valueOF(documentGenObject.get(field)):' --- ';
        resultMap.put(field, fieldValue);
    }

    private static void processRelationshipField(Map<String, String> resultMap, String field, sObject documentGenObject, Map<String, Map<String, Schema.SObjectField>> objectSchemas){
        List<String> relationShipfield = field.split('\\.');
        object fieldValue = ' --- ';
        if(documentGenObject.getSObject(relationShipfield.get(0)) != null){                   
            fieldValue = (documentGenObject.getSObject(relationShipfield.get(0)).get(relationShipfield.get(1)) != null)?documentGenObject.getSObject(relationShipfield.get(0)).get(relationShipfield.get(1)):fieldValue;              
        }
        resultMap.put(field, String.valueOF(fieldValue));
        if( fieldValue!=null){
            String objectName=relationShipfield.get(0).replace('__r','__c');
            if(objectSchemas.get(objectName)!=null){
                Map<String,Schema.SObjectField> objectFields= objectSchemas.get(objectName);
                setDateTimeField(field, objectFields, relationShipfield, fieldValue, resultMap);
            }
        }
    }

    private static void setDateTimeField(String field, Map<String,Schema.SObjectField> objectFields, List<String> relationShipfield, object fieldValue, Map<String, String> resultMap){
        if(objectFields.containsKey(relationShipfield.get(1))){
            String dataType=string.valueOf(objectFields.get(relationShipfield.get(1)).getDescribe().getType());
            if(dataType.equals('DATETIME')){
                datetime datetimeValue = (datetime)fieldValue;
                resultMap.put(field,string.valueOf( datetimeValue.format('MM-dd-yyyy HH:mm:ss', 'IST')));
            }else if(dataType.equals('DATE')){
                datetime datetimeValue = (datetime)fieldValue;
                resultMap.put(field,string.valueOf(datetimeValue.format('dd-MM-YYYY')));
            }
        }
    }

    /****************************************************************************************************************
    * @Function - getObjectSchemas
    * @return - map<string,Map<String,Schema.SObjectField>>.
    * @param objectNames - Objects name for getting their fields.
    * @description - Use for getting objeect fields;
    *****************************************************************************************************************/
    
    public static map<string,Map<String,Schema.SObjectField>> getObjectSchemas(set<String> objectNames){
       map<string,Map<String,Schema.SObjectField>> returnMap= new map<string,Map<String,Schema.SObjectField>>();
        for(String objectName: objectNames ){
     		 SObjectType s = Schema.getGlobalDescribe().get(objectName);
		if(s!=null){
            Map<String,Schema.SObjectField> mfields = s.getDescribe().fields.getMap();
            
                returnMap.put(objectName,mfields);
            }
        }
        return returnMap;
    }
}