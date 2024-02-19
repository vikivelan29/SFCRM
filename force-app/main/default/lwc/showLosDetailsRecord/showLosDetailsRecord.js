import { LightningElement, api } from 'lwc';
import getRecord from '@salesforce/apex/ABHFL_ShowLosDetailsRecordController.getLosDetaisRecord';

export default class ShowLosDetailsRecord extends LightningElement {
    fields = [];

    // Flexipage provides recordId and objectApiName
    @api recordId;
    objectApiName = 'LOS_Details__c';
    losDetailsrecordId;

    connectedCallback(){
        console.log('recordId=='+this.recordId +' objectApiName=='+this.objectApiName);
        getRecord({leadId : this.recordId})
        .then((result) => {
            this.losDetailsrecordId = result;
            console.log('losDetailsrecordId=='+this.losDetailsrecordId);
        }).catch((error) => {
            console.log('error=='+error);
        })
    }


}