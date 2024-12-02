import fetchAssets from "@salesforce/apex/ABFL_LegacyView.getLANRelatedAccount";
import fetchMembers from "@salesforce/apex/ABHI_LOBSpecificLegacyViewMethods.getAccountRelatedMembers";
import getLegacyData from "@salesforce/apex/ABHI_LOBSpecificLegacyViewMethods.getLegacyData";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import { api, LightningElement, track, wire } from 'lwc';

import LOB_FIELD from "@salesforce/schema/Account.Business_Unit__c";
import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
const fields = [CLIENT_CODE_FIELD, LOB_FIELD];

export default class Abfl_LegacyCases extends LightningElement {
    @api recordId;
    @api apiName;
    @api payloadInfo;
    arcPolicyNo;
    emailId;
    phoneNo;
    displayTable = false;
    displayError = false;
    showChildTable = false;
    selectedAsset;
    selectedFinalAsset;
    leagcyCaseData;
    startDate;
    endDate;
    loaded = false;
    disabled = false;
    @track displayResult = [];
    options = '';
    memberOptions;
    statusCode;
    columns;
    errorMessage;
    lob;
    isABHI;
    customerId;
    msdCaseNumber;
    selectedMember;
    mapRequest;
    @api dtTableconfigName;

    label = {
        errorMessage,
        pageSize
    };
    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    account;
    connectedCallback() {
        console.log('***rec'+this.recordId);
        console.log(getFieldValue(this.account.data, LOB_FIELD));
        this.isABHI = getFieldValue(this.account.data, LOB_FIELD) == 'ABHI' ? true : false;
        console.log(this.isABHI);
        // get columns
        getColumns({configName: this.dtTableconfigName})
        .then(result => {
                console.log('**rec2>'+JSON.stringify(result));
                this.columns = [
                    {
                        type: "button", label: 'View Case', fixedWidth: 100,typeAttributes: {
                            label: 'View',
                            name: 'View',
                            title: 'View',
                            disabled: false,
                            value: 'view',
                            variant:'neutral',
                        }
                    },
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
            })
            .catch(error => {
                this.showNotification('Error','Error fetching data.','Error');
            });

        // get lans
        this.fetchLan();
        this.fetchMems();
    }

    fetchLan() {
        fetchAssets({accRec: this.recordId})
        .then(result => {
            this.options = result;
            this.options = [{label: 'None', value: ''}, ...result];
        })
        .catch(error => {
            console.error("Error", error);
        })
    }

    fetchMems() {
        fetchMembers({strRecordId: this.recordId})
        .then(result => {
            this.memberOptions = result;
            this.memberOptions = [{label: 'None', value: ''}, ...result];
            this.selectedMember = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        })
        .catch(error => {
            console.error("Error", error);
        })
    }

    resetSearch() {
        this.selectedMember = '';
        this.selectedFinalAsset = '';
        this.msdCaseNumber = '';
        this.phoneNo = '';
        this.emailId = '';
        this.startDate = '';
        this.endDate = '';
        this.selectedAsset = '';
        this.arcPolicyNo = '';
    }

    //Callout to get Legacy data
    fetchLegacyCases() {
        this.displayTable = false;
        this.displayError = false;
        this.data = null;
        this.customerId = this.selectedMember;
        this.lob = getFieldValue(this.account.data, LOB_FIELD);
        console.log('$.$.Acc'+this.lob);
        if(!this.selectedMember && !this.phoneNo && !this.emailId){
            this.selectedMember = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        }
        this.mapRequest = {
            "CustomerNumber": this.selectedMember,
            "PolicyNumber": this.selectedFinalAsset,
            "FromDate": this.startDate,
            "ToDate": this.endDate,
            "LOB": this.lob,
            "CaseNumber": this.msdCaseNumber,
            "PhoneNumber": this.phoneNo,
            "Email_Id": this.emailId
        };
        console.log('$.$.mapReq',this.mapRequest);
        console.log('$.$.jsonMapReq',JSON.stringify(this.mapRequest));
        if(this.checkFieldValidity()) {
            this.disabled = true;
            this.isLoading = true;
            getLegacyData({mapRow: this.mapRequest}).then(result=>{
                this.leagcyCaseData = result;
                console.log('Result1 ==> ', result);
                this.isLoading = false;
                if (this.leagcyCaseData && this.leagcyCaseData.returnCode == '1' && this.leagcyCaseData.statusCode == 200) {
                    this.statusCode = this.leagcyCaseData.statusCode;
                    this.loaded = true;
                    this.displayTable = true;
                    this.data = this.leagcyCaseData.legacyCaseResponse;
                    this.disabled = false;
                }
                else if(this.leagcyCaseData && this.leagcyCaseData.statusCode != 0 && (this.leagcyCaseData.returnCode == '2' || this.leagcyCaseData.returnMessage != null)) {
                    console.log('@@@Erro');
                    this.displayError = true;
                    this.loaded = true;
                    this.errorMessage = this.leagcyCaseData.returnMessage;
                    this.disabled = false;
                    //this.showNotification("Error", this.leagcyCaseData.returnMessage, 'error');
                }
                else if(this.leagcyCaseData && this.leagcyCaseData.statusCode == 0){
                    this.disabled = false;
                    this.showNotification("Error", this.leagcyCaseData.returnMessage, 'error');
                } 
            }).catch(error=>{
                console.log('error ==> ', error);
                this.showNotification("Error", this.label.errorMessage, 'error');
                this.isLoading = false;
                this.loaded = true;
                this.disabled = false;
            })
        }

    }

    handleChange(event) {

        this.selectedAsset = event.detail.value;
        this.arcPolicyNo = '';
        this.selectedFinalAsset = event.detail.value;
        console.log('this.sa'+JSON.stringify(event.detail));
    }

    handleArchPolicyChange(event) {

        this.selectedAsset = '';
        this.arcPolicyNo = event.detail.value;
        this.selectedFinalAsset = event.detail.value;
        console.log('this.ap'+JSON.stringify(event.detail));
    }

    handleEmailChange(event) {

        this.emailId = event.detail.value;
        this.selectedMember = '';
        console.log('this.em'+JSON.stringify(event.detail));
    }

    handlePhoneChange(event) {

        this.phoneNo = event.detail.value;
        this.selectedMember = '';
        console.log('this.ph'+JSON.stringify(event.detail));
    }

    handleMemberChange(event) {

        this.selectedMember = event.detail.value;
        this.emailId = '';
        this.phoneNo = '';
        console.log('this.sm'+JSON.stringify(event.detail));
    }

    handleCaseInput(event){
        this.msdCaseNumber = event.detail.value;
        console.log('this.cn'+JSON.stringify(event.detail));
    }
    
    callRowAction(event) {
        //this.showChildTable = false;
     //   console.log('Hi>1'+JSON.stringify(event.detail));
        // reset var
        this.showChildTable = true;
        this.payloadInfo = null;
        let result = {};
        
        this.selectedRow = JSON.stringify(event.detail);

        console.log('Hi>1'+ this.selectedRow +'2@@ '+this.statusCode);
        result.statusCode= this.statusCode;
        result.payload = this.selectedRow;
        this.payloadInfo = result;

        setTimeout(() => {
            this.template.querySelector('c-abfl_base_view_screen').callFunction();
        }, 200);
    }
    startDateChange(event)
    {
        this.startDate = event.target.value;
        console.log('The startDate selected is '+this.startDate );
    }

    endDateChange(event)
    {
        this.endDate = event.target.value;
        console.log('The endDate selected is '+this.endDate );
    }
    checkFieldValidity(){
        this.isLoading = false;
        let checkAllFieldsValid = true;
        checkAllFieldsValid = [
            ...this.template.querySelectorAll('.inpFieldCheckValidity'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        console.log('checkAllFieldsValid'+checkAllFieldsValid);
        return checkAllFieldsValid;
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