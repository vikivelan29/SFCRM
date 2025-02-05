import { LightningElement,api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import redirectToCustomerPortalValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.redirectToCustomerPortalValidation';
import generateCustomerURL from '@salesforce/apex/ABSLI_CreateCaseValidationsController.generateCustomerPortalURL';

export default class Absli_redirectToCustomerPortal extends LightningElement {

    @api recordId;
    @track errorMessage = 'Evaluating Criteria...';
    connectedCallback(){
        this.validateBeforeRedirecting();
    }

    validateBeforeRedirecting(){
        redirectToCustomerPortalValidation({caseId:this.recordId})
            .then(result=>{
                let response = JSON.parse(JSON.stringify(result))[0];
                if(response.status=='success'){
                    this.generateCustomerPortalURL();
                }else if(response.status =='error'){
                    this.showToast('ERROR',response.message,response.status);
                    this.closeModal();
                }
            })
            .catch(error=>{
                console.error('Error: ', error);
            });
    }
    closeModal() {
        const closeEvent = new CustomEvent('closepopup', {});
        this.dispatchEvent(closeEvent);
    }

    generateCustomerPortalURL(){
        generateCustomerURL({caseId:this.recordId})
            .then(result=>{
                if(result)
                window.open(result,'_blank');
            })
            .catch(error=>{
                console.error('Error: ',error);
            })
    }

    showToast(title,message,variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}