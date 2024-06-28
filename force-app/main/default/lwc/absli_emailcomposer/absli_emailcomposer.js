import { LightningElement,api } from 'lwc';
import LightningModal from 'lightning/modal';
//import emailTemplate from "@salesforce/resourceUrl/LoanRelatedTemplate14";
import sendMail from '@salesforce/apex/ABSLI_CaseIntegrationHelper.sendMail';

export default class Absli_emailcomposer extends LightningModal {
    previewMode = false;
    @api record;
    @api recid;
    changeHandler(event) {
        this.record = JSON.parse(JSON.stringify(this.record));
        const fieldName = event.target.name;
        this.record[fieldName] = event.target.value;
    }

    connectedCallBack(){
        console.log('e');
    }
    handleModes(e){
        console.log(this.emailTemplate);
        this.previewMode = !this.previewMode;
    }

    sendMail(e){
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if(allValid){
            sendMail({ recId: this.recid,
                emailWrapperStr:JSON.stringify(this.record) })
            .then(result => {
                this.close();
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
            })
        }
    }
}