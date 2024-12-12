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
                    if(resp.holdingsAssetsInfo.mfDetails){
                        this.mfDetails = resp.holdingsAssetsInfo.mfDetails;
                    }
                    if(resp.holdingsAssetsInfo.dgDetails){
                        this.dgDetails = resp.holdingsAssetsInfo.dgDetails;
                    }
                    if(resp.holdingsAssetsInfo.dsDetails){
                        let dsDetails = resp.holdingsAssetsInfo.dsDetails;
                        if(dsDetails.lastTransactionDate){
                            let dtArr = dsDetails.lastTransactionDate.split('-');
                            dsDetails.lastTransactionDate =dtArr.join('/');
                        }
                        this.dsDetails = dsDetails;
                    }
                    if(resp.holdingsAssetsInfo.dmDeatils){
                        let dmDeatils = resp.holdingsAssetsInfo.dmDeatils;
                        if(dmDeatils.accountOpeningDate){
                            let dtArr = dmDeatils.accountOpeningDate.split('-');
                            dmDeatils.accountOpeningDate =dtArr.join('/');
                        }
                        this.dmDetails = dmDeatils;
                    }
                    if(resp.holdingsAssetsInfo.pcDetails){
                        this.pcDetails = resp.holdingsAssetsInfo.pcDetails;
                    }
                }
            }
            this.isLoading = false;
        })
        .catch((error) => {
            this.error = error;
            this.isLoading = false;
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