import { LightningElement, track, api, wire } from 'lwc';
import fetchAssets from "@salesforce/apex/ABSLAMC_LegacyView.getLANRelatedAccount";
import getLegacyData from "@salesforce/apex/ABSLAMC_LegacyView.getLegacyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABSLAMC_LegacyPageSize';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import CLIENT_CODE_FIELD from "@salesforce/schema/Account.PAN__c";
import LOB_FIELD from "@salesforce/schema/Account.Business_Unit__c";
import ARN_FIELD from "@salesforce/schema/Account.ARN_Number__c";
import RECORD_TYPE_FIELD from "@salesforce/schema/Account.RecordType.Name";

const fields = [CLIENT_CODE_FIELD, LOB_FIELD, ARN_FIELD, RECORD_TYPE_FIELD];   

export default class ABSLAMC_LegacyCases extends LightningElement {
    @api recordId;
    @api apiName = 'ABSLAMC_Legacy_Case';
    @api payloadInfo;
    displayTable = false;
    displayError = false;
    showChildTable = false;
    selectedAsset;
    leagcyCaseData;
    loaded = false;
    disabled = false;
    @track displayResult = [];
    options = '';
    statusCode;
    columns;
    errorMessage;
    lob;
    customerId;
    arnNumber;
    showDropdown = false;

    label = {
        errorMessage,
        pageSize
    };
 
    @wire(getRecord, {recordId: "$recordId",fields})
    wiredAccount({ error, data }) {
        if (data) {
            console.log('Account Data: ', data);
            const recordType = getFieldValue(data, RECORD_TYPE_FIELD);
            console.log('Record Type Developer Name: ', recordType);
            this.customerId = getFieldValue(data, CLIENT_CODE_FIELD);
            console.log('Client Code: ', this.customerId);
            this.lob = getFieldValue(data, LOB_FIELD);
            console.log('BU: ', this.lob);
            this.arnNumber = getFieldValue(data, ARN_FIELD);
            console.log('ARN: ', this.arnNumber);

            if (recordType === 'ABSLAMC Individual Distributor' || recordType === 'ABSLAMC Non-Individual Distributor') {
                this.showDropdown = false;
                console.log('Record type is Distributor. Calling fetchLegacyCases...');
                this.fetchLegacyCases();
            } else {
                this.showDropdown = true;
            }
        } else if (error) {
            console.error('Error fetching account data: ', error);
        }
    }

    connectedCallback() {
        console.log('***rec'+this.recordId);
        // get columns
        getColumns({configName:'AMC_DMS_File_Datatable'})
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
                console.error(error);
                this.showNotification('Error','Error fetching data.','Error');
            });

        // get lans
        this.fetchLan();
    }

    fetchLan() {
        fetchAssets({accRec: this.recordId})
        .then(result => {
            this.options = result;
        })
        .catch(error => {
            console.error("Error", error);
        })
    }
    //Callout to get Legacy data
    fetchLegacyCases() {
        this.displayTable = false;
        this.displayError = false;
       

        this.data = null;
        console.log('Acc'+this.lob);
        if(this.checkFieldValidity()) {
            this.disabled = true;
             this.isLoading = true;
             console.log('inputs->>',this.customerId,this.selectedAsset,this.arnNumber,this.lob);
            getLegacyData({customerId: this.customerId, lanNumber: this.selectedAsset, arnNumber: this.arnNumber, lob: this.lob}).then(result=>{
                this.leagcyCaseData = result;
                console.log('Result1 ==> ', result);
                this.isLoading = false;
                console.log('data-->',this.leagcyCaseData.legacyCaseResponse);
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
        console.log('this.v'+JSON.stringify(event.detail));
     }
    
    callRowAction(event) {
        this.showChildTable = true;
        this.payloadInfo = null;
        let result = {};
        
        this.selectedRow = JSON.stringify(event.detail);

        console.log('Hi>1'+ this.selectedRow +'2@@ '+this.statusCode);
        result.statusCode= this.statusCode;
        result.payload = this.selectedRow;
        this.payloadInfo = result;
        console.log('details-->',this.statusCode,'Result-->',JSON.stringify(result));
        setTimeout(() => {     
            console.log('inside timeout');        
            this.template.querySelector('c-abfl_base_view_screen').callFunction();
        }, 200);
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

    clearSelection(event){
        this.customerId = '';
        this.selectedAsset = '';
        this.arnNumber = '';
        this.lob = '';
        this.displayTable = false;
    }
}