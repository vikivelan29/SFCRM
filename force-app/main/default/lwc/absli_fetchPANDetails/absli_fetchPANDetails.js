import { LightningElement, api, track, wire } from 'lwc';
//import fetchBankDetail from '@salesforce/apex/ABSLI_FetchBankDetailsController.fetchBankDetail';
import updateSTPFlagOnCaseDetail from '@salesforce/apex/ABSLI_NSDLPANVerification.updateSTPFlagOnCaseDetail';
import { updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import PAN_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.PAN_Number__c";
import IS_STP_FLG_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.Status_Valid_For_STP__c";
import BANK_NAME_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.Bank_Name__c";
import BANK_BRANCH_FLD from "@salesforce/schema/ABSLI_Case_Detail__c.Branch_Name__c";
import ABSLI_CASE_EXT_ID_FIELD from "@salesforce/schema/ABSLI_Case_Detail__c.Id";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
//import { RefreshEvent } from 'lightning/refresh'; 
//import { fireEvent, fireEventNoPageRef, registerListener } from 'c/asf_pubsub'; // Virendra - Instead of LMS moving to pubsub

import panVerification from '@salesforce/apex/ABSLI_NSDLPANVerification.verifyPANDetails';
import getPanDetails from '@salesforce/apex/ABSLI_NSDLPANVerification.getPanVerificationDetails';

export default class Absli_fetchPANDetails extends LightningElement {
    @api recordId;
    @track processApexReturnValue;
    @track errorMessage = '';
    @track showErrorMsg = false;
    @track data;
    @track loaded = false;
    @track absliCaseExtId = '';
    @track showFetchResponse = false;
    @api fieldNameToSearch = '';
    @track confirmTextValue ='';
    @track originalTextValue = '';
    @track todayDt = new Date().toJSON().slice(0, 10);
    @track record;
    @track error;
    @track bConfirmationTextNotMatching = true;
    @track showConfirmationError = false;
    @track nsdlResponse = undefined;
    @track CancelBtnLbl = 'Cancel';
    @track PAN_Number = '';
    @track clientName = '';
    @track clientDOB = '';
    @track apifetchError = false;
    @track apiFetchErroText = 'External Service is not responding. Please proceed manully entering data.'
    @track isVerificationSuccessful = false;
    

    @wire(CurrentPageReference) pageRef;

    showToast(e){
        this.dispatchEvent(new ShowToastEvent(e));        
    }

    handleDOBChange(event){
        this.clientDOB = event.detail.value;
    }

    connectedCallback(){
        debugger;
        getPanDetails({caseId: this.recordId})
        .then((result)=>{
            debugger;
            this.record = result;
            this.PAN_Number = result.pan;
            this.clientName = result.name;
            this.clientDOB = result.dob;
            this.absliCaseExtId = result.caseExtId;

            this.loaded = true;

        })
        .catch((error)=>{
            this.record =undefined;
            this.PAN_Number = '';
            this.clientName = '';
            this.clientDOB = '';
            this.error = error;
            this.loaded = true;

        })
    }

    closeParentPopup() {
        this.dispatchEvent(new CustomEvent("closepopup"));
    }

    handleFetchDetails(event){
        event.preventDefault();
        this.record = JSON.parse(JSON.stringify(this.record));
        this.record.pan = this.confirmTextValue;
        this.record.dob = this.clientDOB;
        this.invokeFetchPANDetailCallout();
    }

    get showAcceptBtn(){
        return this.showFetchResponse || this.apifetchError;
    }

    validateFields() {
        return [...this.template.querySelectorAll("lightning-input")].reduce((validSoFar, field) => {

            return (validSoFar && field.reportValidity());
        }, true);
    }
    
    async invokeFetchPANDetailCallout() {
        debugger;
        let bValid = this.validateFields();

        if(bValid){
            await panVerification({ panInputWrapperStr : JSON.stringify(this.record), caseId: this.recordId})
            .then((result) => {
                debugger;
                if (result.isSuccess) {
                    this.verificationCompleted = true;
                    this.showToast({
                        title: "Success",
                        message: "PAN Validated Successfully",
                        variant: "success",
                    });
                    this.nsdlResponse = JSON.parse(result.responseStr).outputData[0];
                    this.showFetchResponse = true;
                    this.CancelBtnLbl = 'Deny';
                    if(this.nsdlResponse && this.nsdlResponse.name == "Y" && this.nsdlResponse.dob == "Y" 
                        && this.nsdlResponse.pan_status == "E"){
                    this.isVerificationSuccessful = true;
                    }
                    debugger;
                }
                else{
                    debugger;
                    this.apifetchError =true;
                    this.isVerificationSuccessful = false;
                    this.showToast({
                        title: "Error",
                        message: result.errorMessage,
                        variant: "error",
                    });
                }
            })
            .catch((error) => {
                debugger;
                console.log(error);
            })
        }

        
    }
    get showResponse() {
        if (this.loaded && !this.showErrorMsg) {
            return true;
        }
        return false;
    }
    
    

    handleUpdateFromFieldPopUp(event){
        event.preventDefault();

        let arr_fieldDetails = [];
        let propPAN = {};
        propPAN.FieldAPINAme = PAN_FLD.fieldApiName;
        propPAN.fieldValue = this.confirmTextValue;//this.PAN_Number;
        propPAN.status = 'Success';
        arr_fieldDetails.push(propPAN);
        debugger;

        if(this.isVerificationSuccessful){
            this.handleUpdate();
        }

        this.dispatchEvent(new CustomEvent("case360fieldextn", 
            {
                detail: {
                    arr_fieldDetails
                } 
            }));
            this.closeParentPopup();

    }
    handleOriginalAndConfirmationText(event){
        let val = event.target.value;
        this.confirmTextValue =  val;
        this.originalTextValue = val;
    }
    confirmationCheck() {
        if (this.originalTextValue == this.confirmTextValue && this.confirmTextValue != '') {
            this.bConfirmationTextNotMatching = false;
            this.showConfirmationError = false;
            this.iconClass = 'successBtn';
        }
        else {
            this.bConfirmationTextNotMatching = true;
            this.showConfirmationError = true;
        }
    }
    handleOriginalTextChange(event) {
        this.originalTextValue = event.target.value;
        this.confirmationCheck();
    }
    handleConfirmTextChange(event) {
        let val = event.target.value;
        this.confirmTextValue = val;
        this.confirmationCheck();
    }

    async handleUpdate(event) {
        const fields = {};
        fields[ABSLI_CASE_EXT_ID_FIELD.fieldApiName] = this.absliCaseExtId;
        fields[IS_STP_FLG_FLD.fieldApiName] = true;
        const recordInput = { fields };

        await updateSTPFlagOnCaseDetail({'caseExtId': this.absliCaseExtId, 'flagVal': true})
            .then((result)=>{
                debugger;
            })
            .catch((err)=>{
                debugger;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: err.body.message,
                        variant: "error",
                    }),
                );
            })
        

    }
    
}