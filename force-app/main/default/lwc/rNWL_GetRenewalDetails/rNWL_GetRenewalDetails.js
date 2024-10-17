import { LightningElement,wire,api } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import ACCOUNT_RECORDTYPE from '@salesforce/schema/Opportunity.Account.RecordType.DeveloperName';  
import POLICY_ID_FIELD from "@salesforce/schema/Opportunity.Policy__r.ABHI_Policy_Id__c";

const fields = [ACCOUNT_RECORDTYPE, POLICY_ID_FIELD];

export default class RNWL_GetRenewalDetails extends LightningElement {
    @api recordId;
    isIndividalAccount = false;
    //policyId;
    
    @wire(getRecord, { recordId: '$recordId', fields }) 
    record({ error, data }){
        if (data) {
            let accType = getFieldValue(data, ACCOUNT_RECORDTYPE); 
            if(accType){ 
                this.isIndividalAccount = accType == 'Individual';
               // this.policyId = data.fields.Policy__r.value.fields.ABHI_Policy_Id__c.value; 
            }
        }
    }
}