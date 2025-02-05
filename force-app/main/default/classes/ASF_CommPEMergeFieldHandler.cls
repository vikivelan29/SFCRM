/**
* @description       : 
* @author            : rsinghnagar@salesforce.com
* @group             : 
* @last modified on  : 01-17-2024
* @last modified by  : rsinghnagar@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   01-17-2024   rsinghnagar@salesforce.com   Initial Version
**/
public without sharing class ASF_CommPEMergeFieldHandler {
    
    public static String[] getMergefieldNames(Channel ChannelType){
        
        String mergeFieldCSVName;
        String mergefieldHolderName;
        String templateName;
        String templateFieldName;
        
        switch on ChannelType 
        {
            when SMS {
                mergeFieldCSVName = 'SMS_Merge_Fields_CSV__c';
                mergefieldHolderName = 'SMS_Merge_Field';
                templateName = 'SMS_LT_Name__c';
                templateFieldName = 'SMS_Template_Name__c';
            }   
            when Whatsapp {
                mergeFieldCSVName = 'Whatsapp_Merge_Fields_CSV__c';
                mergefieldHolderName = 'Whatsapp_Merge_Field';
                templateName = 'WhatsApp_LT_Name__c';
                templateFieldName = 'Whatsapp_Template_Name__c';
            }
            when Email {
                mergeFieldCSVName = 'Email_Merge_Fields_CSV__c';
                mergefieldHolderName = 'Email_Merge_Field';
                templateName = 'Email_template_Name__c'; 
                templateFieldName = 'Email_Template_Name__c';
            }
        }
        
        return new string[]{mergeFieldCSVName, mergefieldHolderName, templateName,templateFieldName};
            
            }
    
    
    public static void populateMergeFields(String[] channelFieldNames,
                                           Customer_Notification_Config__mdt comm_config,
                                           case caseRecord,ASF_Communication_Log__c masterlog,
                                           Map<Id,ASF_Communication_Log__c> mPeLogIdCommunicationLog,
                                           Map<String, Schema.SObjectField> casefieldInfo, Id pLogId)
    {
        System.debug('***populateMergeFields --> ');
        Object MergeCSVField = comm_config.get(channelFieldNames[0]);
        
        if(MergeCSVField == null)
            return;
        
        List<string> mergeFields = MergeCSVField.tostring().split(',');
        
        string mergeField, fieldName, fieldValue;
        masterlog = mPeLogIdCommunicationLog.containsKey(pLogId)?mPeLogIdCommunicationLog.get(pLogId):masterlog;
        for(integer counter = 1; counter<=mergeFields.size(); counter++){
            mergeField = mergeFields[counter-1].trim();
            
            if(mergeField.contains('.')){
                String[] arr = mergeField.split('\\.');
                integer iRelLevel = 0;
                for(integer i=0;i<arr.size();i++){
                    if(arr[i].endsWith('__r')){
                        iRelLevel++;
                        if(iRelLevel >=3){
                            break;
                        }
                    }
                }
                if(iRelLevel == 1){
                    fieldValue = String.valueOf(caseRecord.getSobject(arr[0])?.get(arr[1]));
                }
                else if(iRelLevel ==2){
                    fieldValue = String.valueOf(caseRecord.getSobject(arr[0]).getSobject(arr[1])?.get(arr[2]));
                }
                else if(iRelLevel ==3){
                    fieldValue = String.valueOf(caseRecord.getSobject(arr[0]).getSobject(arr[1]).getSobject(arr[2])?.get(arr[3]));
                }
                else{
                    fieldValue = String.valueOf(caseRecord.getSobject(arr[0])?.get(arr[1]));
                }
                System.debug('fieldValue --> '+fieldValue);
                //fieldValue = String.valueOf(caseRecord.getSobject(arr[0])?.get(arr[1]));
                
                fieldValue = formatedValue(caseRecord,arr[0],fieldValue,arr[1]);
                
            }else{
                
                Schema.DisplayType FldType = casefieldInfo.get(mergeField).getDescribe().getType();
                
                if(FldType == Schema.DisplayType.DateTime){
                    Datetime dt = (Datetime) caseRecord.get(mergeField);
                    if(dt!=null){
                        //if(mergeField =='CreatedDate')
                        fieldValue = dt.format();
                        //else
                        //fieldValue = dt.date().format();
                    }
                    
                }else if(FldType == Schema.DisplayType.Date){
                    Date dt = (Date) caseRecord.get(mergeField);
                    if(dt!=null)
                        fieldValue = dt.format();
                }
                else{
                    System.debug('caseRecord.get(mergeField) --> '+caseRecord);
                    System.debug('caseRecord.get(mergeField) --> '+mergeField);
                    fieldValue = String.valueOf(caseRecord.get(mergeField));
                }
            }
            
            fieldName = channelFieldNames[1] + counter + '__c';
            
            masterlog.put(fieldName,fieldValue);
        }
        
        string tempFieldAPIName = channelFieldNames[2];
        
        masterlog.put(tempFieldAPIName,comm_config.get(channelFieldNames[3]).tostring()); //have same field name on both objects
        masterlog.put('External_Template_ID__c',comm_config.external_templateID__c);
        masterlog.put('SMS_Sender_Id__c',comm_config.SMS_Sender_Id__c );
        masterlog.put('SMS_Entity_Id__c',comm_config.SMS_Entity_Id__c );
        
        mPeLogIdCommunicationLog.put(pLogId, masterlog);
        
        
    }
    public enum Channel {SMS, Whatsapp, Email}
    
    
    public static string formatedValue(Case caseRecord,String objectName,String fieldValue,String fieldName){
        // Fixed for Null Pointer exception.
        if(caseRecord.getSobject(objectName) == null){
            return '';
        }
        String extObjectName = String.valueOf(caseRecord.getSobject(objectName).getSObjectType());
        System.debug('extObjectName --> '+extObjectName);
        Map<String, Schema.SObjectField> extFields = Schema.getGlobalDescribe().get(extObjectName.toLowerCase()).getDescribe().fields.getMap();
        Schema.DisplayType FldType = extFields.get(fieldName).getDescribe().getType();
        if(FldType == Schema.DisplayType.DateTime){
            Datetime dt =  DateTime.ValueOf(fieldValue); 
            if(dt!=null){
                fieldValue = dt.format();
            }
            
        }else if(FldType == Schema.DisplayType.Date){
            Date dt = Date.valueOf(fieldValue);
            if(dt!=null)
                fieldValue = dt.format();
        }
        return fieldValue;
    }
    
}