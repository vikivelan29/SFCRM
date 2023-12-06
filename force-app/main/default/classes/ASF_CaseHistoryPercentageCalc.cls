/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-20-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
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
        
        setFieldValue(slaInMilliSec,bh,startTime,c,firstThreshold,secondThreshold,thirdThreshold,'Case_SLA_Threshold_1__c','Case_SLA_Threshold_2__c','Case_SLA_Threshold_3__c');
    }
    public void setStagePercSLAFields(long slaInMilliSec,String bh,DateTime startTime,Case c){
        SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
        // Stage SLA Threshold
        decimal firstStageThreshold = thresholdController.Stage_SLA_Threshold_1__c ;
        decimal secondStageThreshold = thresholdController.Stage_SLA_Threshold_2__c ;
        decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c ; 
        
        setFieldValue(slaInMilliSec,bh,startTime,c,firstStageThreshold,secondStageThreshold,thirdStageThreshold,'Stage_SLA_Threshold_1__c','Stage_SLA_Threshold_2__c','Stage_SLA_Threshold_3__c');
    }
    private void setFieldValue(long slaInMilliSec,String bh,DateTime startTime,Case c,decimal firstThreshold,
                               decimal secondThreshold,decimal thirdThreshold,
                               String firstFieldApiName,String secondFieldApiName,String thirdFieldApiName)
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
        
    }
    
}