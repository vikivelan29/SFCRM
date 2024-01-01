import { LightningElement, api, wire} from 'lwc';
import updateCaseParent from '@salesforce/apex/ASF_RelateDuplicateCaseController.updateCaseParent';
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecordNotifyChange, getRecords, getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from '@salesforce/apex';

import ISCLOSED_FIELD from '@salesforce/schema/Case.IsClosed';
import LAN_FIELD from '@salesforce/schema/Case.LAN__c';
import PARENTCASEID_FIELD from '@salesforce/schema/Case.ParentId';
import CATEGORY_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import TYPE_FIELD from '@salesforce/schema/Case.Sub_Type_Text__c';
import SUBTYPE_FIELD from '@salesforce/schema/Case.Type_Text__c';

export default class Asf_RelateDeduplicateCase extends LightningElement {
    @api recordId;
    @api objectApiName = 'Case';
    loaded = true;
    @api parentCaseId;
    wiredParentRec;
    wiredCurrentRec;
    @api caseFields = [LAN_FIELD, ISCLOSED_FIELD, PARENTCASEID_FIELD, CATEGORY_FIELD, TYPE_FIELD, SUBTYPE_FIELD];
    
    @wire(getRecord, { recordId: '$recordId', fields: '$caseFields' })
    wiredRecord({ error, data }) {
        if (data) {
            this.wiredCurrentRec = {
                    Lan: getFieldValue(data, LAN_FIELD),
                    IsClosed: getFieldValue(data, ISCLOSED_FIELD),
                    Category: getFieldValue(data, CATEGORY_FIELD),
                    Type: getFieldValue(data, TYPE_FIELD),
                    SubType: getFieldValue(data, SUBTYPE_FIELD)
            };
            this.parentCaseId = getFieldValue(data, PARENTCASEID_FIELD);
        } else if (error) {
            console.error('Error loading record', error);
        }
    }  
    @wire(getRecord, { recordId: '$parentCaseId', fields: '$caseFields' })
    wiredParentRecord({ error, data }) {
        if (data) {
            this.wiredParentRec = {
                Lan: getFieldValue(data, LAN_FIELD),
                IsClosed: getFieldValue(data, ISCLOSED_FIELD),
                Category: getFieldValue(data, CATEGORY_FIELD),
                Type: getFieldValue(data, TYPE_FIELD),
                SubType: getFieldValue(data, SUBTYPE_FIELD)
        };
        } else if (error) {
            console.error('Error loading parent record', error);
        }
    }  
  
    handleSuccess() {
        this.showToastMessage('Success!', 'Changes Saved Successfully', 'success');
    }

    handleError(event) {
        this.showToastMessage('Error!', event.detail.detail, 'error');
    }
    
    handleCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToastMessage(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
    handleParentChange(event){
        this.parentCaseId = event.target.value;
    }

    validateDuplicateCase(){
        let isValid = true;
        if(this.wiredParentRec.IsClosed){
            isValid = false;
            this.showToastMessage('Error!', 'You cannot choose a closed case as parent', 'error');
        }
        else if(this.wiredCurrentRec.Lan && this.wiredCurrentRec.Lan != null && this.wiredCurrentRec.Lan != 'NA' && this.wiredCurrentRec.Lan != ''
                && this.wiredCurrentRec.Lan != this.wiredParentRec.Lan){
            isValid = false;
            this.showToastMessage('Error!', 'Parent case should belong to same LAN as current case', 'error');
        }
        else if(this.wiredCurrentRec.Category != this.wiredParentRec.Category && this.wiredCurrentRec.Type != this.wiredParentRec.Type 
            && this.wiredCurrentRec.SubType != this.wiredParentRec.SubType){
            isValid = false;
            this.showToastMessage('Error!', 'Parent case should belong to same Category, Type and Sub Type as current case', 'error');
        }
        return isValid;
    }

    onSubmitHandler(event) {
        event.preventDefault();
        this.loaded = false;
        const fields = event.detail.fields;
        var isDuplicate = event.detail.fields['Is_Duplicate__c'];

        if(isDuplicate && !this.validateDuplicateCase()){
            this.loaded = true;
            return;
        }
        updateCaseParent({ caseRecordId: this.recordId, parentId: this.parentCaseId, isDuplicate: isDuplicate})
            .then(result => {
                this.loaded = true;
                if(result === 'Success'){

                    this.showToastMessage('Success!', 'Changes Saved Successfully', 'success');
                    this.dispatchEvent(new CloseActionScreenEvent());
                    //eval("$A.get('e.force:refreshView').fire();")
                    getRecordNotifyChange([{ recordId: this.recordId }]);

                }else{
                    this.showToastMessage('Error!', result, 'error');
                }              

            })
            .catch(error => {
                this.loaded = true;
                this.showToastMessage('Error!', error, 'error');
            }); 
    }
}