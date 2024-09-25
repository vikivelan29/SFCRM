import { LightningElement, api, track, wire } from 'lwc';
import getCustomerProspectData from '@salesforce/apex/ASF_CustomerAndProspectSearch.getRecords';
import getForm from '@salesforce/apex/ASF_FieldSetController.getLOBSpecificForm';
import { NavigationMixin } from 'lightning/navigation';
import createProspectCase from '@salesforce/apex/ASF_CustomerAndProspectSearch.createProspectWithCaseExtnAndCase';
import { reduceErrors } from 'c/asf_ldsUtils';

import loggedInUserId from '@salesforce/user/Id';

import { getRecord } from 'lightning/uiRecordApi';
import UserBusinessUnit from '@salesforce/schema/User.Business_Unit__c';

import hasSalesProspectPermission from "@salesforce/customPermission/ShowSalesProspect";
import hideCaseWithProspect from "@salesforce/customPermission/HideCaseWithProspect";
import hasShowCreateLeadPermission from "@salesforce/customPermission/ShowCreateLead";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { lanLabels } from 'c/asf_ConstantUtility';



export default class Asf_GlobalSearchCustom extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data;
    @track accountRecords;
    @track contactRecords;
    @track leadRecords;
    typingTimer;
    doneTypingInterval = 300;
    @track showWelcomeMat = true;
    @track headerString = 'Customer and Prospect Search is here.!';
    @track bAtleastOneRecord = false;
    @track showModal = false;
    @track showSalesProspect = false;
    @track fields;
    @track dupeLead=[];
    @track showDupeList=false;
    @track selectedProspectId;
    @track headerName;
    @track isInternalCase = false;
    @track loggedInUserBusinessUnit = '';
    error;
    createCaseWithNewProspect;
    createSalesProspectLabel;
    @track showProspectFlow = false;


    cols_Customer = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Business Unit', fieldName: 'Business_Unit__c', type: 'text' },
        { label: 'Client Code', fieldName: 'Client_Code__c', type: 'text' }
    ];
    cols_Contact = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Email', fieldName: 'Email', type: 'text' },
        { label: 'Mobile', fieldName: 'Mobile__c', type: 'text' }
    ];
    cols_Lead = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Name', fieldName: 'Name', type: 'text' }
    ]
    dupeLeadCols = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
        { label: 'Email', fieldName: 'Email', type: 'text' },
        { label: 'MobilePhone', fieldName: 'MobilePhone', type: 'text' }
    ]



    @wire(getRecord, { recordId: loggedInUserId, fields: [UserBusinessUnit ]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.loggedInUserBusinessUnit = data.fields.Business_Unit__c.value;
            this.createCaseWithNewProspect = lanLabels[this.loggedInUserBusinessUnit].CREATE_CASE_WITH_NEW_PROSPECT != null? lanLabels[this.loggedInUserBusinessUnit].CREATE_CASE_WITH_NEW_PROSPECT : lanLabels["DEFAULT"].CREATE_CASE_WITH_NEW_PROSPECT;
            this.createSalesProspectLabel = lanLabels[this.loggedInUserBusinessUnit].CREATE_SALES_PROSPECT != null? lanLabels[this.loggedInUserBusinessUnit].CREATE_SALES_PROSPECT : lanLabels["DEFAULT"].CREATE_SALES_PROSPECT;
            this.headerName = lanLabels[this.loggedInUserBusinessUnit].CREATE_CASE_WITH_PROSPECT != null? lanLabels[this.loggedInUserBusinessUnit].CREATE_CASE_WITH_PROSPECT : lanLabels["DEFAULT"].CREATE_CASE_WITH_PROSPECT;
        } else if (error) {
            //this.error = error ;
        }
    }

    async handleInputChange(event) {
        console.log(event.target.value);
        let searchString = event.target.value;
        if (searchString != null && searchString != '') {
            // Only when something valid is entered.
            clearTimeout(this.typingTimer);
            this.typingTimer = setTimeout(() => {
                if (searchString.length >= 3) {
                    this.SearchCustomerProspectHandler(searchString);
                }
            }, this.doneTypingInterval);


        }
        else {
            this.showWelcomeMat = true;
        }

    }

    async SearchCustomerProspectHandler(searchString) {
        this.bAtleastOneRecord = false;
        this.showWelcomeMat = true;
        getCustomerProspectData({ searchString: searchString })
            .then(result => {
                console.log(result);
                if (result != null && result != undefined) {
                    this.showWelcomeMat = false;
                }
                this.data = result;
                for (var a = 0; a < result.length; a++) {
                    if (result[a].objectName == 'Account') {
                        this.data[a].cols = this.cols_Customer;
                    }
                    else if (result[a].objectName == 'Contact') {
                        this.data[a].cols = this.cols_Contact;
                    }
                    else if (result[a].objectName == 'Lead') {
                        this.data[a].cols = this.cols_Lead;
                    }

                    this.data[a].objRecords.forEach(res => {
                        res.redirectLink = '/' + res.Id;
                        this.bAtleastOneRecord = true;
                    });
                }

            })
            .catch(error => {
                console.log(error);
                this.showError('error', 'Oops! Error occured', error);
            })
    }
    handleCaseWithProspect(event) {
        this.showModal = true;
        this.headerName = 'Create Case with Prospect';
        this.isInternalCase = false;
    }
    hideModalCreateCase(event) {
        this.showModal = false;
        this.showSalesProspect = false;
        this.dupeLead = null;
        this.showDupeList = false;
        this.isInternalCase = false;
        this.showProspectFlow = false;
    }
    handleStatusChange(event) {
        if(event.detail.status === 'FINISHED'){
            this.hideModalCreateCase(event);
        }
    }

    /* Sales Prospect Code Starts Here */
    async handleSalesProspet(event) {
        this.isInternalCase = false;
        await getForm({ recordId: null, objectName: "Lead", fieldSetName: null, salesProspect: true })
            .then(result => {
                console.log('Data:' + JSON.stringify(result));
                if (result) {
                    this.fields = result.Fields;
                    this.error = undefined;
                    this.showSalesProspect = true;
                    this.disableCreateBtn = false;
                }
            }).catch(error => {
                console.log(error);
                this.error = error;
            });
    }
    createSalesProspect(event) {
        event.preventDefault();
        this.disableCreateBtn = true;
        let isValid = this.isInputValid();
        if(isValid) {

        let leadFields = [...this.template.querySelectorAll('lightning-input-field')]
        let fieldsVar = leadFields.map((field)=>[field.fieldName,field.value]);
        let leadRecord = Object.fromEntries([...fieldsVar, ['sobjectType', 'Lead']]);
        leadRecord["Sales_Prospect__c"] = true;
        leadRecord["Prospect_Type__c"] = 'Sales';
        leadRecord["Business_Unit__c"] = this.loggedInUserBusinessUnit;
        this.dupeLead = [];

        createProspectCase({ caseToInsert: null, caseExtnRecord: null, prospectRecord: leadRecord })
            .then(result => {
                if(result.DuplicateLead != null && result.DuplicateLead != undefined){
                    this.dupeLead.push(JSON.parse(JSON.stringify(result.DuplicateLead)));
                    if(this.dupeLead != null && this.dupeLead != undefined && this.dupeLead.length > 0){
                        this.dupeLead[0].redirectLink =  '/' + this.dupeLead[0].Id;
                        this.showDupeList=true;
                        this.disableCreateBtn = true;
                        return;
                    }
                }
                

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.Lead.Id,
                        actionName: 'view'
                    },
                    state: {
                        mode: 'edit'
                    }
                });
                this.hideModalCreateCase();
            })
            .catch(error => {
                console.log('tst225572' + JSON.stringify(error));
                this.showError('error', 'Oops!', error);
            });
        }
    }
    
    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(inputField => {
            //if (inputField.value != null && inputField.value != undefined) {

            if (inputField.required == true) {
                if (inputField.value != null && inputField != undefined) {
                    if (inputField.value.trim() == '') {
                        inputField.value = '';
                        inputField.reportValidity();
                        isValid = false;
                    }
                    
                }
                else{
                    inputField.reportValidity();
                    isValid = false;
                }

            }

        });
        return isValid;
    }
    
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }

    getSelectedName(event){
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.selectedProspectId = selected.Id;
        }
    }

    handleInternalCaseCreation(event){
        this.showModal = true;
        this.headerName = 'Create Internal Case';
        this.isInternalCase = true;
    }

    get isSalesProspectVisible() {
        return hasSalesProspectPermission;
    }
    get isCaseWithProspectHidden() {
        return hideCaseWithProspect;
    }
    
    get isCreateLeadVisible() {
        return hasShowCreateLeadPermission;
    }

    handleShowFlow(event){
        this.showProspectFlow = true;
    }


}