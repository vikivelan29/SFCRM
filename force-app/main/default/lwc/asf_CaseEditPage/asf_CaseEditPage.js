import { LightningElement,wire, api } from 'lwc';
import getFieldSetFieldsWithValues from '@salesforce/apex/ASF_CaseEditPageController.getfieldSetFieldsWithValues';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NOAUTOCOMM_FIELD from '@salesforce/schema/Case.No_Auto_Communication__c';

export default class Asf_CaseEditPage extends LightningElement {
    @api fieldSetName; 
    @api recordId;
    @api fieldValues = [];
    disableSave = true;
    multiPicklistFieldMap = new Map();
    multiPicklistValueMap = new Map();

    @wire(getObjectInfo, { objectApiName: 'Case' })
    objectInfo;
    
    @wire(getRecord, { recordId: '$recordId', fields: [NOAUTOCOMM_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            // Access the record data and store it in a map 
            this.multiPicklistValueMap.set(NOAUTOCOMM_FIELD.fieldApiName, getFieldValue(data, NOAUTOCOMM_FIELD));
        } else if (error) {
            console.error('Error loading record', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: NOAUTOCOMM_FIELD })
    wiredPicklistValues({ error, data}) {
        if (data){
            //store field API name and picklist options as key value in a map
            this.multiPicklistFieldMap.set(NOAUTOCOMM_FIELD.fieldApiName, data.values);

        } else if (error){
            console.log('error in get picklist--'+JSON.stringify(error));
        }
    }

    @wire(getFieldSetFieldsWithValues, { fieldSetName: 'ASF_Editable_Fields', ObjectName: 'Case', recordId: '$recordId' })
    wiredFieldSet({ error, data }) {
        if (data) {
        
            this.fieldValues = Object.keys(data).map(field => ({ 
                fieldPath: field, 
                ismultiPicklist: this.getDataType(field) === 'MultiPicklist' ? true : false ,
                picklistVal: this.multiPicklistFieldMap.has(field) ? this.multiPicklistFieldMap.get(field) : '',
                fieldLabel: data[field],
                value: this.multiPicklistValueMap.has(field) ? 
                       this.multiPicklistValueMap.get(field) && this.multiPicklistValueMap.get(field).includes(';') ? 
                       this.multiPicklistValueMap.get(field).split(';') : 
                        [this.multiPicklistValueMap.get(field)]
                       : '',
            })); 

        } else if (error) {
            console.error('Error loading record', error);
        }
    } 
    getDataType(fieldName) {
        if (this.objectInfo.data && this.objectInfo.data.fields[fieldName]) {
            return this.objectInfo.data.fields[fieldName].dataType;
        }
        return null;
    }
    handleInputChange(event) {

        this.disableSave = false;
        const fieldPath = event.target.name;
        const value = event.detail.value;

        // Update the field value in the array
        this.fieldValues = this.fieldValues.map(field => {
            if (field.fieldPath === fieldPath) {
                return { ...field, value };
            }
            return field;
        });
    }

    handleSubmit(event) {
        // Prevent the default form submission
        event.preventDefault();
        this.disableSave = true;
        // Get data from submitted form
        var fields = event.detail.fields;

        this.fieldValues.forEach(field => {
            console.log('pick val--'+field.value);
            if(field.ismultiPicklist && field.value){
                fields[field.fieldPath] = field.value.join(';');
            }
        });
        this.template.querySelector('lightning-record-edit-form').submit(fields);

        this.showToastMessage('Success!', 'Changes Saved Successfully', 'success');
    }

    handleSuccess() {
        this.showToastMessage('Success!', 'Changes Saved Successfully', 'success');
    }

    handleError(event) {
        this.showToastMessage('Error!', event.detail.detail, 'error');
    }
    
    showToastMessage(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}