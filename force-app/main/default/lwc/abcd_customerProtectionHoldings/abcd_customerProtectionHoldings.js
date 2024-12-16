import { LightningElement, track, api } from 'lwc';
import getTabData from '@salesforce/apex/ABCD_CustomerInfoController.getTabData';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Abcd_customerProtectionHoldings extends LightningElement 
{
    @api recordId;
    error;
    tbLabel = 'Protection';
    isLoading = false;
    @track liDetails;
    @track hiDetails;
    @track miDetails;

    connectedCallback(){
        this.fetchProtectionHoldings();
    }

    handleRefresh(){
        this.fetchProtectionHoldings();
    }

    fetchProtectionHoldings(){
        this.isLoading = true;
        getTabData({ tabLabel:this.tbLabel , recordId: this.recordId})
        .then((data) => {
            if (data) {
                let resp = JSON.parse(data);
                if(resp.status == 'Success'){
                    if(resp.holdingsProtectionInfo.liDetails){
                        this.liDetails = resp.holdingsProtectionInfo.liDetails;
                    }
                    if(resp.holdingsProtectionInfo.hiDetails){
                        this.hiDetails = resp.holdingsProtectionInfo.hiDetails;
                    }
                    if(resp.holdingsProtectionInfo.miDetails){
                        this.miDetails = resp.holdingsProtectionInfo.miDetails;
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