@isTest
public with sharing class ASF_customPicklistUtilityTest {
    @isTest
    public static void getPicklistValues(){
        List<ASF_customPicklistUtility.picklistValues> retVal = ASF_customPicklistUtility.getPicklistValues('Case','Stage__c');
        retVal.sort();
    }
}