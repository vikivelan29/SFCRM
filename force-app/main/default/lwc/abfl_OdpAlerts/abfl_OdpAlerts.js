import { LightningElement, api, wire } from 'lwc';
import getOdpAlerts from '@salesforce/apex/ABFL_OdpAltertsController.getOdpAlerts';

export default class Abfl_OdpAlerts extends LightningElement {
    @api recordId ;
    showSpinner = false;
    showErrorMessage = false;
    isAbhflUser = false;
    isAbflUser = false; //New
    userType;
    responseMessage;
    
    connectedCallback(){
       this.odpAlerts();
    }

    odpAlerts(){
        this.showSpinner = true;
        this.showErrorMessage = false;

        getOdpAlerts({'accountId':this.recordId}) //new
        .then(result => {
            console.log('***result'+JSON.stringify(result));
            if(result[0].errorCode == undefined){
                this.responseMessage = result;
            }else{
                this.handleError(result[0].message);
            }
            this.showSpinner = false;
        })
        .catch(error => {
            this.showSpinner = false;
            this.handleError(error);
            console.log('error==>',JSON.stringify(error));
        });
    }

    handleError(error){
        this.responseMessage = error;
        this.showErrorMessage = true;
    }
}