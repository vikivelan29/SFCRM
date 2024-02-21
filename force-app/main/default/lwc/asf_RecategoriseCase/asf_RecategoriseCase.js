import { LightningElement, track, api, wire } from 'lwc';
import {loadStyle} from 'lightning/platformResourceLoader';
import overrideCSSFile from '@salesforce/resourceUrl/asf_QuickActionHeightWidthIncreaser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_OBJECT from '@salesforce/schema/Case';
import { createRecord, notifyRecordUpdateAvailable, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import CCC_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';
import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
import RECATEGORISATION_REASON_FIELD from '@salesforce/schema/Case.Recategorisation_Reason__c';
import BOT_FEEDBACK_FIELD from '@salesforce/schema/Case.Bot_Feedback__c';
import CASE_BU_FIELD from '@salesforce/schema/Case.Business_Unit__c';
import SENTTOBOT_FIELD from '@salesforce/schema/Case.Sent_to_EBOT__c';

import Email_Bot_BU_label from '@salesforce/label/c.ASF_Email_Bot_Feedback_BU';

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import { reduceErrors } from 'c/asf_ldsUtils';
import { fireEventNoPageRef, registerListener } from 'c/asf_pubsub';
import { RefreshEvent } from 'lightning/refresh';

import getTypeSubTypeData from '@salesforce/apex/ASF_RecategoriseCaseController.getTypeSubTypeDataByCustomerType';
import getCaseRelatedObjName from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseRelatedObjName';
import getCaseRecordDetails from '@salesforce/apex/ASF_RecategoriseCaseController.getCaseRecordDetails';
import updateCaseRecord from '@salesforce/apex/ASF_RecategoriseCaseController.updateCaseWithNewCCCId';
import fetchCCCDetails from '@salesforce/apex/ASF_RecategoriseCaseController.fetchCCCDetails';
import callEbotFeedbackApi from '@salesforce/apex/ABCL_EBotFeedback.callEbotFeedbackApi';

export default class asf_RecategoriseCase extends NavigationMixin(LightningElement) {
    searchKey;
    accounts;
    isNotSelected = true;
    @api recordId;
    @wire(CurrentPageReference) pageRef;
    @api fieldToBeStampedOnCase;
    loaded = false;
    caseRelObjName;
    caseExtensionRecordId;
    //TBD . load this 
    caseRecordId;

    //tst strt
    doneTypingInterval = 300;
    typingTimer;
    createCaseWithAll = false;
    
    isAllNature = false;
    isAllProduct = false;
    isAllSource = false;

    isRequestAndQuery = false;
    isRequestAndQuerySource = false;
    isOnlySource = false;
    natureVal;
    productVal;
    sourceVal;
    rejectionReasonVal;
    botFeedbackVal;

    assetId;
    isasset;
    accountId;
    leadId; // Virendra - Added for Prospect Related ReCategorisation.
    
    //asset;

    singleChoice;
    
    sourceValues = [];
    natureValues = [];
    lstChannelValues = [];
    complaintValues = [];

    primaryLOBValue;

    strSource = '';
    strChannelValue = '';
    strDefaultChannel = '';

    //boolChannelVisible = false;

    boolShowNoData = false;
    boolAllChannelVisible = false;
    boolAllSourceVisible = false;
    strNoDataMessage = '';
    complaintLevelVisible = false;
    
    complaintSelected;
    subsourceSelected;
    cccProductType;
    selectedSRCategory;
    caseComplaintLevel;
    
    cccproduct_type = '';

    accountRecordType = '';
    leadRecordType = ''; // Virendra - Added as part of Prospept Requirement.
    caseFields = [NATURE_FIELD, SOURCE_FIELD, CHANNEL_FIELD];
    oldCaseDetails ;
    currentCCCId;
    recategorizeEnabled;
    sendBotFeedback = true;
    showBotFeedback = false;
     
    @wire(getRecord, { recordId: '$recordId', fields: [SENTTOBOT_FIELD, CASE_BU_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            //Show Bot Feedback checkbox if Case source is Email and for specific BU
            const email_Bot_BU = Email_Bot_BU_label.includes(';') ? Email_Bot_BU_label.split(';') : [Email_Bot_BU_label];
            if(getFieldValue(data, SENTTOBOT_FIELD) === true && email_Bot_BU.includes(getFieldValue(data, CASE_BU_FIELD))){
                this.showBotFeedback = true;
            }
        } else if (error) {
            console.error('Error loading record', error);
        }
    }

    renderedCallback(){
        Promise.all([
            loadStyle(this, overrideCSSFile)
        ]);
    }
    //utility method
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }
    connectedCallback() {
        //api record id was not working
        console.log('this.recordId',this.recordId);
        this.recordId = this.pageRef.state.recordId;
        this.getCurrentCaseRecordDetails();
    }

    //This Funcation will get the value from Text Input.
    handelSearchKey(event) {
        clearTimeout(this.typingTimer);
        this.searchKey = event.target.value;

        this.typingTimer = setTimeout(() => {
            if (this.searchKey && this.searchKey.length >= 3) {
                this.searchTypeSubtypeHandler();
            }
        }, this.doneTypingInterval);
    }

    //This function gets the value from the Send Bit Feedback Checkbox
    handleBotFeedback(event){
        this.sendBotFeedback = event.target.checked;
    }

    //This function will fetch the CCC Name on basis of searchkey
    searchTypeSubtypeHandler() {
        this.accounts = null;
        this.createCaseWithAll = false;
        this.boolAllChannelVisible = false;
        this.boolAllSourceVisible = false;
        this.boolChannelVisible = false;
        this.isNotSelected = true;
 
        getTypeSubTypeData({ keyword: this.searchKey, asssetProductType: this.cccproduct_type, isasset: this.isasset, accRecordType : this.accountRecordType,currentCCCId : this.currentCCCId  })
            .then(result => {
                if (result != null && result.boolNoData == false) {
                    this.accounts = result.lstCCCrecords;
                    //this.strSource = result.strSource;
                    //this.strSource = JSON.parse(result.caseDetails).Source__c //JSON.parse(this.oldCaseDetails.caseDetails).Source__c;
                    this.strSource = JSON.parse(this.oldCaseDetails.caseDetails).Source__c;
                    this.boolShowNoData = false;
                    if (result.lstChannel != null && result.lstChannel.length > 0) {
                        this.lstChannelValues = result.lstChannel;
                        //this.strDefaultChannel = this.lstChannelValues[0].label;
                       // this.strDefaultChannel =  JSON.parse(result.caseDetails).Channel__c//JSON.parse(this.oldCaseDetails.caseDetails).Channel__c;
                       if(JSON.parse(this.oldCaseDetails.caseDetails).Channel__c == undefined){
                            this.strDefaultChannel =  this.lstChannelValues[0].label;
                       }
                       else { 
                            this.strDefaultChannel =  JSON.parse(this.oldCaseDetails.caseDetails).Channel__c;
                       }
                        this.strChannelValue = this.strDefaultChannel; 
                        this.boolChannelVisible = true;
                    }
                    if(this.accounts.length == 0){
                        this.boolShowNoData = true;
                        this.strNoDataMessage = result.strErrorMessage;
                        this.loaded = true;
                        
                    }
                }
                else if (result.boolNoData == true) {
                    this.boolShowNoData = true;
                    this.strNoDataMessage = result.strErrorMessage;
                }
                this.isNotSelected = true;
                this.loaded = true;
            })
            .catch(error => {
                this.accounts = null;
                this.isNotSelected = true;
                this.loaded = true;
            });

    }

    getSelectedName(event) {
        this.createCaseWithAll = false;
        this.isNotSelected = false;
        this.isAllNature = false;
        this.isAllProduct = false;
        this.isAllSource = false;
        this.isRequestAndQuery = false;
        this.isRequestAndQuerySource = false;
        this.isOnlySource = false;
        this.productVal = '';
        this.natureVal = '';
        this.sourceVal = '';
        this.sourceValues = [];
     
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;
        }
    
        if (selected) {
            if (selected && (selected[NATURE_FIELD.fieldApiName] == "All" || selected[SOURCE_FIELD.fieldApiName] == "All") && (!selected[NATURE_FIELD.fieldApiName].includes(','))) {
                this.boolAllChannelVisible = true;
                this.boolAllSourceVisible = true;
            }
            this.createCaseWithAll = true;
            this.isNotSelected = true;
            if (selected[NATURE_FIELD.fieldApiName] == "All") {
                this.isAllNature = true;
            }
            if (selected[SOURCE_FIELD.fieldApiName] == "All") {
                this.isAllSource = true;
            }
        }
        if (selected && (selected[NATURE_FIELD.fieldApiName].includes(','))) {
            const picklistValues = selected[SOURCE_FIELD.fieldApiName];
            const naturePicklistValues = selected[NATURE_FIELD.fieldApiName];
            if ((picklistValues) && (selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                this.sourceValues = picklistValues.split(',').map((elem) => {
                    const sourceValues = {
                        label: elem,
                        value: elem
                    };
                    return sourceValues;
                });
            }

            else if ((picklistValues) && (selected[SOURCE_FIELD.fieldApiName] == "All")) {
                const optionVal = {
                    label: 'Branch',
                    value: 'Branch'
                };
                const optionVal1 = {
                    label: 'CEC',
                    value: 'CEC'
                };
                const emailVal = {
                    label: 'Email',
                    value: 'Email'
                };
                if (this.sourceValues.length == 0) {
                    this.sourceValues.push(optionVal, optionVal1, emailVal);
                }

                this.singleChoice = selected[SOURCE_FIELD.fieldApiName];
            }
            else if ((picklistValues) && (!selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                const optionVal = {
                    label: selected[SOURCE_FIELD.fieldApiName],
                    value: selected[SOURCE_FIELD.fieldApiName]
                };
                this.sourceValues.push(optionVal);
                this.singleChoice = selected[SOURCE_FIELD.fieldApiName];
                this.sourceVal = selected[SOURCE_FIELD.fieldApiName];
            }
            if (naturePicklistValues) {
                this.natureValues = naturePicklistValues.split(',').map((elem) => {
                    const natureValues = {
                        label: elem,
                        value: elem
                    };
                    return natureValues;
                });
            }

            this.createCaseWithAll = true;
            this.isNotSelected = true;
            this.isRequestAndQuery = true;
            if ((selected[SOURCE_FIELD.fieldApiName] != null) && (selected[SOURCE_FIELD.fieldApiName].includes(','))) {
                this.isRequestAndQuerySource = true;
            }
            if ((selected[SOURCE_FIELD.fieldApiName] == 'All')) {
                this.isRequestAndQuerySource = true;
            }
            if (this.isAllSource == true) {
                this.isRequestAndQuerySource = false;
            }
        } else {
            if (selected) {
                this.isOnlySource = true;
                this.isAllSource = false;
                if (selected[NATURE_FIELD.fieldApiName] && selected[NATURE_FIELD.fieldApiName] != 'All') {
                    this.natureVal = selected[NATURE_FIELD.fieldApiName];
                }
                if (selected[SOURCE_FIELD.fieldApiName]) {

                    if (!selected[SOURCE_FIELD.fieldApiName].includes(',') && selected[SOURCE_FIELD.fieldApiName] != 'All') {
                        this.sourceVal = selected[SOURCE_FIELD.fieldApiName];
                    }
                    else if (selected[SOURCE_FIELD.fieldApiName].includes(',')) {
                        this.sourceValues = selected[SOURCE_FIELD.fieldApiName].split(',').map((elem) => {
                            const sourceValues = {
                                label: elem,
                                value: elem
                            };
                            return sourceValues;
                        });
                        this.isOnlySource = true;
                        this.createCaseWithAll = true;
                        this.isNotSelected = true; // Virendra : 8th March 2023 : To make Create Case button disable if field value is not selected.
                    }
                }
            }
        }

        //Making Disabled button false in case the Nature Field is not visible. 
        if (this.isAllNature == false && this.isRequestAndQuery == false) {
            this.isNotSelected = false;
        }
        else {
            this.isNotSelected = true;
        }
        if (selected && selected.hasOwnProperty("Complaint_Level__c")) {
            this.complaintSelected = selected['Complaint_Level__c']
            this.complaintLevelVisible = true;
            this.complaintValues = [];
            if (this.complaintSelected == 'L3') {
                this.caseComplaintLevel = 'L3';
            } else if (this.complaintSelected == 'L2') {
                this.caseComplaintLevel = 'L2';
            }
            this.fetchNatureMetadata(this.complaintSelected, selected[NATURE_FIELD.fieldApiName])
            this.isNotSelected = true;
        } else {
            this.complaintLevelVisible = false;
        }

    }
    
    async updateCaseHandler() {
        
        if(!this.isInputValid()) {
            return;
        }
        const rejectionReason = this.template.querySelector('[data-id="rejectReason"]');
        if(rejectionReason.value == undefined || rejectionReason.value == null || rejectionReason.value.trim() == ''){
            rejectionReason.reportValidity();
            return;
        }
        const botfeedback = this.template.querySelector('[data-id="botfeedback"]');
        if(botfeedback.value == undefined || botfeedback.value == null || botfeedback.value.trim() == ''){
            botfeedback.reportValidity();
            return;
        } 
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        
        if(!await this.validateNewCCC(selected.CCC_External_Id__c)){
            return;
        }
        const fields = {};
        for(let fldToStamp in this.fieldToBeStampedOnCase) {
            fields[fldToStamp] = this.fieldToBeStampedOnCase[fldToStamp];
        }
        
        await this.getCaseRelatedObjName(selected.CCC_External_Id__c);
 
        if (this.caseRelObjName) {
            /*
            only if extension object is changing , then do this. 
            else does not matter.but on save, losing fields , winning fields should do
            */
            if(this.oldCaseDetails.currentExtensionName != this.caseRelObjName ){
                await this.createExtensionObj();
                fields[this.caseRelObjName] = this.caseExtensionRecordId;
            }
        }
       
        fields[CCC_FIELD.fieldApiName] = selected.CCC_External_Id__c;
        fields[NATURE_FIELD.fieldApiName] = this.natureVal;
        fields[SOURCE_FIELD.fieldApiName] = this.strSource;
        fields[CHANNEL_FIELD.fieldApiName] = this.strChannelValue;
        //jay
        fields[RECATEGORISATION_REASON_FIELD.fieldApiName] = this.template.querySelector('[data-id="rejectReason"]').value;
        fields[BOT_FEEDBACK_FIELD.fieldApiName] = this.template.querySelector('[data-id="botfeedback"]').value;
        const caseRecord = { apiName: CASE_OBJECT.objectApiName, fields: fields };
        this.loaded = false; 
        updateCaseRecord({ recId: this.recordId,oldCCCId : JSON.parse(this.oldCaseDetails.caseDetails).CCC_External_Id__c,newCaseJson : JSON.stringify(caseRecord) })
        .then(result => {
            if(this.showBotFeedback && this.sendBotFeedback){
                this.notifyEbot();
            }
            this.dispatchEvent(new CloseActionScreenEvent());
            console.log('Firing pubsub from Recategorize!!!!!!');
            let payload = {'source':'recat', 'recordId':this.recordId};
            fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload);  
            let changeArray = [{recordId: this.recordId}];
            notifyRecordUpdateAvailable(changeArray);
            this.isNotSelected = true;
            this.createCaseWithAll = false; 
        })
        .catch(error => {
            console.log(error);
            this.showError('error', 'Oops! Error occured', error);
            this.loaded = true; 
        }); 
    }
    notifyEbot(){
        callEbotFeedbackApi({ caseId: this.recordId})
            .then(result => {
               console.log('ebot call success');
            })
            .catch(error => {
                this.showError('error', 'Oops! Error occured', error);
            });
    }

    async validateNewCCC(newCCCExtId){
        let configuredCurrentCCC = await fetchCCCDetails({
            cccExtId : newCCCExtId
        })
        .catch(error => {
            console.log(error);
            this.showError('error', 'Oops! Error occured', error);
            this.loaded = true;
            return false; 
        });

        if(configuredCurrentCCC){
            let errorMsg;
            if(this.accountId == null && configuredCurrentCCC.Only_CRN_Mandatory__c == true && configuredCurrentCCC.Is_Prospect_Related__c == false){
                errorMsg = 'Account is not there. But type sub type is selected which require Customer';
            } 
            else if(this.assetId == null && configuredCurrentCCC.is_FA_Mandatory__c == true && configuredCurrentCCC.Is_Prospect_Related__c == false){
                errorMsg = 'Asset is not there. But type sub type is selected which required Asset';
            }
            /* CHECK IF SELECTED CCC IS PROSPECT RELATED.
            /* Scenario 1 - CRN MANDATORY AS WELL AS IS PROSPECT RELATED IS TRUE. MEANING THE CTST IS ELIGIBLE FOR 
            /*              SELECTION AGAINST CUSTOMER AND LEAD BOTH. HENCE FIRST CHECK IF CUSTOMER PRESENT, IF NOT
            /*              CHECK IF LEAD PRESENT, IF BOTH OF THEM ARE NOT PRESENT SHOW ERROR MESSAGE.
            /* Scenario 2 - ASSET MANDATORY AS WELL AS IS PROSPECT RELATED IS TRUE. MEANING THE CTST IS ELIGIBLE FOR
            /*              SELECTION AGAINST ASSET AND LEAD BOTH. HENCE FIRST CHECK IF ASSET PRESENT, IF NOT CHECK
            /*              IF LEAD PRESENT, IF BOTH OF THEM ARE NOT PRESENT SHOW ERROR MESSAGE.
            /* Scenario 3 - ONLY IS PROSPECT RELATED IS TRUE THEN CHECK IF THE LEAD IS PRESENT, IF NOT THEN SHOW ERROR MESSAGE.
            /* Author - Virendra
            */
            if(configuredCurrentCCC.Is_Prospect_Related__c == true && configuredCurrentCCC.Only_CRN_Mandatory__c == true && this.accountId == null && this.leadId == null){
            errorMsg = 'Neither Account nor Prospect is there. But type sub type is selected which require Customer or Prospect.'
            }
            else if(configuredCurrentCCC.Is_Prospect_Related__c == true && configuredCurrentCCC.is_FA_Mandatory__c == true && this.assetId == null && this.leadId == null){
            errorMsg = 'Neither Asset nor Prospect is there. but type sub type is selected which require Asset or Prospect.'
            }
            else if(configuredCurrentCCC.Is_Prospect_Related__c == true && this.leadId == null && configuredCurrentCCC.Only_CRN_Mandatory__c == false && configuredCurrentCCC.is_FA_Mandatory__c == false){
            errorMsg = 'Prospect is not there. But type sub type is selected which require Prospect.'
            }
            /* PROSPECT RECATEGORISATION ENDS HERE */
              
            else if(configuredCurrentCCC.Priority__c != null && this.currentPriority != configuredCurrentCCC.Priority__c ){
                errorMsg = 'Case Category Configured priority and case priority is mismatch';
            } 
            else if(configuredCurrentCCC.Custom_Segment__c != null 
            && this.accountRecordType != configuredCurrentCCC.Custom_Segment__c ){
                errorMsg = 'Case Category Configured Customer segment and case customer segment is mismatch';
            }
            if(errorMsg){
                console.log('displaying error');
                this.showError('error', 'Oops! Invalid Selection', errorMsg);
                return false;
            } 
        }
        return true;
    }
    async createExtensionObj() {
        const fields = {};
        const caseRecord = { apiName: this.caseRelObjName, fields: fields };

        await createRecord(caseRecord)
            .then(result => {
                this.caseExtensionRecordId = result.id;
            })
            .catch(error => {
                this.showError('error', 'Oops! Error occured', error);
                this.loaded = true;
            })
    }

    cols = [
        { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
        { label: 'LOB', fieldName: 'LOB__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
    ]

    handleNatureVal(event) {
        this.natureVal = event.target.value;
        var btnActive = false;
        if (this.natureVal && this.natureVal != '') {
            btnActive = true;
            if (this.isAllSource) {
                if (this.strSource && this.strSource != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            } else if (this.isAllProduct) {
                if (this.productVal && this.productVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }
    closeAction(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleProductVal(event) {
        this.productVal = event.target.value;
        var btnActive = false;
        if (this.productVal && this.productVal != '') {
            btnActive = true;
            if (this.isAllNature) {
                if (this.natureVal && this.natureVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            } else if (this.isAllSource) {
                if (this.strSource && this.strSource != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }

    // Method to handle the Channel Picklist
    handleChangeChannel(event) {
        this.strChannelValue = event.target.value;
        var btnActive = false;
        if (this.strChannelValue && this.strChannelValue != '') {
            btnActive = true;

        } else {
            btnActive = false;
        }
    }

    handleChangeNature(event) {
        this.natureVal = event.target.value;
        var btnActive = false;
        if (this.natureVal && this.natureVal != '') {
            btnActive = true;
            if (this.isRequestAndQuerySource) {
                if (this.strSource && this.strSource != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
            if (this.complaintSelected != '') {
                this.fetchNatureMetadata(this.complaintSelected, this.natureVal)
                if (this.subsourceSelected)
                    btnActive = true;
                else
                    btnActive = false;
            }


        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }

    handleSource(event) {
        this.sourceVal = event.target.value;
        var btnActive = false;
        if (this.sourceVal && this.sourceVal != '') {
            btnActive = true;
            if (this.isRequestAndQuery) {
                if (this.natureVal && this.natureVal != '') {
                    btnActive = true;
                } else {
                    btnActive = false;
                }
            }
        } else {
            btnActive = false;
        }

        this.isNotSelected = !btnActive;
    }

    async getCaseRelatedObjName(cccExtId) {
        //tst Get the Case Extension Object Name
        await getCaseRelatedObjName({ cccId: cccExtId })
            .then(result => {
                this.caseRelObjName = result;
            })
            .catch(error => {
                console.log(error);
            });
    }

    async getCurrentCaseRecordDetails() {
       
        if(this.recordId != null && this.recordId != undefined){
            let result = await getCaseRecordDetails({ 
                recId: this.recordId 
            })
            .catch(error => {
                console.log(error);
                this.showError('error', 'Oops! Error occured while loading the case', error);
            });
            
            this.oldCaseDetails = result;
            this.recategorizeEnabled = result.recategorizeEnabled;
            var caseparsedObject = JSON.parse(this.oldCaseDetails.caseDetails);
            this.accountId = caseparsedObject.AccountId;
            this.assetId = caseparsedObject.AssetId;
            this.currentPriority = caseparsedObject.Priority;
            this.currentCCCId = caseparsedObject.CCC_External_Id__c;
           
            /* CHECK IF THE CASE IS RETURNING ACCOUNT OR NOT. IN CASE OF PROSPECT RELATED CASES
            /* ACCOUNT IS COMING AS NULL.
            /* Author - Virendra
            */
            this.leadId = caseparsedObject.Lead__c;

            if(caseparsedObject.Account != null && caseparsedObject.Account != undefined){
                this.accountRecordType = caseparsedObject.Account.RecordType.Name;
                this.primaryLOBValue = caseparsedObject.Account.Business_Unit__c;
            }
            else if(caseparsedObject.Lead__c != null && caseparsedObject.Lead__c != undefined){
                this.leadRecordType = caseparsedObject.Lead__r.RecordType.Name;
                this.primaryLOBValue = caseparsedObject.Lead__r.Business_Unit__c;
            }
            
            
            //this is without asset parameter. default is false
            //this means , if case is not having asset , then
            //this will be true. 
            this.isasset = 'true';
            if (caseparsedObject.AssetId != undefined && caseparsedObject.AssetId != null){
                //this.assetId = caseparsedObject.AssetId; 
                //once case is associated to asset, reset this
                this.isasset = 'false';
            }
            else if(caseparsedObject.Lead__c != null && caseparsedObject.Lead__c != undefined){
                /* IN CASE OF SERVICE REQUEST CREATED WITH LEAD, FIRST CHECK IF IT IS FIRST ASSOCIATED WITH ASSET, IF YES
                *  EXECUTE FIRST IF BLOCK OTHERWISE, CHECK SET isasset FLAG TO PROSPECT
                *  THIS MEANS RETURN ONLY CTST's THOSE ARE SPECIFIC TO PROSPECT ONLY. THAT IS, ON ASF_CASE_CATEGORY_CONFIG WHERE Is_Prospect_Related__c IS TRUE.
                *  Author - VIRENDRA
                */
                this.isasset = 'Prospect';
            }
            this.loaded = true;
        }
    }

    resetBox() {
        this.dispatchEvent(new CustomEvent('resetbox', {
            detail: {
                message: 'true'
            }
        }));
    }
    
    handleSubSource(event) {
        this.subsourceSelected = event.target.value;
        if (this.subsourceSelected && this.complaintSelected && this.natureVal)
            this.isNotSelected = false;
        else
            this.isNotSelected = true;
    }
    //To get SR Category Reason:
    fetchNatureMetadata(level, nature) {
        fetchNatureMetadata({ level: level, nature: nature }).then(result => {
            this.selectedSRCategory = result;
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
        });
    }

    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    async handleConfirmClick(msg) {
        const result = await LightningConfirm.open({
            message: msg,
            variant: 'headerless',
            label: 'Duplicate Found !',
            // setting theme would have no effect
        });
    }



}