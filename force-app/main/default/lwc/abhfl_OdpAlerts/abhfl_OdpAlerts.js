import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import getOdpAlerts from '@salesforce/apex/ABHFL_ODPAlerts.getOdpAlerts';
import getConstants from '@salesforce/apex/ABHFL_Constants.getAllConstants';
import businessUnitType from '@salesforce/schema/User.Business_Unit__c';

export default class Abhfl_OdpAlerts extends LightningElement {
    @api recordId ;
    showSpinner = false;
    showErrorMessage = false;
    isAbhflUser = false;
    userType;
    responseMessage;
    
    connectedCallback(){
       getConstants()
        .then(result => {
            console.log('this.userType =='+this.userType +' result.ABHFL=='+result.ABHFL);
            if(this.userType == result.ABHFL){
                this.isAbhflUser = true;
                this.odpAlerts();
            }
        })
        .catch(error => {
            this.showSpinner = false;
            this.handleError(JSON.stringify(error));
            console.log('error=='+JSON.stringify(error));
        });
    }

    @wire(getRecord, { recordId: Id, fields: [businessUnitType]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.userType = data.fields.Business_Unit__c.value;
        } else if (error) {
            this.handleError(JSON.stringify(error));
        }
    }

    odpAlerts(){
        this.showSpinner = true;
        this.showErrorMessage = false;

        getOdpAlerts({'AccountId':this.recordId})
        .then(result => {
            if(result[0].errorCode == undefined){
                this.responseMessage = result;
            }else{
                this.handleError(result[0].message);
            }
            
            this.showSpinner = false;
        })
        .catch(error => {
            this.showSpinner = false;
            this.handleError(JSON.stringify(error));
            console.log('error=='+JSON.stringify(error));
        });
    }

    handleError(error){
        this.responseMessage = error;
        this.showErrorMessage = true;
    }
}