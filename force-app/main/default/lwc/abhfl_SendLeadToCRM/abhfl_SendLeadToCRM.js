import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendLead from '@salesforce/apex/ABHFL_LeadCreationAPI.sendLead';

export default class Abhfl_SendLeadToCRM extends LightningElement {
    @api recordId;
    
    @api invoke() {
        
        sendLead({leadId: this.recordId, executingFromTrigger: false})
        .then(result => {
            if(result.includes('Failed')){
                this.showToast('Error', result, 'error');
            }else{
                this.showToast('Success', result, 'Success');
            }  
        })

        .catch(error => {
            let errorMessage = 'Send lead to CRM failed';
            if ( error.body.message) {
                errorMessage = error.body.message;
            }
            this.showToast('Error', errorMessage, 'Error');
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