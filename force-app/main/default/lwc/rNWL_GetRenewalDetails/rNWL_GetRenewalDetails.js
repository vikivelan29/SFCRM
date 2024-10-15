import { LightningElement,wire,api } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import ACCOUNT_RECORDTYPE from '@salesforce/schema/Opportunity.Account.RecordType.DeveloperName';   
const fields = [ACCOUNT_RECORDTYPE];

export default class RNWL_GetRenewalDetails extends LightningElement {
    @api recordId;
    isIndividalAccount; 

    @wire(getRecord, { recordId: '$recordId', fields }) 
    record({ error, data }){
        if (data) {
            let accType = getFieldValue(data, ACCOUNT_RECORDTYPE); 
            if(accType){ 
                this.isIndividalAccount = accType == 'Individual'; 
            }
        }
    } 
}