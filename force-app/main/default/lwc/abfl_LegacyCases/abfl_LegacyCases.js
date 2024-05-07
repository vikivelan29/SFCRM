import { LightningElement, track, api } from 'lwc';
import fetchAssets from "@salesforce/apex/ABFL_LegacyView.getLANRelatedAccount";
import getLegacyData from "@salesforce/apex/ABFL_LegacyView.getLegacyData";
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';

// const columns = [
    
//     { label: 'Customer Name', fieldName: 'Customer' },
//     { label: 'Case Id', fieldName: 'CaseID' },
//     { label: 'Category', fieldName: 'Category'},
//     { label: 'Case Type', fieldName: 'CaseType' },
//     { label: 'Case SubType', fieldName: 'SubType' },
//     { label: 'Source', fieldName: 'Source' },
//     { label: 'Loan No', fieldName: 'LoanAccountNo' },
//     { label: 'Case Created Date', fieldName: 'CreatedOn'},
//     { label: 'Case Status', fieldName: 'CaseStatus' },
//     { label: 'Last Updated Date', fieldName: 'LastUpdatedOn'},
//     { label: 'Case Owner', fieldName: 'Owner' },
// ];

export default class Abfl_LegacyCases extends LightningElement {
    @api recordId;
    @api apiName = 'ABFL_Legacy_Case';
    displayTable = false;
    displayError = false;
    showChildTable = false;
    selectedAsset;
    leagcyCaseData;
    startDate;
    endDate;
    payload = [];
    @track displayResult = [];
    options = '';
    statusCode;
    columns;
    errorMessage;
   
   /* @wire(fetchAssets,{accRec: "$recordId"})
        fetchAssets ({ error, data }) {
            if (data) {
                console.log('@@rec2'+this.recordId);
                this.options = data;
                //this.lstaccounts = data;
            } else if (error) {
                console.log('@@rec1'+this.recordId);
                this.error = error;
            }    
    }*/
    label = {
        errorMessage
    };
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
        console.log('selected asset', this.selectedAsset);
        if(this.checkFieldValidity()) {
            getLegacyData({customerId: this.recordId, lanNumber: this.selectedAsset, startDate: this.startDate,
                endDate: this.endDate}).then(result=>{
                this.leagcyCaseData = result;
                console.log('Result1 ==> ', result);
                this.isLoading = false;
                if (this.leagcyCaseData && this.leagcyCaseData.returnCode == '1' && this.leagcyCaseData.statusCode == 200) {
                    this.statusCode = this.leagcyCaseData.statusCode;
                    this.displayTable = true;
                    this.data = this.leagcyCaseData.legacyCaseResponse;
                }
                else if(this.leagcyCaseData && this.leagcyCaseData.returnCode == '2') {
                    console.log('@@@Erro');
                    this.displayError = true;
                    this.errorMessage = this.leagcyCaseData.returnMessage;
                    //this.showNotification("Error", this.leagcyCaseData.returnMessage, 'error');
                }
                else if(this.leagcyCaseData && this.leagcyCaseData.statusCode != 200 && result.response.includes('error_message')){
                    let parsedjson = JSON.parse(JSON.parse(result.response).body);
                    this.showNotification("Error", parsedjson.error_message, 'error');
                } 
            }).catch(error=>{
                console.log('error ==> ', error);
                this.showNotification("Error", this.label.errorMessage, 'error');
                this.isLoading = false;
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
             this.template.querySelector('c-abfl_base_view_screen').callFunction();
        }, 200);
    }*/

    handleChange(event) {

        this.selectedAsset = event.detail.value;
        console.log('this.v'+JSON.stringify(event.detail));
     }
    callRowAction(event) {
        console.log('Hi'+JSON.stringify(event.detail.row));
        this.showChildTable = false;
        this.selectedRow = JSON.stringify(event.detail.row);
        this.payload['statusCode'] = this.statusCode;
        this.payload['payload'] = this.selectedRow;
        this.showChildTable = true;
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