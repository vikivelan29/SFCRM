import { LightningElement,track,api} from 'lwc';

import getSurveyResponseFieldsByAccountId from '@salesforce/apex/Abhfl_GenericRepeatingAndOpenComplntClas.getSurveyResponseFieldsByAccountId';

export default class abhfl_surveyResponseView extends LightningElement {

    @api accountId;
    @track surveyresponse = [];
    @track surveyresponse1 = [];
    @track surveyresponse2 = [];
    @track errorinresponse;
    @track columns = [];
    @track columns1 = [];
    @track columns2 = [];
    @track isrespdataaval = false;
    @track isloading = true;
    errorMessage;
    @api tabName;


    
    
    connectedCallback() {
        
        console.log('recordId:', this.accountId);  // Log to check if recordId is available
        if (this.accountId) {
            this.openSurveyResponse();  // Ensure openSurveyResponse is defined and available
        } else {
            console.error('No accountId available');
        }
    }
    // this.getCaseRecordCommon();

    async openSurveyResponse() {
        console.log('I m here');
        // this.getCaseRecordCommon();
        this.isloading = true;
        await getSurveyResponseFieldsByAccountId({
                accountId: this.accountId
            })
            .then(data => {
                this.isloading = false;
                this.isrespdataaval = true;
                this.columns = data.columnwrap;
                this.columns1 = data.columnwrap1;
                this.columns2 = data.columnwrap2;
                this.surveyresponse = data.rowdata;
                this.surveyresponse1 = data.rowdata1;
                this.surveyresponse2 = data.rowdata2;
                console.log('data-->' + JSON.stringify(data));
                this.mapPicklistOptionsToRows(this.surveyresponse, data.columnwrap);
                this.mapPicklistOptionsToRows(this.surveyresponse1, data.columnwrap1);
                this.mapPicklistOptionsToRows(this.surveyresponse2, data.columnwrap2);
                //this.setupColumns(data);
                //this.error = undefined;
            })
            .catch(error => {
                //this.error=true;
                this.isloading = false;
                console.log('errror-->' + JSON.stringify(error));
                this.errorMessage = error.body.message;
                //this.errorMessage='Error fetching Survey Response: ' + error.body.message;
                // this.error = 'Error fetching Survey Response: ' + error.body.message;
                // this.opportunities = [];
            });
    }
    mapPicklistOptionsToRows(rows, columnwrap) {
        // Iterate through each row and column
        rows.forEach(row => {
            columnwrap.forEach(column => {
                console.log('column:::', JSON.stringify(column))
                console.log('row:::', JSON.stringify(row))
                let picklistField = column.fieldName; //case__r.Nature__c
                if (column.options && column.fieldName) {
                    // Find the corresponding picklist label based on the API name
                    const picklistOptions = column.options;
                    //added by Mrinal Tripathi for Nature field issue fix starts
                    let selectedValue = ''
                    if(picklistField == 'Case__r.Nature__c'){
                        if(row['Case__r'] != undefined && row['Case__r'].Nature__c != undefined)
                         selectedValue = row['Case__r'].Nature__c
                    }
                    if (picklistField.includes('Case__r.')) {
                        if (row['Case__r'] != undefined && row['Case__r'][picklistField.split('.')[1]] != undefined)
                            selectedValue = row['Case__r'][picklistField.split('.')[1]];
                    } else {
                        selectedValue = row[picklistField];
                    }
                    //Mrinal Tripathi for Nature field issue fix ends

                    const selectedOption = picklistOptions.find(option => option.value === selectedValue);

                    if (selectedOption) {
                        // Replace the API name with the label
                        row[picklistField] = selectedOption.label;
                    }
                } else {
                    let selectedValue = ''
                    if (picklistField.includes('Case__r.')) {
                        if (row['Case__r'] != undefined && row['Case__r'][picklistField.split('.')[1]] != undefined)
                            selectedValue = row['Case__r'][picklistField.split('.')[1]];
                    } else {
                        selectedValue = row[picklistField];
                    }
                    if (selectedValue) {
                        row[picklistField] = selectedValue;
                    }
                }
            });
        })
    }
    closeresp() {
        this.isrespdataaval = false;
    }

}