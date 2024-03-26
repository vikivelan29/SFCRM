import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from 'lightning/uiRecordApi';
import  getEnachStatus from '@salesforce/apex/ABFL_ENACH_Status_Controller.getENACHStatus';
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';

const FIELDS = ["Asset.Client_Code__c"];


export default class AbflENACHStatus extends LightningElement {
    @api recordId;
    label = {
		errorMessage
	};

    assetClientCode;
    isLoading = false;
    showBaseViewScreen = false;
    enachStatusResult;
    apiName = 'ABFL_Enach_Status';

    connectedCallback(){
       
    }

    @wire( getRecord,{ recordId: "$recordId", fields: FIELDS })
    wiredAssetRecord({error, data}){
        console.log('from wire..')
        if (error) {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
              message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
              message = error.body.message;
            }
            this.showToast('Error', message, 'error');
        } 
        else if (data) {
            console.log('from data ==> ', data)
            this.assetClientCode = data.fields.Client_Code__c? data.fields.Client_Code__c.value : '';
            //this.callGetEnachStatus();
        }
    }

    callGetEnachStatus(){
        if(this.assetClientCode){
            getEnachStatus({'customerId':this.assetClientCode}).then(result=>{
                this.enachStatusResult = result;
                console.log('Result1 ==> ', result);
                this.isLoading = false;
                if (this.enachStatusResult) {
                    this.showBaseViewScreen = true;
                } else {
                    console.log('error ==> ');
                    this.showToast("Error", this.label.errorMessage, 'error');
                }

            }).catch(error=>{
                console.log('error ==> ', error);
                this.isLoading = false;
            })
        }
    }
    
    handleShowEnachStatus(event){
        this.showBaseViewScreen = false;
        this.isLoading= true;
        this.callGetEnachStatus()
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}