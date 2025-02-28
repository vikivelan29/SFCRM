import { LightningElement, track, api } from 'lwc';
import getTabData from '@salesforce/apex/ABCD_CustomerInfoController.getTabData';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Abcd_customerInfoView extends LightningElement 
{
    @api recordId;
    error;
    tbLabel = 'Asset Holdings';
    isLoading = false;
    @track mfDetails;
    @track dgDetails;
    @track dsDetails;
    @track dmDetails;
    @track pcDetails;
    @track status;
    @track apiMessage;

    connectedCallback(){
        this.fetchAssetHoldings();
    }

    handleRefresh(){
        this.fetchAssetHoldings();
    }

    fetchAssetHoldings(){
        this.isLoading = true;
        getTabData({ tabLabel:this.tbLabel , recordId: this.recordId})
        .then((data) => {
            if (data) {
                let resp = JSON.parse(data);
                if(resp.status == 'Success'){
                    this.status = resp.status;
                    if(resp.holdingsAssetsInfo.mfDetails){
                        this.mfDetails = resp.holdingsAssetsInfo.mfDetails;
                    }
                    if(resp.holdingsAssetsInfo.dgDetails){
                        this.dgDetails = resp.holdingsAssetsInfo.dgDetails;
                    }
                    if(resp.holdingsAssetsInfo.dsDetails){
                        let dsDetails = resp.holdingsAssetsInfo.dsDetails;
                        if(dsDetails.lastTransactionDate){
                        }
                        this.dsDetails = dsDetails;
                    }
                    if(resp.holdingsAssetsInfo.dmDeatils){
                        let dmDeatils = resp.holdingsAssetsInfo.dmDeatils;
                        if(dmDeatils.accountOpeningDate){
                        }
                        this.dmDetails = dmDeatils;
                    }
                    if(resp.holdingsAssetsInfo.pcDetails){
                        this.pcDetails = resp.holdingsAssetsInfo.pcDetails;
                    }
                }
                else{
                    this.status = resp.status;
                    this.apiMessage = resp.message;
                    this.isLoading = false;
                }
            }else{
                this.status = 'failure';
                this.apiMessage = 'An API Error Occured. Please try again or Contact your Admin.';
            }
            this.isLoading = false;
        })
        .catch((error) => {
            this.error = error;
            this.isLoading = false;
            if (error && error.body && error.body.message) {
                this.apiMessage = 'An API Error occured: '+ error.body.message;
            } else if (error && error.message) {
                this.apiMessage = 'An API Error occured: '+ error.message;
            } else {
                this.apiMessage = 'An unexpected error occurred. Please try later or contact your admin';
            }
        });

    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}