import { LightningElement, track, api, wire } from 'lwc';
import fetchAssets from "@salesforce/apex/ABSLAMC_LegacyView.getLANRelatedAccount";
import getLegacyData from "@salesforce/apex/ABSLAMC_LegacyView.getLegacyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABSLAMC_LegacyPageSize';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import CLIENT_CODE_FIELD from "@salesforce/schema/Account.Client_Code__c";
import LOB_FIELD from "@salesforce/schema/Account.Business_Unit__c";
const fields = [CLIENT_CODE_FIELD, LOB_FIELD];   

export default class ABSLAMC_LegacyCases extends LightningElement {
    @api recordId;
    @api apiName = 'ABSLAMC_Legacy_Case';
    @api payloadInfo;
    displayTable = false;
    displayError = false;
    showChildTable = false;
    selectedAsset;
    leagcyCaseData;
    startDate;
    endDate;
    loaded = false;
    disabled = false;
    @track displayResult = [];
    options = '';
    statusCode;
    columns;
    errorMessage;
    lob;
    customerId;

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
        // get columns
        getColumns({configName:'LegacyCaseView'})
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
                // todo: remove hardcoding
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
        this.customerId = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        this.lob = getFieldValue(this.account.data, LOB_FIELD);
        console.log('Acc'+this.lob);
        if(this.checkFieldValidity()) {
            this.disabled = true;
             this.isLoading = true;
            getLegacyData({customerId: this.customerId, lanNumber: this.selectedAsset, startDate: this.startDate,
                endDate: this.endDate, lob: this.lob}).then(result=>{
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
   /* handleRowSelection(event)
    {   
        this.showChildTable = false;
        let selectedRows = event.detail.selectedRows;
        this.selectedRow = selectedRows[0];
        console.log('the rows selected is '+this.detailJson);
        this.payload['statusCode'] = this.statusCode;
        this.payload['payload'] = JSON.stringify(this.selectedRow);
        this.showChildTable = true;
        setTimeout(() => {             
             this.template.querySelector('c-ABSLAMC_base_view_screen').callFunction();
        }, 200);
    }*/

    handleChange(event) {

        this.selectedAsset = event.detail.value;
        console.log('this.v'+JSON.stringify(event.detail));
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