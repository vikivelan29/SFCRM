/*********************************************************
*Name           :   ASF_SMSCommunicationParser
*Author         :   Salesforce
*Since          :    
*Description    :   Parser class for SMS Communication 
*History
Name                Date                  Change Description

*********************************************************/
public without sharing class ASF_SMSCommunicationParser {
    public class RequestBody{
        
        public String mobileNo;
    }

    /****************************************************
    * @Description - get Contact Details for the Case  
    * @param srId - Case Id.
    * @return -  List of Contact associated to that case(Account).     
    *****************************************************/

    @AuraEnabled(cacheable=true)
    public static List<ASF_ContactDetailsWrapper> getListOfContact(String srId){
        List<ASF_ContactDetailsWrapper> conLst = new List<ASF_ContactDetailsWrapper>();
        try {
            List<Case> cs = [SELECT AccountId FROM Case WHERE Id =: srId WITH SECURITY_ENFORCED LIMIT 1];
            Id accId = cs[0].AccountId;
            for(Contact con: [SELECT Id, Name, MobilePhone FROM Contact 
                                WHERE AccountId  =: accId]){
                conLst.add(new ASF_ContactDetailsWrapper(con));
            }

        } catch(Exception objExp) {
            //Nebula.Logger.error(objExp.getMessage());
            //Nebula.Logger.saveLog(); 
        }

        return conLst;
        
    }

    /****************************************************
     * @Description - Wrapper Class for Contact Details
    *****************************************************/ 
    public class ASF_ContactDetailsWrapper {
        @AuraEnabled
        public Id id{get;set;}
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String phone{get;set;}
        
        /****************************************************
         * @Description - paramaterized Construtor 
        *****************************************************/  
        public ASF_ContactDetailsWrapper(Contact con){
            this.id = con.Id;
            this.name = con.Name;
            this.phone = con.MobilePhone;
        }

        /****************************************************
         * @Description - Default Construtor 
        *****************************************************/  
        public ASF_ContactDetailsWrapper(){
            this.id = ASF_Constants.STRING_BLANK;
            this.name = ASF_Constants.STRING_BLANK;
            this.phone = ASF_Constants.STRING_BLANK;
        }
    }


    /****************************************************
    * @Description - get Whatsapp Template list for the Case  
    * @param caseId - Case Id.
    * @return -  List of template.     
    *****************************************************/

    @AuraEnabled
    public static List<ASF_SMSTemplateWrapper> getListOfTemplate(String caseId){
        Map<String, String> templateNameLabelMap = new Map<String, String>();
        for(EmailTemplate em: [SELECT Id, Name, DeveloperName FROM EmailTemplate WITH SECURITY_ENFORCED ]){
            templateNameLabelMap.put(em.DeveloperName,em.Name);
        }

        List<ASF_SMSTemplateWrapper> SMSTempList = new List<ASF_SMSTemplateWrapper>();
        try {
            List<Case> cs = [SELECT CCC_External_Id__c FROM Case WHERE Id =: caseId WITH SECURITY_ENFORCED LIMIT 1];
            String cccId = cs[0].CCC_External_Id__c;
            List<ASF_Case_Category_Config__c> cccLst = [SELECT id,SMS_Templates__c 
                                                  FROM ASF_Case_Category_Config__c 
                                                  WHERE CCC_External_Id__c =: cccId];
            String smsMD = cccLst[0].SMS_Templates__c ;
            List<String> smsMDLst =  smsMD.split(',');
            
            System.debug(smsMDLst);

            for(Customer_Notification_Config__mdt mdt: [SELECT Id,SMS_Template_Name__c,label,DeveloperName
                                                        FROM Customer_Notification_Config__mdt 
                                                        WHERE DeveloperName =: smsMDLst AND Active__c = true]){
                                                            System.debug('Check here ---> ');
                if(templateNameLabelMap.containsKey(mdt.SMS_Template_Name__c)){
                    SMSTempList.add(new ASF_SMSTemplateWrapper(mdt,templateNameLabelMap.get(mdt.SMS_Template_Name__c)));
                }
            }

        } catch(Exception objExp) {
            //Nebula.Logger.error(objExp.getMessage());
            //Nebula.Logger.saveLog(); 
        }

        return SMSTempList;
        
    }

    /****************************************************
     * @Description - Wrapper Class for Email templates
    *****************************************************/ 
    public class ASF_SMSTemplateWrapper {
        @AuraEnabled
        public Id id{get;set;}
        @AuraEnabled
        public String label{get;set;}
        @AuraEnabled
        public String mdtName{get;set;}
        @AuraEnabled
        public String templateName{get;set;}

        /****************************************************
         * @Description - paramaterized Construtor 
        *****************************************************/  
        public ASF_SMSTemplateWrapper(Customer_Notification_Config__mdt mdt, String label){
            this.id = mdt.Id;
            this.label = label;
            this.mdtName = mdt.DeveloperName;
            this.templateName = mdt.SMS_Template_Name__c;
        }

        /****************************************************
         * @Description - Default Construtor 
        *****************************************************/  
        public ASF_SMSTemplateWrapper(){
            this.id = ASF_Constants.STRING_BLANK;
            this.label = ASF_Constants.STRING_BLANK;
            this.mdtName = ASF_Constants.STRING_BLANK;
            this.templateName = ASF_Constants.STRING_BLANK;
        }
    }

    /****************************************************
    * @Description - get SMS Communication is enable against the SR  
    * @param caseId - Case Id.
    * @return -  Boolean.
    *****************************************************/
    @AuraEnabled
    public static Boolean isCommunicationEnabled(Id caseId){
        List<Case> cs = [SELECT CCC_External_Id__c FROM Case WHERE Id =: caseId LIMIT 1];
            String cccId = cs[0].CCC_External_Id__c;
            List<ASF_Case_Category_Config__c> cccLst = [SELECT Id, Send_SMS__c
                                                  FROM ASF_Case_Category_Config__c 
                                                  WHERE CCC_External_Id__c =: cccId];
            return cccLst[0].Send_SMS__c ;
    }

}