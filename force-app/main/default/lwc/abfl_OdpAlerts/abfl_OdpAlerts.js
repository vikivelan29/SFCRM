import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import getOdpAlerts from '@salesforce/apex/ABFL_OdpAltertsComtroller.getOdpAlerts';
import getConstants from '@salesforce/apex/ABHFL_Constants.getAllConstants';
import getConstantsABFL from '@salesforce/apex/ABFL_Constants.getAllConstants'; //new code for ABFL
import businessUnitType from '@salesforce/schema/User.Business_Unit__c';

export default class Abhfl_OdpAlerts extends LightningElement {
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

    // @wire(getRecord, { recordId: Id, fields: [businessUnitType]}) 
    // currentUserInfo({error, data}) {
    //     if (data) {
    //         this.userType = data.fields.Business_Unit__c.value;
    //         console.log('***this.userType'+this.userType);
    //         this.callODPAlerts();
    //     } else if (error) {
    //         this.handleError(error);
    //     }
    // }

    odpAlerts(){
        this.showSpinner = true;
        this.showErrorMessage = false;

        getOdpAlerts({'AccountId':this.recordId}) //new
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