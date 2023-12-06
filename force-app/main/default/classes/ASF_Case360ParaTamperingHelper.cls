public without sharing class ASF_Case360ParaTamperingHelper {
    public static Map<String,Map<String,Schema.SObjectField>> mObjField = new Map<String,Map<String,Schema.SObjectField>>();
    public static Map<String,Set<String>> mObjVsFields = new Map<String,Set<String>>();
    @AuraEnabled
    public static void executeValidation(string cccId,
                                         string status, 
                                         string caseId,
                                         Map<String,String> record, 
                                         List<string> fieldNames,  
                                         List<string> fieldValues, 
                                         String extensionObjId,
                                         boolean isManualApprovalStg){
                                             Set<String> set_ObjName = new Set<String>();
                                             Map<String,String> fields = new Map<String,String>();
                                             
                                             Map<String,String> defaultFieldValue = new Map<String,String>();
                                             Map<String,List<String>> mObjFieldsForQuery = new Map<String,List<String>>();
                                             //Map<String,String> fieldToTypeMap = new Map<String,String>();
                                             // Create Map of DefaultField Vs Values from UI - Objective is to check if for read only field 
                                             // value is changed to other than default value.
                                             // 
                                             Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('ASF_Case360ParaTamperingHelper'); 
                                             if(!mdtPEFramework.TriggerEnabled__c){
                                                 return;
                                             }
                                             
                                             for(integer i=0;i<fieldNames.size();i++){
                                                 if(fieldNames[i] != null && fieldNames[i] != ''){
                                                     if(fieldValues.size()>i){
                                                         defaultFieldValue.put(fieldNames[i],fieldValues[i]);
                                                     }
                                                     
                                                 }
                                             }
                                             
                                             // Invoke method to get the correct field config for valiation.
                                             List<ASF_GetCaseRelatedDetails.CaseFieldConfigWrapper> result = ASF_GetCaseRelatedDetails.getCaseFieldsConfig(cccId,status,caseId);
                                             for(ASF_GetCaseRelatedDetails.CaseFieldConfigWrapper r : result){
                                                 if(String.isNotBlank(r.ObjectAPIName)){
                                                     System.debug(r.ObjectAPIName);
                                                     // Get All Fields detail related to object.
                                                     // mObjFieldsForQuery --> This particular map is used to build query related to object.
                                                     set_ObjName.add(r.ObjectAPIName);
                                                     if(r.ObjectAPIName.trim().toUpperCase() == 'CASE'){
                                                         if(!mObjFieldsForQuery.containsKey('CASE')){
                                                             mObjFieldsForQuery.put('CASE',new List<String>());
                                                         }
                                                         mObjFieldsForQuery.get('CASE').add(r.FieldAPINAme);
                                                         //fieldToTypeMap.put(r.FieldAPINAme,r.FieldType.trim().toUpperCase());
                                                     }
                                                     else{
                                                         if(!mObjFieldsForQuery.containsKey(r.ObjectAPIName.trim().toUpperCase())){
                                                             mObjFieldsForQuery.put(r.ObjectAPIName.trim().toUpperCase(),new List<String>());
                                                         }
                                                         if(!mObjFieldsForQuery.get(r.ObjectAPIName.trim().toUpperCase()).contains(r.FieldAPINAme)){
                                                             mObjFieldsForQuery.get(r.ObjectAPIName.trim().toUpperCase()).add(r.FieldAPINAme);
                                                         }
                                                         //fieldToTypeMap.put(r.FieldAPINAme,r.FieldType.trim().toUpperCase());
                                                         
                                                     }
                                                 }
                                             }
                                             if(set_ObjName.size()>0){
                                                 getObjectDescribe(set_ObjName);
                                             }
                                             
                                             
                                             Map<String,sObject> mObjRecord = new Map<String,sObject>();
                                             
                                             if(mObjFieldsForQuery.keySet().size()>0){
                                                 for(String ob : mObjFieldsForQuery.keySet()){
                                                     //Query Case Object.
                                                     if(ob.trim().toUpperCase() == 'CASE'){
                                                         String q = 'SELECT ID, ';
                                                         q += String.JOIN(mObjFieldsForQuery.get('CASE'),',');
                                                         q += ' FROM CASE WHERE ID =:caseId';
                                                         List<Case> cases = Database.query(q);
                                                         if(cases.size()>0){
                                                             mObjRecord.put('CASE',cases[0]);
                                                         }
                                                     }
                                                     else{
                                                         // Query Case Related Object.
                                                         if(extensionObjId != null && extensionObjId != ''){
                                                             String q = 'SELECT ID, ';
                                                             q += String.JOIN(mObjFieldsForQuery.get(ob),',');
                                                             q += ' FROM '+ob+' WHERE Id =:extensionObjId';
                                                             System.debug(q);
                                                             List<sObject> caseRelatedRecords = Database.query(q);
                                                             if(caseRelatedRecords.size()>0){
                                                                 sObject o = caseRelatedRecords[0];
                                                                 Id tempId = o.Id;
                                                                 String temp_objNm = String.ValueOf(tempId.getSobjectType());
                                                                 if(temp_objNm != null && temp_objNm != ''){
                                                                     mObjRecord.put(temp_objNm.trim().toUpperCase(),o);
                                                                 }
                                                             }
                                                         }
                                                         
                                                     }
                                                 } 
                                             }
                                             /// WHEN IN APPROVAL STAGE - ALL FIELD ARE READ ONLY.
                                             // If anyone tries to modify any fields value in Approval Stage, show error message. (UI specific)
                                             if(isManualApprovalStg){
                                                 Id obj_recordId = record.get('id');
                                                 String obj_recordName = String.ValueOf(obj_recordId.getSobjectType());
                                                 if(obj_recordName != null && obj_recordName != ''){
                                                     
                                                     if(mObjRecord.containsKey(obj_recordName.trim().toUpperCase())){
                                                         sObject o = mObjRecord.get(obj_recordName.trim().toUpperCase());
                                                         if(o != null){
                                                             Map<String,Schema.SObjectField> temp_OFields = mObjField .get(obj_recordName);
                                                             for(String fdName : record.keySet()){
                                                                 processValidation(temp_OFields,record,o, fdName ,obj_recordName);
                                                             }
                                                         }
                                                     }
                                                 }
                                             }
                                             else{
                                                 // Below code is executed only when Stage is not manual approval stage.
                                                 for(ASF_GetCaseRelatedDetails.CaseFieldConfigWrapper r : result){
                                                     if(String.isNotBlank(r.ObjectAPIName) && String.isNotBlank(r.FieldAPINAme)){
                                                         sObject o = mObjRecord.get(r.ObjectAPIName.trim().toUpperCase());
                                                         
                                                         Map<String,Schema.SObjectField> temp_OFields = mObjField .get(r.ObjectAPIName);
                                                         
                                                         
                                                         // Handle if Controlling field is present - Older logic of Controlling field readOnly.
                                                         if(String.IsNotBlank(r.UpdateAt) && r.useControllingFormula != true){
                                                             if(r.UpdateAt.trim().containsIgnoreCase(status)){
                                                                 if(r.ControllingExpression != null && r.ControllingField !=null){
                                                                     if(record.containsKey(r.ControllingField)){
                                                                         if(record.get(r.ControllingField) != r.ControllingExpression){
                                                                             // Check if the current field is part of default set fields.
                                                                             if(defaultFieldValue.containsKey(r.FieldAPINAme)){
                                                                                 // Check if the current field value is different than default value designed for field.
                                                                                 if(record.get(r.FieldAPINAme) != o.get(r.FieldAPINAme) && o.get(r.FieldAPINAme) != null){
                                                                                     if(record.get(r.FieldAPIName) != defaultFieldValue.get(r.FieldAPINAMe)){
                                                                                         System.debug('Inside here...');
                                                                                         if(!mObjVsFields.containsKey(r.ObjectAPIName)){
                                                                                             mObjVsFields.put(r.ObjectAPIName,new Set<String>());
                                                                                         }
                                                                                         mObjVsFields.get(r.ObjectAPIName).add(r.FieldAPINAme);
                                                                                     }
                                                                                 }
                                                                             }
                                                                             else{
                                                                                 System.debug('From First ---> '+r.FieldAPINAme);
                                                                                 processValidation(temp_OFields,record,o, r.FieldAPINAme ,r.ObjectAPIName);
                                                                             }
                                                                         }
                                                                     }
                                                                 }
                                                             }
                                                             else{
                                                                 System.debug('From Second ---> '+r.FieldAPINAme);
                                                                 processValidation(temp_OFields,record,o, r.FieldAPINAme ,r.ObjectAPIName);
                                                             }
                                                         }
                                                         else if(r.useControllingFormula != true){
                                                             // Execute when no conditional rendering.
                                                             // Check if current field is part of default fields.
                                                             //processValidation(temp_OFields,record,o, r.FieldAPINAme ,r.ObjectAPIName);
                                                             if(defaultFieldValue.containsKey(r.FieldAPINAme)){
                                                                 System.debug('record.get(r.FieldAPINAme) --> '+record.get(r.FieldAPINAme));
                                                                 System.debug('o.get(r.FieldAPINAme) --> '+o.get(r.FieldAPINAme));
                                                                 if(record.get(r.FieldAPINAme) != o.get(r.FieldAPINAme) && o.get(r.FieldAPINAme) != null){
                                                                     if(record.get(r.FieldAPIName) != defaultFieldValue.get(r.FieldAPINAMe)){
                                                                         System.debug('Inside here...');
                                                                         if(!mObjVsFields.containsKey(r.ObjectAPIName)){
                                                                             mObjVsFields.put(r.ObjectAPIName,new Set<String>());
                                                                         }
                                                                         mObjVsFields.get(r.ObjectAPIName).add(r.FieldAPINAme);
                                                                     }
                                                                     
                                                                 }
                                                             }
                                                             else{
                                                                 processValidation(temp_OFields,record,o, r.FieldAPINAme ,r.ObjectAPIName);
                                                             }
                                                         }
                                                     }
                                                 } 
                                             }
                                             
                                             
                                             
                                             if(record != null && record.keySet().size()>0){
                                                 String sObjIdStr = record.get('id');
                                                 Id sObjId = Id.ValueOf(sObjIdStr);
                                                 String ObjName = String.ValueOf(sObjId.getSobjectType());
                                                 System.debug(ObjName);
                                                 if(mObjVsFields.containskey(ObjName)){
                                                     for(String fdName : mObjVsFields.get(ObjName)){
                                                         System.debug('record.get(fdName) --> '+fdName+' --> '+record.get(fdName));
                                                         if(record.get(fdName) != null && record.get(fdName) != ''){
                                                             if(mObjField.containsKey(ObjName)){
                                                                 System.debug('Inside mObjField if block...');
                                                                 if(mObjField.get(ObjName).containskey(fdName)){
                                                                     String FieldLabelName = mObjField.get(ObjName).get(fdName).getDescribe().getLabel();
                                                                     fields.put(fdName,FieldLabelName);
                                                                 }
                                                             }
                                                         }
                                                     }
                                                 }
                                             }
                                             if(fields.size()>0){
                                                 String errorString = String.join(fields.values(), ',');
                                                 throw new AuraException(errorString);
                                             }
                                             
                                             
                                         }
    private static void getObjectDescribe(Set<String> ObjectApi){
        for(String ObjName : ObjectApi){
            if(!mObjField.containsKey(ObjName)){
                Map<String,Schema.SObjectField> fMap  = Schema.getGlobalDescribe().get(ObjName.toLowerCase()).getDescribe().Fields.getMap();
                mObjField.put(ObjName,fMap);
            } 
        }
    }
    private static void processValidation(Map<String,Schema.SObjectField> temp_OFields, Map<String,String> record,sObject o, string fieldAPIName ,String objApiName){
        Schema.SObjectField schemaFdDefination = temp_OFields.get(fieldAPIName);
        Schema.DisplayType fielddataType = schemaFdDefination.getDescribe().getType();
        // 
        string temp_fdType = 'STRING';
        String record_fieldVal = String.ValueOf(record.get(fieldAPIName));
        string temp_fdVal = String.valueOf(o.get(fieldAPIName));
        
        if(fielddataType == Schema.DisplayType.DATE){
            if(o.get(fieldAPIName) != null){
                temp_fdVal = String.valueOf(Date.valueOf(o.get(fieldAPIName)));
            }
            else{
                temp_fdVal = String.valueOf(o.get(fieldAPIName));
            }
        }
        else if(fielddataType == Schema.DisplayType.PERCENT){
            integer iScale = schemaFdDefination.getDescribe().getScale();
            if(record_fieldVal != null && record_fieldVal != ''){
                decimal temp_d = decimal.valueOf(record_fieldVal);
                temp_d = temp_d.setScale(iScale);
                record_fieldVal = String.valueOf(temp_d);
            }
        }
        else if(fielddataType == Schema.DisplayType.CURRENCY || fielddataType == Schema.DisplayType.DOUBLE){
            integer iScale = schemaFdDefination.getDescribe().getScale();
            System.debug(fieldAPIName+ ' --> '+record_fieldVal);
            System.debug(fieldAPIName+ ' --> '+temp_fdVal);
            if(record_fieldVal != null && record_fieldVal != ''){
                decimal temp_d = decimal.valueOf(record_fieldVal);
                temp_d = temp_d.setScale(iScale);
                record_fieldVal = String.valueOf(temp_d);
                System.debug(record_fieldVal);
            }
        }
        else if(fielddataType == Schema.DisplayType.DATETIME ){
            if(record_fieldVal != null && record_fieldVal != ''){
                string rec_dt_Str = record_fieldVal;
                //2023-04-14T15:04:00.000Z --> Db
                //2023-04-14 15:04:00 --> Front end
                rec_dt_Str = rec_dt_Str.replace('T', ' ');
                
                //2023-04-14 15:04:00 --> DB
                //2023-04-14 15:04:00.000Z --> After replace T
                
                rec_dt_Str = rec_dt_Str.substringBefore('.');
                //2023-04-14 15:04:00 
                //2023-04-14 15:04:00
                
                record_fieldVal = rec_dt_Str;
            }
        }
        else{
            temp_fdVal = String.valueOf(o.get(fieldAPIName));
        }
        System.debug(temp_fdVal + ' == '+record_fieldVal);
        if(temp_fdVal != record_fieldVal){
            System.debug('I am here inside.');
            if(!mObjVsFields.containsKey(objApiName)){
                mObjVsFields.put(objApiName,new Set<String>());
            }
            mObjVsFields.get(objApiName).add(fieldAPIName);
        }
    }
}


/* Rough work
* 
* 
* if(r.ReadOnly != null && r.ReadOnly == true && !r.useControllingFormula){
if(!mObjVsFields.containsKey(r.ObjectAPIName)){
mObjVsFields.put(r.ObjectAPIName,new Set<String>());
}
mObjVsFields.get(r.ObjectAPIName).add(r.FieldAPINAme);
}*/