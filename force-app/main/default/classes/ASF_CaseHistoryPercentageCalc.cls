/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-06-2024
 * @last modified by  : rsinghnagar@salesforce.com
**/
public class ASF_CaseHistoryPercentageCalc {
    public void setOverallPercSLAFields(long slaInMilliSec,String bh,DateTime startTime,Case c){
        SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
        System.debug('@@@thresholdController '+thresholdController);
        // Overall SLA Threshold
        decimal firstThreshold = thresholdController.Case_SLA_Threshold_1__c;
        decimal secondThreshold = thresholdController.Case_SLA_Threshold_2__c;
        decimal thirdThreshold = thresholdController.Case_SLA_Threshold_3__c; 
        
        // Stage SLA Threshold
        decimal firstStageThreshold = thresholdController.Stage_SLA_Threshold_1__c ;
        decimal secondStageThreshold = thresholdController.Stage_SLA_Threshold_2__c ;
        decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c ; 
        System.debug('@@@firstThreshold '+firstThreshold+' '+secondThreshold);
        System.debug('@@@firstThreshold2 '+thresholdController.Customer_Email_buffer_hours__c);
        long slaIdentifier = 3600000;
        long bufferDays = Integer.valueOf(thresholdController.Customer_Email_buffer_hours__c) * slaIdentifier;
        setFieldValue(slaInMilliSec,bh,startTime,c,firstThreshold,secondThreshold,thirdThreshold,'Case_SLA_Threshold_1__c','Case_SLA_Threshold_2__c','Case_SLA_Threshold_3__c', bufferDays);
    }
    public void setStagePercSLAFields(long slaInMilliSec,String bh,DateTime startTime,Case c){
        SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
        // Stage SLA Threshold
        decimal firstStageThreshold = thresholdController.Stage_SLA_Threshold_1__c ;
        decimal secondStageThreshold = thresholdController.Stage_SLA_Threshold_2__c ;
        decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c ; 
        
        setFieldValue(slaInMilliSec,bh,startTime,c,firstStageThreshold,secondStageThreshold,thirdStageThreshold,'Stage_SLA_Threshold_1__c','Stage_SLA_Threshold_2__c','Stage_SLA_Threshold_3__c', null);
    }
    private void setFieldValue(long slaInMilliSec,String bh,DateTime startTime,Case c,decimal firstThreshold,
                               decimal secondThreshold,decimal thirdThreshold,
                               String firstFieldApiName,String secondFieldApiName,String thirdFieldApiName,
                               long bufferDays)
    {
        long slaMulitplierInLong = 3600000;
        System.debug('@@@slaInMilliSec'+slaInMilliSec+' '+firstThreshold);
        String sla50percentageHoursInMilli = String.ValueOf(slaInMilliSec * firstThreshold);
        String sla75percentageHoursInMilli = String.ValueOf(slaInMilliSec * secondThreshold);
        String sla90percentageHoursInMilli = String.ValueOf(slaInMilliSec * thirdThreshold);
        
        
        
        
        long aggred50SLAHours = Decimal.VALUEOF(sla50percentageHoursInMilli).round(system.RoundingMode.CEILING);
        long aggred75SLAHours = Decimal.valueOf(sla75percentageHoursInMilli).round(system.RoundingMode.CEILING);
        long aggred90SLAHours = Decimal.valueOf(sla90percentageHoursInMilli).round(system.RoundingMode.CEILING);

        
        DateTime dt50Percentage = BusinessHours.add(bh, startTime, aggred50SLAHours);
        DateTime dt75Percentage = BusinessHours.add(bh, startTime, aggred75SLAHours);
        DateTime dt90Percentage = BusinessHours.add(bh, startTime, aggred90SLAHours);
        
        c.put(firstFieldApiName, dt50Percentage);
        c.put(secondFieldApiName, dt75Percentage);
        c.put(thirdFieldApiName,dt90Percentage);
        if(bufferDays != null && c.Overall_Case_Closure_SLA__c != null){
            c.Overall_SLA_plus_X_days__c = BusinessHours.add(c.BusinessHoursId,c.Overall_Case_Closure_SLA__c, bufferDays);
        }
    }
    
}