import { LightningElement,api, track } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchConfig from '@salesforce/apex/ASF_CloneCCCController.searchConfig';
import cloneConfigData from '@salesforce/apex/ASF_CloneCCCController.cloneConfigData';

export default class Asf_cloneCCCRecords extends NavigationMixin(LightningElement) {
    searchTypeKey;
    searchSubTypeKey;
    @api recordId;
    @track errorList;
    isValidInput = true;
    hideClone = true;
    cols = [
        {label:'Object Name', fieldName:'objectName' , type:'text'} , 
        {
            label: "Id",
            type: "button",
            typeAttributes: { label: { fieldName: "recordId" }, name: "gotoConfigRecord", variant: "base" }
        },
        {label:'Error Messages', fieldName:'errorMessages' , type:'text', wrapText: true}
              
    ]


    handleTypeSearchKey(event){
        this.searchTypeKey = event.target.value;
        this.hideClone = true;
    }

    handleSubTypeSearchKey(event){
        this.searchSubTypeKey = event.target.value;
        this.hideClone = true;
    }
    validateInput(){
        this.isValidInput = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
    }
    searchConfigHandler(){
        this.validateInput();
        if(this.isValidInput){
            searchConfig({type: this.searchTypeKey,subType: this.searchSubTypeKey})
            .then(result => {
                if(result === 'Success'){
                    this.hideClone = false;
                    this.showToastMessage('Success!', 'Type and Sub Type combination does not exist. Good to Clone', 'success');
                }else{
                    this.hideClone = true;
                    this.showToastMessage('Error!', 'Type and Sub Type combination exists.', 'error');
                }
            })
            .catch( error=>{
                this.hideClone = true;
                this.showToastMessage('Error!', 'Unexpected Error Occured. Please Contact Administrator', 'error');
            });
        }
    }
    cloneConfigHandler(){
        console.log('record id--'+this.recordId);
        cloneConfigData({configId: this.recordId, typeVal: this.searchTypeKey, subType: this.searchSubTypeKey})
        .then(result => {
                this.errorList = result;
                if(result.state == 'success'){
                    var rId =  result.recordId;
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId:rId,
                            objectApiName: 'ASF_Case_Category_Config__c',
                            actionName: 'view'
                        },
                    }); 
                } 
                //failure . Handle errors 
                else {
                    this.errorList  = JSON.parse(result.error);
                }
        })
        .catch( error=>{
            this.errorList = null;
        });
    }
    handleRowAction(event) {
        if (event.detail.action.name === "gotoConfigRecord") {
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    recordId: event.detail.row.recordId,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url, "_blank");
            });
        }
    }
    //Utility method to Display Toast Message
    showToastMessage(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}