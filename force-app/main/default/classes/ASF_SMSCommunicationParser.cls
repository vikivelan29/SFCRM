/*********************************************************
*@Name           :   ASF_SMSCommunicationParser
*@Author         :   Salesforce
*@Since          :    
*@description    :   Parser class for SMS Communication 
*@History
Name                Date                  Change Description

*********************************************************/
public without sharing class ASF_SMSCommunicationParser {
     /****************************************************
    * @description RequestBody
    *****************************************************/ 
    public class RequestBody{
        
        public String mobileNo;
    }

    /****************************************************
    * @description get Contact Details for the Case  
    * @param srId
    * @return List<ASF_ContactDetailsWrapper>
    *****************************************************/

    @AuraEnabled(cacheable=true)
    public static List<ASF_ContactDetailsWrapper> getListOfContact(String srId){
        List<ASF_ContactDetailsWrapper> conLst = new List<ASF_ContactDetailsWrapper>();
        try {
            List<Case> cs = [SELECT AccountId,Lead__c FROM Case WHERE Id =: srId WITH SECURITY_ENFORCED LIMIT 1];
            Id accId = cs[0].AccountId;
            Id leadId = cs[0].Lead__c;
            if(accId != null){
                for(Contact con: [SELECT Id, Name, MobilePhone FROM Contact WHERE AccountId  =: accId WITH SYSTEM_MODE])
                {
                    conLst.add(new ASF_ContactDetailsWrapper(con));
                }
            }
            if(leadId != null){
                for(Lead prospect : [SELECT Id,Name,MobilePhone FROM Lead WHERE Id =: leadId WITH SYSTEM_MODE])
                {
                    conLst.add(new ASF_ContactDetailsWrapper(prospect));
                } 
            }
            
            
            
        } catch(Exception objExp) {
            //Nebula.Logger.error(objExp.getMessage());
            //Nebula.Logger.saveLog(); 
        }
        
        return conLst;
        
    }
    
    /****************************************************
    * @description  Wrapper Class for Contact Details
    *****************************************************/ 
    public class ASF_ContactDetailsWrapper {
       /* @description  Wrapper Class for Contact Details*/
        @AuraEnabled
        public Id id{get;set;}
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String phone{get;set;}
        
        /****************************************************
        * @description  paramaterized Construtor 
        * @param con
        *****************************************************/  
        public ASF_ContactDetailsWrapper(Contact con){
            this.id = con.Id;
            this.name = con.Name;
            this.phone = con.MobilePhone;
        }
        /****************************************************
        * @description  paramaterized Construtor 
        * @param prospect
        *****************************************************/  
        public ASF_ContactDetailsWrapper(Lead prospect){
            this.id = prospect.Id;
            this.name = prospect.Name;
            this.phone = prospect.MobilePhone;
        }
        
        /****************************************************
        * @description - Default Construtor 
        *****************************************************/  
        public ASF_ContactDetailsWrapper(){
            this.id = ASF_Constants.STRING_BLANK;
            this.name = ASF_Constants.STRING_BLANK;
            this.phone = ASF_Constants.STRING_BLANK;
        }
    }
    
    
    /****************************************************
    * @description - get Whatsapp Template list for the Case  
    * @param caseId 
    * @return List<ASF_SMSTemplateWrapper>
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
                                                        WHERE CCC_External_Id__c =: cccId
                                                        WITH SECURITY_ENFORCED];
            String smsMD = cccLst[0].SMS_Templates__c ;
            List<String> smsMDLst =  smsMD.split(',');
                        
            for(Customer_Notification_Config__mdt mdt: [SELECT Id,SMS_Template_Name__c,label,DeveloperName
                                                        FROM Customer_Notification_Config__mdt 
                                                        WHERE DeveloperName =: smsMDLst AND Active__c = true
                                                        WITH SECURITY_ENFORCED]){
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
    * @description - Wrapper Class for Email templates
    *****************************************************/ 
    public class ASF_SMSTemplateWrapper {
        /* @description Id */ @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String mdtName{get;set;}
        @AuraEnabled public String templateName{get;set;}
        
        /****************************************************
        * @description paramaterized Construtor 
        * @param mdt
        * @param label
        *****************************************************/  
        public ASF_SMSTemplateWrapper(Customer_Notification_Config__mdt mdt, String label){
            this.id = mdt.Id;
            this.label = label;
            this.mdtName = mdt.DeveloperName;
            this.templateName = mdt.SMS_Template_Name__c;
        }
        
        /****************************************************
        * @description - Default Construtor 
        *****************************************************/  
        public ASF_SMSTemplateWrapper(){
            this.id = ASF_Constants.STRING_BLANK;
            this.label = ASF_Constants.STRING_BLANK;
            this.mdtName = ASF_Constants.STRING_BLANK;
            this.templateName = ASF_Constants.STRING_BLANK;
        }
    }
    
    /****************************************************
    * @description  get SMS Communication is enable against the SR  
    * @param caseId 
    * @return Boolean.
    *****************************************************/
    @AuraEnabled
    public static Boolean isCommunicationEnabled(Id caseId){
        List<Case> cs = [SELECT CCC_External_Id__c FROM Case WHERE Id =: caseId WITH SECURITY_ENFORCED LIMIT 1];
        String cccId = cs[0].CCC_External_Id__c;
        List<ASF_Case_Category_Config__c> cccLst = [SELECT Id, Send_SMS__c
                                                    FROM ASF_Case_Category_Config__c 
                                                    WHERE CCC_External_Id__c =: cccId
                                                    WITH SECURITY_ENFORCED];
        return cccLst[0].Send_SMS__c ;
    }
    
}