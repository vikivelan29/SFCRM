import gettingOmniDocTemplate from '@salesforce/apex/ABHI_OmniDocViewController.templateDetails';
import { LightningElement, api } from 'lwc';

export default class ABHI_OmniDocAwaitDocuments extends LightningElement {

    @api recordId;
    @api objRow;
    @api objASFRec;
    @api strplanname;
    @api straccountid;
    @api straccountemail;
    clrInterval;
    clrTimeOut;

    connectedCallback(event){
        setTimeout(() => {
            this.clrInterval = setInterval(() => {
                this.callOmniDocTemplate(event);
            }, 2000);
        }, 10000);
        return new Promise((resolve, reject) => {
            this.clrTimeOut = setTimeout(() => {
                this.clearIntervalAndFireFailure(this.interval); 
            }, 20000);
            resolve('success!');
        });
    }

    clearIntervalAndFireFailure(event){
        clearInterval(event);
        const selectEvent = new CustomEvent('awaittimeout', { detail : 'File download process timed out. Please try again'});
        this.dispatchEvent(selectEvent);
    }

    callOmniDocTemplate(event){
        gettingOmniDocTemplate({strASFRecordId: this.objASFRec.Id, mapRow: this.objRow, strAssetId: this.recordId, strPlanName: this.strplanname, strAccountId: this.straccountid, strAccountEmail: this.straccountemail}).then((response)=>{
            console.log(response);
            if(response){
                const selectEvent = new CustomEvent('closeawaitscreen', { detail : response});
                this.dispatchEvent(selectEvent);
                clearInterval(this.clrInterval);
                clearTimeout(this.clrTimeOut);
            }
        }).catch(error => {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            }else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            const selectEvent = new CustomEvent('failedawaitscreen', { detail : message});
            this.dispatchEvent(selectEvent);
        });
    }

    disconnectedCallback(event){
        clearInterval(this.clrInterval);
        clearTimeout(this.clrTimeOut);
    }
}