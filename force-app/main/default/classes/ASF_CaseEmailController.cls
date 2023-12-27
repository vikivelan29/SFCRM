global without Sharing class ASF_CaseEmailController {
    global Case caseObject {get;set;}
    global string caseId{get;set;}
    public String emailTemplateName{get;set;}
    public String outputBody;
    
    global String getOutputBody(){
        CaseObject = [Select id, Subject from Case where Id =:caseId];
        Emailtemplate emailT = [Select HtmlValue,id, subject  from EmailTemplate where Name = :emailTemplateName];  
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailT.Id, userInfo.getUserId(), caseId);
        String htmlBody = mail.getHtmlBody();
        if(test.isRunningTest()){
            //htmlBody='$$WM_Details__r.Prefrred_Date_Time__c$$';
            htmlBody='$$ABHFL_Case_Detail__r.As_On_Date__c$$';
        }

        String regExp = '\\$\\$(.*?)\\$\\$';
        htmlBody = generateString(htmlBody, regExp, CaseObject.Id);
        return htmlBody;      
    }

    //String inputText = 'This is some $$text$$ between $$symbols$$ that we want to $$capture$$.';
    global String generateString(String inputText, String regExp, Id CaseObjectId){
        Pattern regex = Pattern.compile(regExp);
        Matcher matcher = regex.matcher(inputText);
        
        List<String> dynamicFieldsToReplace = new List<String>();
        Map<String,String> resultMap;
        set<string> objectschemas = new set<string>();
        
        while (matcher.find()) {
            String capturedString = matcher.group(1);
            system.debug('capturedString'+capturedString);
            if (!dynamicFieldsToReplace.contains(capturedString)){
                
                if(capturedString.contains('__r')){
                    system.debug(capturedString);
                    system.debug(capturedString.split('\\.'));
                    string objectName=capturedString.split('\\.')[0].replace('__r','__c');
                    objectschemas.add(objectName);
                }
                dynamicFieldsToReplace.add(capturedString);
            }
        }

        for(String str : dynamicFieldsToReplace){

        }
        if (dynamicFieldsToReplace != null && dynamicFieldsToReplace.size() > 0){
            System.debug('Dynamic fields  ----   '+dynamicFieldsToReplace);
            resultMap = getDynamicFields(dynamicFieldsToReplace,CaseObjectId,objectschemas);
        }
        if (resultMap != null){
            for(String s : resultMap.keyset()){
                System.debug(s+' ------ >>>>  '+resultMap.get(s));
                if(resultMap.get(s) != null){
                    inputText =inputText.replace('$$' + s + '$$',resultMap.get(s));
                }
                else{
                    inputText =inputText.replace('$$' + s + '$$','');
                }
            }
        }
        return inputText; 
    } 

    public static Map<String,String> getDynamicFields(List<String> fieldsToQuery, String recordId,set<String> objectNames) {
        Map<String,String> resultMap = new Map<String,String>();
        
       
        Id recordId1 = Id.valueOf(recordId);
        set<String> fieldsToQueryUniqueset = new set<String>();
        fieldsToQueryUniqueset.addAll(fieldsToQuery);
        List<String> fieldsToQuerUiqueList = new List<String>();
        fieldsToQuerUiqueList.addAll(fieldsToQueryUniqueset);
        String sobjectType = recordId1.getSObjectType().getDescribe().getName();
        String dynamicSOQL ;
        
        dynamicSOQL = 'Select Id, ' + String.join(fieldsToQuerUiqueList,',') + ' From ' + sobjectType +' Where Id =:recordId1';
        system.debug(dynamicSOQL);
        List<sObject> documentGenerationList = Database.query(dynamicSOQL);
        sObject documentGenObject = documentGenerationList.get(0);
        system.debug(JSON.serialize(documentGenObject));
        map<string,Map<String,Schema.SObjectField>> objectSchemas =getObjectSchemas(objectNames);
        for(String s : fieldsToQuerUiqueList){
            //documentGenObject.getSObject('Primary_Borrower__r').get('Full_Name__c')
            //relationship queries need second level. 
            if (s.contains('__r')){
                system.debug(s);
                List<String> relationShipfield = s.split('\\.');
                System.debug('  documentGenObject.getSObject(relationShipfield.get(0))  --  '+documentGenObject.getSObject(relationShipfield.get(0)));
                object fieldValue = ' --- ';
                if(documentGenObject.getSObject(relationShipfield.get(0)) != null){                   
                    fieldValue = (documentGenObject.getSObject(relationShipfield.get(0)).get(relationShipfield.get(1)) != null)?documentGenObject.getSObject(relationShipfield.get(0)).get(relationShipfield.get(1)):fieldValue;              
                }
                resultMap.put(s, String.valueOF(fieldValue));
                if( fieldValue!=null){
           		String objectName=relationShipfield.get(0).replace('__r','__c');
                if(objectSchemas.get(objectName)!=null){
                    Map<String,Schema.SObjectField> fields= objectSchemas.get(objectName);
                    if(fields.containsKey(relationShipfield.get(1))){
                        String dataType=string.valueOf(fields.get(relationShipfield.get(1)).getDescribe().getType());
                        if(dataType.equals('DATETIME')){
                            datetime datetimeValue = (datetime)fieldValue;
                            system.debug(datetimeValue);
                            system.debug(string.valueOF(datetimeValue.format('MM-dd-yyyy HH:mm:ss', 'IST')));
                            resultMap.put(s,string.valueOf( datetimeValue.format('MM-dd-yyyy HH:mm:ss', 'IST')));
                        }
                    }
                }
                }
            }
            else if(s.contains('.')) {
                String objectName = s.substring(0,s.indexOf('.'));
                String fieldName = s.substring(s.indexOf('.') + 1);
                String fieldValue = ' --- ';
                if(documentGenObject.getSObject(objectName) != null){
                    fieldValue = ((documentGenObject.getSObject(objectName).get(fieldName))!= null)?String.valueOf(documentGenObject.getSObject(objectName).get(fieldName)):fieldValue;
                }
                resultMap.put(s, fieldValue);
            }
            else {
                String fieldValue = (String.valueOF(documentGenObject.get(s)) != null)?String.valueOF(documentGenObject.get(s)):' --- ';
                resultMap.put(s, fieldValue);
            } 
        }
        for(String str : resultMap.keySet()){
            System.debug(str+ '   ->>>   '+ resultMap.get(str));
        }
        return resultMap;
    } 
    
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