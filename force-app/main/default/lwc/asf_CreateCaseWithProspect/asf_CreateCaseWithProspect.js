import { LightningElement, track } from 'lwc';
import getAccountData from '@salesforce/apex/ASF_CreateCaseWithTypeController.getAccountDataByCustomerType';

import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';
import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';

export default class Asf_CreateCaseWithProspect extends LightningElement {
    @track loaded = true;
    typingTimer;
    doneTypingInterval = 300;
    @track accounts;
    strSource = '';
    sourceFldValue;
    sourceFldOptions;
    boolShowNoData = false;
    strDefaultChannel = '';
    strChannelValue = '';
    strNoDataMessage = '';
    boolAllChannelVisible = false;
    boolAllSourceVisible = false;
    createCaseWithAll = false;
    isNotSelected = true;
    isAllNature = false;
    isAllSource = false;



    cols = [
        { label: 'Nature', fieldName: 'Nature__c', type: 'text' },
        { label: 'LOB', fieldName: 'LOB__c', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Sub_Type__c', type: 'text' }
    ]


    handelSearchKey(event) {
        clearTimeout(this.typingTimer);
        this.searchKey = event.target.value;

        this.typingTimer = setTimeout(() => {
            if (this.searchKey && this.searchKey.length >= 3) {
                this.SearchAccountHandler();
            }
        }, this.doneTypingInterval);
    }
    SearchAccountHandler() {
        getAccountData({ keyword: this.searchKey, asssetProductType: "", isasset: "false", accRecordType : null })
            .then(result => {
                if (result != null && result.boolNoData == false) {
                    this.accounts = result.lstCCCrecords;
                    this.strSource = result.strSource;
                    if(this.strSource) {
                        this.populateSourceFld();
                    }
                    this.boolShowNoData = false;
                    if (result.lstChannel != null && result.lstChannel.length > 0) {
                        //this.createCaseWithAll = true;
                        this.lstChannelValues = result.lstChannel;
                        this.strDefaultChannel = this.lstChannelValues[0].label;
                        this.strChannelValue = this.strDefaultChannel;
                        this.boolChannelVisible = true;

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
                console.log('tst22423', error);
                this.isNotSelected = true;
                this.loaded = true;
            });

    }
    populateSourceFld() {
        let getAllSourceFldValues = this.strSource.split(',');
        this.sourceFldValue = getAllSourceFldValues[0];
        this.sourceFldOptions = getAllSourceFldValues.map(fldVal => ({label : fldVal, value : fldVal}));
    }

    getSelectedName(event) {
        var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0];
        if (selected) {
            this.boolAllChannelVisible = true;
            this.boolAllSourceVisible = true;
        }
        if ((selected) && (this.businessUnit == 'ABFL')) {
            this.boolAllChannelVisible = false;
            this.boolAllSourceVisible = true;
        }

        if (selected) {
            this.createCaseWithAll = true;
            this.isNotSelected = true;

            if (selected[NATURE_FIELD.fieldApiName] == "All") {
                this.isAllNature = true;
            }
            if (selected[SOURCE_FIELD.fieldApiName] == "All") {
                this.isAllSource = true;
            }
        }
    }
}