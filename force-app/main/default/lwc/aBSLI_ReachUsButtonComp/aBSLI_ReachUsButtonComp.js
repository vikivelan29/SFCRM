import { LightningElement, api, track } from 'lwc';
import getTemplateBody from "@salesforce/apex/ABSLI_ReachUsButtonController.getTemplateBody";
import sendCommunication from "@salesforce/apex/ABSLI_ReachUsButtonController.sendCommunication";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';

export default class ABSLI_ReachUsButtonComp extends LightningElement {
    @track templateBody;
    @api recordId;
    @track sendToUnregistered = false;

    async connectedCallback(){
        console.log('recordId in Child --> '+this.recordId);
        await getTemplateBody({whatId : this.recordId})
        .then((result)=>{
            this.templateBody = result;
        })
        .catch((error) => {
            console.log(error);
        });
    }
    handleSend(event){
        this.sendCommunication(this.recordId);
    }

    @api
    sendCommunication(parentRecordId){

        console.log('Class Name --> '+parentRecordId);
        if(this.IsInputValid()){
            let unregistedPhoneNumber = null;
            if(this.refs.unregisterednumber){
                unregistedPhoneNumber = this.refs.unregisterednumber.value;
            }
            sendCommunication({accountId : parentRecordId, unregisteredNumber: unregistedPhoneNumber})
            .then((result)=>{
                this.invokeCloseModal();
                this.showSuccessMessage('success', 'SMS triggered successfully.', '');
    
            })
            .catch((error)=>{
                console.log('error');
                this.showError('error', 'Unable to send SMS.', error);
                debugger;
    
            })
        }
        
    }
    handleToggle(event){
        this.sendToUnregistered = !this.sendToUnregistered;
    }
    IsInputValid(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField=>{
            debugger;
            if(!inputField.checkValidity()){
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    invokeCloseModal(){
        this.dispatchEvent(new CustomEvent('closepopup', {
            detail: {
                message: true
            }
        }));
    }
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }
    showSuccessMessage(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message
        });
        this.dispatchEvent(event);
    }
    

}