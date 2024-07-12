import { LightningElement, api, wire} from 'lwc';
import updateCaseParent from '@salesforce/apex/ASF_RelateDuplicateCaseController.updateCaseParent';
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecordNotifyChange, getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';
import { fireEventNoPageRef } from 'c/asf_pubsub';

import ISCLOSED_FIELD from '@salesforce/schema/Case.IsClosed';
import LAN_FIELD from '@salesforce/schema/Case.LAN__c';
import PARENTCASEID_FIELD from '@salesforce/schema/Case.ParentId';
import CATEGORY_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import TYPE_FIELD from '@salesforce/schema/Case.Sub_Type_Text__c';
import SUBTYPE_FIELD from '@salesforce/schema/Case.Type_Text__c';
import OWNER_FIELD from '@salesforce/schema/Case.OwnerId';
import BUSINESS_UNIT_FIELD from '@salesforce/schema/Case.Business_Unit__c'
import IS_DUPLICATE_FIELD from '@salesforce/schema/Case.Is_Duplicate__c'
import USER_ID from '@salesforce/user/Id';
import { lanLabels } from 'c/asf_ConstantUtility';

export default class Asf_RelateDeduplicateCase extends LightningElement {
    @api recordId;
    @api objectApiName = 'Case';
    loaded = false;
    showPage = false;
    @api parentCaseId;
    businessUnit;
    @wire(CurrentPageReference) pageRef;
    wiredParentRec;
    wiredCurrentRec;
    userId = USER_ID;
    errorMessage = 'You do not have access. Only case owner is allowed to mark the case as Relate/ Duplicate';
    lanErrorMessage;
    @api caseFields = [LAN_FIELD, ISCLOSED_FIELD, PARENTCASEID_FIELD, CATEGORY_FIELD, TYPE_FIELD, SUBTYPE_FIELD, OWNER_FIELD, BUSINESS_UNIT_FIELD, IS_DUPLICATE_FIELD];
    
    //wire to get the current case details
    @wire(getRecord, { recordId: '$recordId', fields: '$caseFields' })
    wiredRecord({ error, data }) {
        if (data) {
            this.wiredCurrentRec = {
                    Lan: getFieldValue(data, LAN_FIELD),
                    IsClosed: getFieldValue(data, ISCLOSED_FIELD),
                    Category: getFieldValue(data, CATEGORY_FIELD),
                    Type: getFieldValue(data, TYPE_FIELD),
                    SubType: getFieldValue(data, SUBTYPE_FIELD),
                    Owner: getFieldValue(data, OWNER_FIELD),
                    BusinessUnit : getFieldValue(data, BUSINESS_UNIT_FIELD),
                    IsDuplicate : getFieldValue(data, IS_DUPLICATE_FIELD)
            };
            this.parentCaseId = getFieldValue(data, PARENTCASEID_FIELD);
            this.businessUnit = getFieldValue(data, BUSINESS_UNIT_FIELD);
            this.lanErrorMessage = lanLabels[this.businessUnit].RELATE_DUP_LAN_ERRORMSG != null? lanLabels[this.businessUnit].RELATE_DUP_LAN_ERRORMSG : lanLabels["DEFAULT"].RELATE_DUP_LAN_ERRORMSG;
            this.ownerValidation();
        } else if (error) {
            console.error('Error loading record', error);
        }
    }  
    //wire to get the parent case details
    @wire(getRecord, { recordId: '$parentCaseId', fields: '$caseFields' })
    wiredParentRecord({ error, data }) {
        if (data) {
            this.wiredParentRec = {
                Lan: getFieldValue(data, LAN_FIELD),
                IsClosed: getFieldValue(data, ISCLOSED_FIELD),
                Category: getFieldValue(data, CATEGORY_FIELD),
                Type: getFieldValue(data, TYPE_FIELD),
                SubType: getFieldValue(data, SUBTYPE_FIELD),
                BusinessUnit : getFieldValue(data, BUSINESS_UNIT_FIELD),
                IsDuplicate : getFieldValue(data, IS_DUPLICATE_FIELD)
        };
        } else if (error) {
            console.error('Error loading parent record', error);
        }
    }
    ownerValidation(){
        this.loaded = true;
        if(this.wiredCurrentRec.Owner === this.userId){
            this.showPage = true;
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
        if(this.wiredParentRec.IsDuplicate && (this.wiredParentRec.BusinessUnit =='ABFL' || this.wiredParentRec.BusinessUnit=='ABWM') && (this.wiredCurrentRec.BusinessUnit =='ABFL' || this.wiredCurrentRec.BusinessUnit=='ABWM')){
            isValid = false;
            this.showToastMessage('Error!', 'You cannot choose a duplicate case as parent', 'error');
        }
        else if(this.wiredParentRec.IsClosed && this.wiredParentRec.BusinessUnit !='ABFL' && this.wiredParentRec.BusinessUnit!='ABWM' && this.wiredCurrentRec.BusinessUnit !='ABFL' && this.wiredCurrentRec.BusinessUnit!='ABWM'){
            isValid = false;
            this.showToastMessage('Error!', 'You cannot choose a closed case as parent', 'error');
        }
        else if(this.wiredCurrentRec.Lan && this.wiredCurrentRec.Lan != null && this.wiredCurrentRec.Lan != 'NA' && this.wiredCurrentRec.Lan != ''
                && this.wiredCurrentRec.Lan != this.wiredParentRec.Lan){
            isValid = false;
            this.showToastMessage('Error!', this.lanErrorMessage, 'error');
        }
        else if(this.wiredCurrentRec.Category != this.wiredParentRec.Category || this.wiredCurrentRec.Type != this.wiredParentRec.Type 
            || this.wiredCurrentRec.SubType != this.wiredParentRec.SubType){
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
                    let payload = {'source':'relateDup', 'recordId':this.recordId};
                    fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload); 
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