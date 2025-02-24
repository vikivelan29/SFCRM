import { LightningElement, track, api } from 'lwc';
import getTabData from '@salesforce/apex/ABCD_CustomerInfoController.getTabData';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Abcd_CustomerLiabilities extends LightningElement {
    @track accordions = null; 
    @api recordId;
    error;
    tbLabel = 'Liabilities';
    @track plDetails;
    @track blDetails;
    @track hflDetails;

    connectedCallback(){
        this.fetchCustomerLiabilities();
    }

    handleRefresh(){
        this.fetchCustomerLiabilities();
    }

    fetchCustomerLiabilities(){
        this.isLoading = true;
        getTabData({ tabLabel:this.tbLabel , recordId: this.recordId})
        .then((data) => {
            if (data) {
                let resp = JSON.parse(data);
                if(resp.status == 'Success'){
                    if(resp.holdingsLiabilitiesInfo.plDetails){
                        let plDetails = resp.holdingsLiabilitiesInfo.plDetails;
                        if(plDetails.holdingsDetails){
                            for(let i=0; i<plDetails.holdingsDetails.length;i++){
                                if(plDetails.holdingsDetails[i].rateOfInterest){
                                    plDetails.holdingsDetails[i].rateOfInterest = plDetails.holdingsDetails[i].rateOfInterest + '%';
                                }
                            }
                        }
                        this.plDetails = plDetails;
                    }
                    if(resp.holdingsLiabilitiesInfo.hflDetails){
                        let hflDetails = resp.holdingsLiabilitiesInfo.hflDetails;
                        if(hflDetails.holdingsDetails){
                            for(let i=0; i<hflDetails.holdingsDetails.length;i++){
                                if(hflDetails.holdingsDetails[i].rateOfInterest){
                                    hflDetails.holdingsDetails[i].rateOfInterest = hflDetails.holdingsDetails[i].rateOfInterest + '%';
                                }
                            }
                        }
                        this.hflDetails = hflDetails;
                    }
                    if(resp.holdingsLiabilitiesInfo.blDetails){
                        let blDetails = resp.holdingsLiabilitiesInfo.blDetails;
                        if(blDetails.holdingsDetails){
                            for(let i=0; i<blDetails.holdingsDetails.length;i++){
                                if(blDetails.holdingsDetails[i].rateOfInterest){
                                    blDetails.holdingsDetails[i].rateOfInterest = blDetails.holdingsDetails[i].rateOfInterest + '%';
                                }
                            }
                        }
                        this.blDetails = blDetails;
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