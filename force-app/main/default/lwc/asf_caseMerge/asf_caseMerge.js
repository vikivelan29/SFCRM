import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable,getRecordNotifyChange } from "lightning/uiRecordApi";
import fetchCases from "@salesforce/apex/ASF_CasemergeController.fetchCases"
import mergeCases from "@salesforce/apex/ASF_CasemergeController.mergeCases"
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import SUPPLIEDEMAIL_FIELD from '@salesforce/schema/Case.SuppliedEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import mergeError from '@salesforce/label/c.ASF_Error_Case_Merge';
import mergeSuccess from '@salesforce/label/c.ASF_Success_Case_Merge';
import noRecSelError from '@salesforce/label/c.ASF_No_Record_Selected';
import noRecFound from '@salesforce/label/c.ASF_No_Merge_Duplicates';
import { reduceErrors } from 'c/asf_ldsUtils';
const FIELDS = [SUBJECT_FIELD, SUPPLIEDEMAIL_FIELD];

export default class Asf_caseMerge extends LightningElement {
    @api recordId;
    check = 0;
    showtable = true;
    selectedStep = '1';
    selectedRec = [];
    selectedRecId;
    noRecFound = noRecFound;
    caseColumns = [
        { label: 'SR Number', fieldName: 'CaseNumber' },
        { label: 'Subject', fieldName: 'Subject' },
        { label: 'Description', fieldName: 'Description' },
        { label: 'Email', fieldName: 'SuppliedEmail' },
        { label: 'Owner', fieldName: 'OwnerId' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date-local' },
        { label: 'Status', fieldName: 'Status' }
    ];
    caseList;
    error;
    toastMessage;
    toastTitle;
    toastvariant;
    showModal = true;
    caseSubject;
    suppliedEmail;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCaseRecord({ error, data }) {
        if (data) {
            this.caseSubject = getFieldValue(data, SUBJECT_FIELD);
            this.suppliedEmail = getFieldValue(data, SUPPLIEDEMAIL_FIELD);
            this.getCasesData();
        }
        else if (error) {
            this.error = error;
        }
    }
    renderedCallback() {
        if (this.check < 2) {
            //this.getCasesData();
        }

    }

    getCasesData() {
        this.check = this.check + 1;
        fetchCases({ recordId: this.recordId, caseSubject: this.caseSubject, suppliedEmail: this.suppliedEmail })
            .then(result => {
                if (result != '') {
                    this.showtable = true;
                    this.caseList = result;
                    let parsedCase = JSON.parse(JSON.stringify(result));
                    parsedCase.forEach(caseRecord => {
                        if (caseRecord.OwnerId) {
                            caseRecord.OwnerId = caseRecord.Owner.Name;
                        }
                    });
                    this.caseList = parsedCase;
                }
                else {
                    this.showtable = false;
                }
            })
            .catch(error => {

            });

    }
    getSelectedRec() {
        return this.template.querySelector("lightning-datatable").getSelectedRows();
    }
    completeMerge(event) {
        this.selectedRec = this.getSelectedRec();
        if (this.selectedRec.length == 0) {
            this.toastTitle = 'Error';
            this.toastMessage = noRecSelError;
            this.toastvariant = 'Error';
            this.showToast();
        }
        else {
            let caseIdList = this.selectedRec.map(caseRec => caseRec.Id);
            mergeCases({ selectedRec: this.selectedRec, masterRecId: this.recordId, selectedCaseIdList: caseIdList})
                .then((result) => {
                    this.error = undefined;
                    this.toastTitle = 'Merged Successfully';
                    this.toastMessage = mergeSuccess;
                    this.toastvariant = 'success';
                    this.showToast();
                    this.getCasesData();

                    getRecordNotifyChange([{ recordId: this.recordId }]);
                    //eval("$A.get('e.force:refreshView').fire();");
                })
                .catch((error) => {
                    this.error = error;
                    this.toastTitle = 'Failed to merge SR';
                    this.toastMessage = this.error;
                    this.toastvariant = 'Error';
                    this.showError('Error', 'Failed to merge SR', error) 
                    this.data = undefined;
                });
        }

    }
    showToast() {
        const event = new ShowToastEvent({
            title: this.toastTitle,
            message: this.toastMessage,
            variant: this.toastvariant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
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


}