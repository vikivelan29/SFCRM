import { LightningElement, api, track } from 'lwc';
import fetchAssets from "@salesforce/apex/ABSLI_FetchPolicyDetails.getPolicyDetailsFromDWH";

export default class Absli_fetchPolicyDetail extends LightningElement {
    @api recordId;
    @track data;
    @track responseCode;
    @track responseMsg;
    @track showError = false;
    @track showLoader = true;

    connectedCallback(){
        this.invokeIntegration();

    }
    invokeIntegration(){
        fetchAssets({policyId : this.recordId})
        .then((result)=>{
            debugger;
            console.log(result);
            try{
                this.data = result.lstDetails;
                this.responseCode = result.ReturnCode;
                if(this.responseCode != "0" && this.ReturnCode != "00"){
                    this.responseMsg = result.ReturnMessage;
                }
                this.showLoader = false;

            }
            catch(ex){
                this.responseMsg = 'Something went wrong ! Please contact System Administrator.';
                this.showError = true;
                this.showLoader = false;
            }
            

        })
        .catch((error)=>{
            debugger;
            console.log(error);
            this.responseMsg = 'Something went wrong ! Please contact System Administrator.';
            this.showError = true;
            this.showLoader = false;

        })
    }
}