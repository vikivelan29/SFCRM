import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmailForCannedResponse from '@salesforce/apex/ABSLI_CannedResponse_Controller.sendEmailForCannedResponse';

export default class Absli_CannedResponse extends LightningElement {

    @api recordId;

    @api invoke() {
        sendEmailForCannedResponse({recordId : this.recordId})
        .then(result => {
            let isSuccess = result.isSuccess;
            let errorMessage = result.errorMessage;
            let successMessage = result.successMessage;
            if(isSuccess) {
                this.showToast('Success', successMessage, 'success', 'dismissable');
            } 
            else {
                this.showToast('Error', errorMessage, 'error', 'dismissable');
            }
        })
        .catch(error => {
            console.log('Error inside sendEmailForCannedResponse-- '+error);
        });
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant || 'info', // Default variant is 'info'
            mode: mode || 'dismissable' // Default mode is 'dismissable'
        });
        this.dispatchEvent(event);
    };
    

}