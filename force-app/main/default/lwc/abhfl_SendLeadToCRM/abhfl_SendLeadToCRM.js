import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendLead from '@salesforce/apex/ABHFL_LeadCreationAPI.sendLead';

export default class Abhfl_SendLeadToCRM extends LightningElement {
    @api recordId;

    @api invoke() {
         console.log(this.recordId);

         sendLead({leadId: this.recordId})
         .then(result => {
            this.showToast('Success', result, 'Success');
          })

        .catch(error => {
            this.showToast('Error', error, 'Error');
        });

        
    }

    showToast(titleMsg,response,toastType){
        this.dispatchEvent(
            new ShowToastEvent({
                title: titleMsg,
                message: response,
                variant: toastType
            })
        );
    }
}