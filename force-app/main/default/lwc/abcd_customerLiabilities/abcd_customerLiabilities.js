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
    @track glDetails;
    @track isLoading = false;
    @track status;
    @track apiMessage;



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
                        this.status = resp.status;
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
                }else{
                    this.status = resp.status;
                    this.apiMessage = resp.message;
                }
                this.isLoading = false;
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