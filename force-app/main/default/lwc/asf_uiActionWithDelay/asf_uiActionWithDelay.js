import { LightningElement, api } from 'lwc';
import runIntegration from "@salesforce/apex/ASF_IntegrationsController.runIntegration";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';
import TimeDelay from '@salesforce/label/c.ASF_UIActionDelay';
import getAllCaseIntegrations from '@salesforce/apex/ASF_IntegrationsController.getAllCaseIntegrations';

export default class Asf_uiActionWithDelay extends LightningElement {
    @api recordId;
    @api caseIntId;
    @api intExtId;
    @api selectedAction;
    @api allIntegrations;
    @api caseRecord;
    caseIntId;
    message;
    showSpinner = false;
    currentURL;
    delayTime = TimeDelay;


    connectedCallback() {
    }

    closeModal() {
        const closeEvent = new CustomEvent('closepopup', {});
        this.dispatchEvent(closeEvent);
    }

    async processResponse(result) {
        if (result.status != 'Success') {
            this.handleResponse('error', 'Error while running Integration', result.response);
        }
        else if(result.status == 'Success'){
            let integrationArr = [this.intExtId];
            this.interval = setInterval(() => {
                getAllCaseIntegrations({caseId: this.recordId, intExtIds:integrationArr})
                .then((result) => {
                    if(result && result.length > 0){
                        for(let rec in result){
                            if(result[rec].Status__c == 'Success'){
                                this.handleResponse('success', 'Success', 'Integration Completed.');
                            }
                            else if(result[rec].Status__c == 'Failure'){
                                this.handleResponse('error', 'Error','Integration Failed. Kindly check the logs.' );
                            }
                            else{
                                this.handleResponse('Info', 'Info', 'Integration Pending.Kindly check the logs.');
                            }
                            break;
                        }
                    }
                })
                .catch((error) => {
                    this.handleResponse('Info', 'Info', 'Integration Pending.Kindly check the logs.');
                })
                clearInterval(this.interval);
            }, this.delayTime);
        }
        
    }

    async submit() {
        let selectedInt = this.allIntegrations.find((el) => el.Id == this.selectedAction.id);
        this.showSpinner = true;
        if (selectedInt) {
            runIntegration({ integ: selectedInt, caseRec: this.caseRecord })
                .then((result) => {
                    this.processResponse(result);
                })
                .catch((error) => {
                    this.handleResponse('error', 'Error while running Integration', result.response);
                })
        }
        clearInterval(this.interval);
    }

    //utility method
    showMessage(variant, title, message) {
        let errMsg = reduceErrors(message);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }

    handleResponse(toastType,toastMessage,message){
        this.showSpinner = false;
        this.showMessage(toastType, toastMessage, message);
        this.closeModal();        
    }
}