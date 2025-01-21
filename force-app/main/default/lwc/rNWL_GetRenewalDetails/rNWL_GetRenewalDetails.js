import { LightningElement,wire,api } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import POLICY_TYPE from '@salesforce/schema/Opportunity.Policy__r.PolicyType__c';  
const fields = [POLICY_TYPE];

export default class RNWL_GetRenewalDetails extends LightningElement {
    @api recordId;
    isIndividalAccount = false;  
    isNonIndividalAccount = false; 

    @wire(getRecord, { recordId: '$recordId', fields }) 
    record({ error, data }){
        if (data) {
            let policyType = getFieldValue(data,POLICY_TYPE);
            if(policyType){  
                if(policyType.toUpperCase() == 'RETAIL'){
                    this.isIndividalAccount = true;
                }else{
                    this.isNonIndividalAccount = true;
                } 
            }
        }
    } 
}
