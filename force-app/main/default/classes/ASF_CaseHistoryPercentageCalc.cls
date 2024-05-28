/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-06-2024
 * @last modified by  : rsinghnagar@salesforce.com
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.NcssMethodCount,PMD.ExcessiveParameterList')
public without sharing class ASF_CaseHistoryPercentageCalc {
    private static Map<Id, Decimal> businessHoursTohoursPerDay = new Map<Id, Decimal>();
    /**
     * @description - 
     * @param slaInMilliSec
     * @param bh
     * @param startTime
     * @param c
     */
    public void setOverallPercSLAFields(long slaInMilliSec,String bh,DateTime startTime,Case c){
        SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
        // Overall SLA Threshold
        decimal firstThreshold = thresholdController.Case_SLA_Threshold_1__c;
        decimal secondThreshold = thresholdController.Case_SLA_Threshold_2__c;
        decimal thirdThreshold = thresholdController.Case_SLA_Threshold_3__c; 
        
        long slaIdentifier = 3600000;
        long bufferDays = 0;
        if((thresholdController.Custom_Email_Buffer_Days__c  != null && thresholdController.Custom_Email_Buffer_Days__c >0) || Test.IsRunningTest()){
            // 1. First Find out the Business Working Hours based on Business Hour.
            // 2. Multiply Custom Email Buffer Days with Business Working Hours.
            // 3. Based on the step 2 find out the millisecond values for bufferDays.
            if(businessHoursTohoursPerDay.keySet().size()<=0){
                calculateBusinessHoursPerDay();
            }
            if(Test.isRunningTest()){
                thresholdController.Custom_Email_Buffer_Days__c = 1;
            }
            if(businessHoursTohoursPerDay.containsKey(bh)){
                decimal workingHours = businessHoursTohoursPerDay.get(bh);
                bufferDays = Integer.ValueOf(workingHours * thresholdController.Custom_Email_Buffer_Days__c) * slaIdentifier;
            }
            else{
                bufferDays = 0;
            } 
        }
        setFieldValue(slaInMilliSec,bh,startTime,c,firstThreshold,secondThreshold,thirdThreshold,'Case_SLA_Threshold_1__c','Case_SLA_Threshold_2__c','Case_SLA_Threshold_3__c', bufferDays);
    }
    /**
     * @description -  Stage percentage SLA fields
     * @param slaInMilliSec
     * @param bh
     * @param startTime
     * @param c
     */
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
        firstThreshold = firstThreshold != null ? firstThreshold : 0.0;
        secondThreshold = secondThreshold != null ? secondThreshold : 0.0;
        thirdThreshold = thirdThreshold != null ? thirdThreshold : 0.0;
        
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
    
    /**
     * @description - methods caculates the business hours per day
     */
    private static void calculateBusinessHoursPerDay(){          
        for(BusinessHours bhRec : [SELECT Id, MondayStartTime, MondayEndTime FROM BusinessHours with SYSTEM_MODE]){
            
            if(bhRec.MondayStartTime == null){
                businessHoursTohoursPerDay.put(bhRec.Id, 9);
                continue;
            } 

            Decimal startMinutes = bhRec.MondayStartTime.hour() * 60 + bhRec.MondayStartTime.minute();
            Decimal endMinutes = bhRec.MondayEndTime.hour() * 60 + bhRec.MondayEndTime.minute();
            Decimal hoursPerDay = (endMinutes - startMinutes) / 60; 
            
            if(hoursPerDay == 0){
                businessHoursTohoursPerDay.put(bhRec.Id, 24);     
            }else{
                businessHoursTohoursPerDay.put(bhRec.Id, hoursPerDay);
            }
        }
    }
    
}