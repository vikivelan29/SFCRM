/*********************************************************
* @Class        :  ASF_CaseEmailController
* @Author       : 
* @Created Date :  
* @Last Modified:  
* @description  :  Class for Email Templates
*********************************************************/

@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList,PMD.NcssMethodCount')
public without sharing class ASF_CaseEmailController {
    /*********************************************************
    * @description - Use for Store case record.    
    *********************************************************/
    public Case caseObject {get;set;} 
   /*********************************************************
    * @description -Use for get case Id from VF Template.
    *********************************************************/
    public string caseId{get;set;}
   /*********************************************************
    * @description - Use for get Lightning Email Template Body..
    *********************************************************/
    public String emailTemplateName{get;set;}
    /*********************************************************
    * @description - Use for get Lightning Email Template Body using Developer Name(Unique)..
    *********************************************************/
    public String emailTemplateDeveloperName{get;set;}
   /*********************************************************
    * @description - Use for Date formatting in the outputbody.
    *********************************************************/
    public String dateFormat{get;set;}
   /*********************************************************
    * @description - Use for return output/displaying text in email.
    *********************************************************/
    public String outputBody;
    /*********************************************************
    // Map to store date field as value and possible format in list
    *********************************************************/
    Map<String, List<String>> mDateFieldFormat = new Map<String, List<String>>();
    
   /****************************************************************************************************************
    * @Function - getOutputBody
    * @return - String.
    * @description - Invoked from VF Template.
    *****************************************************************************************************************/
    
    public String getOutputBody(){
        CaseObject = [Select id, Business_Unit__c, Subject from Case where Id =:caseId ];
        Emailtemplate emailT = [Select HtmlValue,id, subject  from EmailTemplate where Name = :emailTemplateName OR DeveloperName=:emailTemplateDeveloperName WITH SECURITY_ENFORCED LIMIT 1];  
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailT.Id, userInfo.getUserId(), caseId);
        String htmlBody = mail.getHtmlBody();


        String regExpForFields = '\\$\\$(.*?)\\$\\$';
        String regExpForSubQuery = '\\#\\#(.*?)\\#\\#';

        htmlBody = generateString(htmlBody, regExpForFields, regExpForSubQuery, CaseObject.Id);
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
    
    public String generateString(String inputText, String regExpFields, String regExpForSubQuery, Id caseObjectId){
        Pattern regex = Pattern.compile(regExpFields);
        Matcher matcher = regex.matcher(inputText);
        
        Pattern regex2 = Pattern.compile(regExpForSubQuery);
        Matcher matcher2 = regex2.matcher(inputText);
        
        String caseBusinessUnit = caseObject.Business_Unit__c;

        Boolean isABHFL = (caseObject.Business_Unit__c == 'ABHFL' || caseObject.Business_Unit__c == 'ABSLI')?true:false;
        
        List<String> dynamicFieldsToReplace = new List<String>();
        Map<String,String> resultMap = new Map<String, String>();
        set<string> objectschemas = new set<string>();

        set<String> subQueriesToReplace = new set<String>();
       if(isABHFL){
            while (matcher2.find()) {
                String capturedString = matcher2.group(1);
                subQueriesToReplace.add(capturedString);                      
            }   
        } 
            

        while (matcher.find()) {
            String capturedString = matcher.group(1);
            if (!dynamicFieldsToReplace.contains(capturedString)){
                System.debug('captured string'+capturedString);
                if(capturedString.contains(':')){
                    String fs = capturedString;
                    // 1st -> field api, 2nd: either date/datetime, 3rd: function, 4th: number
                    capturedString = capturedString.split(':')[0];
                    if(mDateFieldFormat.containsKey(capturedString)){
                        mDateFieldFormat.get(capturedString).add(fs);
                    }else{
                        mDateFieldFormat.put(capturedString, new List<String>{fs});
                    }
                }
                if (!dynamicFieldsToReplace.contains(capturedString) && capturedString!='Today'){
                    if(capturedString.contains('__r')){
                        string objectName=capturedString.split('\\.')[0].replace('__r','__c');
                        objectschemas.add(objectName);
                    }else if(capturedString.contains('.')){
                        objectschemas.add(capturedString.split('\\.')[0]);
                    }
                    dynamicFieldsToReplace.add(capturedString);
                }
            }
        }

        if(!dynamicFieldsToReplace.isEmpty() || !subQueriesToReplace.isEmpty()){
            resultMap = getDynamicFields(dynamicFieldsToReplace, subQueriesToReplace, caseObjectId,objectschemas, dateFormat);
            resultMap.put('Today',Date.today().format());
        }else{
            resultMap.put('Today',Date.today().format());
        }
        System.debug(resultMap);
        System.debug(inputText);

        inputText = ASF_CaseEmailControllerBUSpecificHandler.replaceDynamicFields(inputText, resultMap, isABHFL,caseBusinessUnit);
        if (resultMap != null){
            for (String resKey : resultMap.keySet()) {
                String resVal = resultMap.get(resKey);
                if(resVal != null){
                    // check in mDateFieldFormat
                    if(mDateFieldFormat.containsKey(resKey)){
                        // get dateformated strings from Map
                        List<String> lDtFormats = mDateFieldFormat.get(resKey);
                        for(String rec: lDtFormats){
                            String evalValue = evalFormula(resVal, rec);
                            inputText = inputText.replace('$$' + rec + '$$', evalValue);
                        }
                        // for cases where simple date field is also present along with calculated fields
                        inputText = inputText.replace('$$' + resKey + '$$', resVal);
                    }else{
                        inputText = inputText.replace('$$' + resKey + '$$', resVal);
                    }
                }else{
                    inputText = inputText.replace('$$' + resKey + '$$', '');
                }
            }
        }
        return inputText; 
    } 

    private String evalFormula(String fv, String format){
        String retVal;
        // Split formated string and evaluate formula
        List<String> splitList = format.split(':');
        switch on splitList[1] {
            // datetime
            when  'dt'{
                if(splitList[2]=='add'){
                    Datetime datetimeVal = Datetime.parse(fv);
                    retVal = datetimeVal.addDays(Integer.valueOf(splitList[3])).format('dd/MM/yyyy HH:mm:ss', 'IST');
                }
            }
            // date
            when 'd'{
                if(splitList[2]=='add'){
                    System.debug('***fv:'+fv);
                    Datetime datetimeVal = (Datetime) Date.parse(fv);
                    System.debug('***datetimeVal:'+datetimeVal);
                    retVal = datetimeVal.addDays(Integer.valueOf(splitList[3])).format('dd/MM/yyyy', 'IST');
                }
            }
            when 'cd'{
                if(splitList[2]=='add'){
                    System.debug('inside custom.');
                    Datetime datetimeVal = (Datetime) Date.parse(fv);
                    retVal =  datetimeVal.addDays(Integer.valueOf(splitList[3])).format('dd/MM/yyyy', 'IST');
                    System.debug('cusyom date ==> '+retVal);
                }
            }
        }
        System.debug('***retVal:'+retVal);
        return retVal;
    }

    /****************************************************************************************************************
    * @Function - getDynamicFields
    * @return - Map<String,String>.
    * @param fieldsToQuery - fields for geting field value.
    * @param recordId - Case record Id.
    * @param objectNames - relationship object names which fields are used in HTML body.
    * @description - Use for getting dynamic fields value;
    *****************************************************************************************************************/

    public static Map<String,String> getDynamicFields(List<String> fieldsToQuery, Set<String> subQueriesToReplace, String recordId,set<String> objectNames, String dateFormat) {
        Map<String,String> resultMap = new Map<String,String>();

        Map<String, String> subFieldWithQuery = ASF_CaseEmailControllerBUSpecificHandler.handleSubQueries(subQueriesToReplace);
        System.debug('subFieldWithQuery --> '+subFieldWithQuery);
        Id recordId1 = Id.valueOf(recordId);

        set<String> fieldsToQueryUniqueset = new set<String>();
        fieldsToQueryUniqueset.addAll(fieldsToQuery);
        List<String> fieldsToQuerUiqueList = new List<String>();
        fieldsToQuerUiqueList.addAll(fieldsToQueryUniqueset);

        set<String> allfieldsToQueryUniqueset = new set<String>();
        allfieldsToQueryUniqueset.addAll(subFieldWithQuery.values());
        allfieldsToQueryUniqueset.addAll(fieldsToQuery);
        List<String> AllfieldsToQuerUiqueList = new List<String>();
        AllfieldsToQuerUiqueList.addAll(allfieldsToQueryUniqueset);
        System.debug('allfieldsToQueryUniqueset --> '+allfieldsToQueryUniqueset);

        String sobjectType = recordId1.getSObjectType().getDescribe().getName();
        String dynamicSOQL ;
        
        dynamicSOQL = buildDynamicSOQL(sobjectType, AllfieldsToQuerUiqueList, recordId1);
		System.debug('dynamicSOQL --> '+dynamicSOQL);
        List<sObject> documentGenerationList = Database.query(dynamicSOQL);        
        sObject documentGenObject = documentGenerationList.get(0);
        map<string,Map<String,Schema.SObjectField>> objectSchemas = getObjectSchemas(objectNames);

        if(!(subFieldWithQuery.values()).isEmpty()){
            processAllSubQueriesField(resultMap, documentGenObject, subFieldWithQuery.keySet());
        }

        for(String s : fieldsToQuerUiqueList){
            //documentGenObject.getSObject('Primary_Borrower__r').get('Full_Name__c')
            //relationship queries need second level. 
            if (s.contains('__r')){
                processRelationshipField(resultMap, s, documentGenObject, objectSchemas, dateFormat);
            }
            else if(s.contains('.')) {
                processNestedField(resultMap, s, documentGenObject, objectSchemas, dateFormat);
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


    public static void processAllSubQueriesField(Map<String, String> resultMap, sObject documentGenObject, Set<String> subFielsSet){
        for(String subField : subFielsSet){
            List<String> objectAndField = subField.split('\\.');
            String fieldValue = processSubQueriesField(objectAndField, documentGenObject);
            resultMap.put(subField, fieldValue);
        }
    }

    public static String processSubQueriesField(List<String> objectAndField, SObject documentGenObject){
        String objectName = objectAndField[0];
        String fieldName = objectAndField[1];
        String fieldValue = '';
        if(documentGenObject.getSObjects(objectName) != null){
            for(sObject sob : documentGenObject.getSObjects(objectName)){
                fieldValue+=(sob.get(fieldName) != null)?sob.get(fieldName) + '<next>':' --- <next>';
            }
        }
        return fieldValue.removeEnd('<next>');
    }

    private static void processNestedField(Map<String, String> resultMap, String field, sObject documentGenObject,Map<String, Map<String, Schema.SObjectField>> objectSchemas, String dateFormat){
        List<String> relationShipfield = field.split('\\.');
        String objectName = field.substring(0,field.indexOf('.'));
        String fieldName = field.substring(field.indexOf('.') + 1);
        object fieldValue = ' --- ';
        /*if(documentGenObject.getSObject(objectName) != null){
            fieldValue = ((documentGenObject.getSObject(objectName).get(fieldName))!= null)?String.valueOf(documentGenObject.getSObject(objectName).get(fieldName)):fieldValue;
        }*/
        if(documentGenObject.getSObject(objectName) != null){
            fieldValue = ((documentGenObject.getSObject(objectName).get(fieldName))!= null)?documentGenObject.getSObject(objectName).get(fieldName):fieldValue;
        }
        resultMap.put(field, String.valueOF(fieldValue));
        if( fieldValue!=null && objectSchemas.get(objectName)!=null){
            Map<String,Schema.SObjectField> objectFields= objectSchemas.get(objectName);
            setDateTimeField(field, objectFields, relationShipfield, fieldValue, resultMap, dateFormat);
        }
    }

    private static void processStandardField(Map<String, String> resultMap, String field, sObject documentGenObject){
        String fieldValue = (String.valueOF(documentGenObject.get(field)) != null)?String.valueOF(documentGenObject.get(field)):' --- ';
        resultMap.put(field, fieldValue);
    }

    private static void processRelationshipField(Map<String, String> resultMap, String field, sObject documentGenObject, Map<String, Map<String, Schema.SObjectField>> objectSchemas, String dateFormat){
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
                setDateTimeField(field, objectFields, relationShipfield, fieldValue, resultMap, dateFormat);
            }
        }
    }

    /****************************************************************************************************************
    * @Function - setDateTimeField
    * @return - void
    * @param field - Name of field
    * @param objectFields - hold Object fields details
    * @param relationShipfield - holds the relationship field API Names
    * @param fieldValue - Holds the value of the field from record
    * @param resultMap - holds the map of fields with value of record
    * @param dateFormat - hold the format of date to which it should be displayed
    * @description - Used for setting the date time fields;
    *****************************************************************************************************************/
    private static void setDateTimeField(String field, Map<String,Schema.SObjectField> objectFields, List<String> relationShipfield, object fieldValue, Map<String, String> resultMap, String dateFormat){
        if(objectFields.containsKey(relationShipfield.get(1))){
            String dataType=string.valueOf(objectFields.get(relationShipfield.get(1)).getDescribe().getType());
                if(dataType.equals('DATETIME') && fieldValue != ' --- '){
                    if(dateFormat == null || dateFormat==''){
                        datetime datetimeValue = datetime.valueOf(fieldValue);
                        resultMap.put(field,string.valueOf( datetimeValue.format('dd/MM/yyyy HH:mm:ss', 'IST')));
                    }else{
                        datetime datetimeValue = datetime.valueOf(fieldValue);
                        resultMap.put(field,string.valueOf( datetimeValue.format(dateFormat+' HH:mm:ss', 'IST')));
                    }
                }else if(dataType.equals('DATE') && fieldValue != ' --- '){
                    if(dateFormat == null || dateFormat ==''){
                        date dt = date.valueOf(fieldValue);
                        resultMap.put(field, String.valueOf(dt.Format()));
                    }else{
                        datetime dt = date.valueOf(fieldValue);
                        resultMap.put(field, String.valueOf(dt.format(dateFormat)));
                    }
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