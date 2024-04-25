import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from 'lightning/uiRecordApi';
import  outstandingCharges from '@salesforce/apex/ABFL_OutstandingChargesController.getOutstandingCharges';

const FIELDS = ["Asset.LAN__c"];

export default class Abfl_OutstandingCharges extends LightningElement {
    @api recordId;

    customerLoanAccountNumber;
    isLoading = false;
    showBaseViewScreen = false;
    outstandingChargesResult;
    apiName = 'ABFL_Outstanding_Charges';
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
            this.customerLoanAccountNumber = data.fields.LAN__c? data.fields.LAN__c.value : '';
            //this.callOutstandingCharges();
        }
    }

    callOutstandingCharges(){
        if(this.customerLoanAccountNumber){
            outstandingCharges({'customerLAN':this.customerLoanAccountNumber}).then(result=>{
                this.outstandingChargesResult = result;
                console.log('result ==> ', result);
                this.outstandingChargesResult.payload = JSON.stringify(JSON.parse(result.payload).success[0]);
                //this.outstandingChargesResult.statusCode = JSON.stringify(JSON.parse(result.payload).statusCode);
                if (this.outstandingChargesResult) {
                    this.showBaseViewScreen = true;
                } else {
                    console.log('error ==> ');
                    this.showToast("Error", this.label.errorMessage, 'error');
                }
                this.isLoading = false;
            }).catch(error=>{
                console.log('error ==> ', error);
                let parsedjson = JSON.parse(this.outstandingChargesResult.payload);
                var errormsg = '';
                if (Array.isArray(parsedjson.error)) {
                    errormsg =  parsedjson.error.map((e) => e.value).join(", ");
                }else{
                    errormsg = parsedjson?.error?.value? parsedjson.error.value : 'Something went wrong. Please contact System Admin.'
                }
                this.showToast('Error', errormsg, 'error');
                this.isLoading = false;
            })
        }
        else{
            this.showToast('Error', 'Loan Account Number is Blank, Please fill the valid/correct Loan Account Number', 'error');
            this.isLoading = false;
        }
        
    }
    
    handleShowEnachStatus(event){
        this.showBaseViewScreen = false;
        this.isLoading= true;
        this.callOutstandingCharges()
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