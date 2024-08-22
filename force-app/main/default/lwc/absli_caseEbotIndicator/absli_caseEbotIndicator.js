import { LightningElement,api,wire } from 'lwc';
import displayEbotEmailIndicator from '@salesforce/apex/ABSLI_CaseIntegrationHelper.ebotEmailComposerHandler';
import ebotEmailIndicatorMessage from '@salesforce/label/c.ABSLI_EBOT_EMAIL_INDICATOR_MESSAGE';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class Absli_caseEbotIndicator extends NavigationMixin(LightningElement) {
    @api recordId;
    displayIndicator;
    ebotEmailIndicatorMessage = ebotEmailIndicatorMessage;
    record;
    displayEmailComposer;
    emailSent = false;

    connectedCallback(e){
		displayEbotEmailIndicator({ recId: this.recordId })
		.then(result => {
			//this.displayIndicator = result.displayMessage;
            this.record = result;
			this.error = undefined;
		})
		.catch(error => {
			this.error = error;
		})
        //console.log(JSON.stringify(this.case.data.fields.ABSLI_Case_Detail__r.value.fields.Email_Body__c.value));
	} 

    handleEmailComposer(e){
        if(this.emailSent){
            this.showToast({
                title: "Info",
                message: 'EBOT Draft Email has been sent',
                variant: "info",
            }); 
        }else{
            this.displayEmailComposer = true;
        }

    }

    closeModal(e){
        if(e.detail){
            this.emailSent = true;
        }
        this.displayEmailComposer = false;
    }

    showToast(e) {
        this.dispatchEvent(new ShowToastEvent(e));
    }
}