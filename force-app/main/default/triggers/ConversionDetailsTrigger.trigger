trigger ConversionDetailsTrigger on Conversion_Details__c (after insert) {
    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }

    TriggerDispatcher.Run(new ConversionDetailsTriggerHandler());
}