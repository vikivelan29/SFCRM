/*********************************************************
*Class        :  ABHFL_EbotTriggerHelper
*Author       :  Siddarth Jaitly
*Created Date :  06/12/2023
*Last Modified:  06/12/2023
*Description  :  Trigger Helper for EBOT Internal Event
*********************************************************/
public class ABHFL_EbotTriggerHelper {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - createExtEbotEvent
    * @param newEmails - map of event from trigger.newMap()
    * @return - void .
    * @Description - Create CRM to EBOT Event 
    *****************************************************************************************************************/     
    public static void createExtEbotEvent(map<Id, sObject> newEvent){
        for(EBOT_Internal_Event__e request : (List<EBOT_Internal_Event__e>)newEvent.values()){
            
            system.debug('entered PE trigger');
            EmailMessage emailMsg = [Select Contentdocumentids,HasAttachment,CCAddress,FromAddress,ToAddress,BCCAddress,ParentId,Parent.Description,
                                     Parent.CaseNumber,Parent.Subject,Parent.Origin from EmailMessage where id =: request.Email_Message_ID__c ];
            system.debug('emailMsg'+emailMsg);
            
            List<String> fileNamesList = new List<String>();
            if(emailMsg.HasAttachment){
                List<ContentDocument> conDoc = [Select Title,FileExtension from ContentDocument where id in: emailMsg.ContentDocumentids];
                system.debug('conDoc'+conDoc);
                for(ContentDocument doc : conDoc){
                    fileNamesList.add(doc.Title+'.'+doc.FileExtension);
                }   
            }
            
            String fileNames = String.join(fileNamesList,',');
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
            caseInt.Case__c = emailMsg.ParentId;
            caseInt.Status__c = 'Pending';
            caseInt.Type__c = 'eBOT';
            insert caseInt;   
            caseInt = [Select Id,Name from ASF_Case_Integration__c where id =:caseInt.Id];
            
            String additionalEmails='';
            if(String.isNotBlank(emailMsg.CCAddress)){
                additionalEmails += emailMsg.CCAddress.replace(';',',');
            }
            //Salesforce doesn't capture BCC addresses in incoming mails
            if(String.isNotBlank(emailMsg.BCCAddress)){
                additionalEmails += emailMsg.BCCAddress.replace(';',',');
            }
            
            string LOB = '';
            if(String.isNotBlank(emailMsg.Parent.Origin)){
                LOB = emailMsg.Parent.Origin.split(' ')[0];
            }
            
            Map<String, String> fieldsMap = new Map<String, String>();
            fieldsMap.put('Case_Integration_ID__c',caseInt.Name);
            fieldsMap.put('Description__c',emailMsg.Parent.Description);
            fieldsMap.put('Line_of_Business__c',LOB);
            fieldsMap.put('Business_Unit__c',LOB);
            fieldsMap.put('Integration_Name__c','EBOT API');
            fieldsMap.put('Case_Number__c',emailMsg.Parent.CaseNumber);
            fieldsMap.put('From_Address__c',emailMsg.FromAddress);
            fieldsMap.put('To_Address__c',emailMsg.ToAddress);
            fieldsMap.put('Subject__c',emailMsg.Parent.Subject);
            fieldsMap.put('Additional_Emails__c',additionalEmails);
            fieldsMap.put('File_Names__c',fileNames); 
            Database.SaveResult eventResult = ABHFL_CasePlatformEventHandler.publishPlatformEvent('CRM_to_EBOT_Event__e', fieldsMap);
        }
    }
}