/*********************************************************
*Class        :  ASF_EmailRelayLoadBalancer 
*Author       :  Virendra Patil
*Description  :  This is scheduled class to run every 15 mins, and repoint the email relay to different set of authentication user based 
:  on the user configuration in Custom Metadata - EmailRelayAuthUser__mdt.
*********************************************************/
public without sharing class ASF_EmailRelayLoadBalancer implements Schedulable {
    public static void execute(SchedulableContext sc){
        integer iLimitEmailAtExchange = 8000;
        if(System.Label.EmailRelayThreshold != null ){
            iLimitEmailAtExchange = Integer.ValueOf(System.Label.EmailRelayThreshold);
        }
        Map<Integer,EmailRelayAuthUser__mdt> mIdxEmailRelayConfig = new Map<Integer,EmailRelayAuthUser__mdt>();
        
        // VIRENDRA - VERY VERY IMPORTANT - Order to start from 0, At the start of the day , when 10 DIVIDE BY 8000 --> result is 0 index.
        for(EmailRelayAuthUser__mdt mdt : [SELECT Id, Auth_User_Name__c, Auth_User_Password__c, Order__c FROM EmailRelayAuthUser__mdt ORDER BY Order__c ASC]){
            mIdxEmailRelayConfig.put(Integer.ValueOf(mdt.Order__c), mdt);
        }
        integer iNumberOfEmailsInDay = getNumberOfSentEmailToday();
        integer iDivision = Integer.ValueOf(Math.floor(iNumberOfEmailsInDay/iLimitEmailAtExchange));
        integer iIdxOfUser = Math.Mod(iDivision,mIdxEmailRelayConfig.keySet().size());
        System.debug('iIdxOfUser --> '+iIdxOfUser);
        configureEmailRelay(mIdxEmailRelayConfig.get(iIdxOfUser));
    }
    private static integer getNumberOfSentEmailToday(){
        List<EmailMessage> messages = [SELECT ID FROM EmailMessage WHERE Incoming = FALSE AND CREATEDDATE = TODAY ];
        integer iCountOfEmail = messages.size();
        return iCountOfEmail;
    }
    private static void configureEmailRelay(EmailRelayAuthUser__mdt mdt){
        EmailRelay relay = [SELECT Host, Port, Username, Password, AuthType, TlsSetting, IsRequireAuth, Id FROM EmailRelay];
        if((relay.Username.trim().toLowerCase() != mdt.Auth_User_Name__c.trim().toLowerCase()) || Test.IsRunningTest()){
            relay.Username = mdt.Auth_User_Name__c;
            relay.Password = mdt.Auth_User_Password__c;
            update relay;
        }
    }
    
}