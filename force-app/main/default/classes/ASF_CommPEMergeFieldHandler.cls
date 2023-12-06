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
        Object MergeCSVField = comm_config.get(channelFieldNames[0]);
        
        if(MergeCSVField == null)
            return;
        
        List<string> mergeFields = MergeCSVField.tostring().split(',');
        
        string mergeField, fieldName, fieldValue;
        
        for(integer counter = 1; counter<=mergeFields.size(); counter++){
            mergeField = mergeFields[counter-1];
            
            System.debug('mergeField ----> '+mergeField);
            
            if(mergeField.contains('.')){
                String[] arr = mergeField.split('\\.');
                fieldValue = (String) caseRecord.getSobject(arr[0])?.get(arr[1]);
            }else{
                
                Schema.DisplayType FldType = casefieldInfo.get(mergeField).getDescribe().getType();
                
                if(FldType == Schema.DisplayType.DateTime){
                    Datetime dt = (Datetime) caseRecord.get(mergeField);
                    if(dt!=null){
                        if(mergeField =='CreatedDate')
                            fieldValue = dt.format();
                        else
                            fieldValue = dt.date().format();
                    }
                    
                }else if(FldType == Schema.DisplayType.Date){
                    Date dt = (Date) caseRecord.get(mergeField);
                    if(dt!=null)
                        fieldValue = dt.format();
                }
                else{
                    System.debug('caseRecord.get(mergeField) --> '+caseRecord);
                    System.debug('caseRecord.get(mergeField) --> '+mergeField);
                    fieldValue = (String) caseRecord.get(mergeField);
                }
            }
            
            fieldName = channelFieldNames[1] + counter + '__c';
            
            masterlog.put(fieldName,fieldValue);
        }
        
        string tempFieldAPIName = channelFieldNames[2];
        
        masterlog.put(tempFieldAPIName,comm_config.get(channelFieldNames[3]).tostring()); //have same field name on both objects
        masterlog.put('External_Template_ID__c',comm_config.external_templateID__c);
        
        mPeLogIdCommunicationLog.put(pLogId, masterlog);
        
        
    }
    public enum Channel {SMS, Whatsapp, Email}
    
}