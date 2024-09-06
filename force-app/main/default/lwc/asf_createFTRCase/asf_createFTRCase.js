import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord, getRecord } from "lightning/uiRecordApi";
import getCaseFieldsConfig from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseFieldsConfig';
import getUserDetails from '@salesforce/apex/ASF_CreateCaseWithTypeController.getUserDetails';
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import LOB_FIELD from "@salesforce/schema/Account.Line_of_Business__c";
import BUSINESS_UNIT_FIELD from "@salesforce/schema/Account.Business_Unit__c";
import CCC_External_Id_FIELD from "@salesforce/schema/ASF_Case_Category_Config__c.CCC_External_Id__c";

export default class Asf_createFTRCase extends NavigationMixin(LightningElement) {
    label = {
        errorMessage
    };

    @api recordId;
    @track accountData;
    @track error;
    @track cccRecordId;
    @track cccExternalId;

    loading = false;
    submitButtonDisabled = true;
    fieldsMetadata;
    caseRelObjName;
    caseExtensionRecordId;
    caseRecordId;

    matchingInfo = {
        primaryField: { fieldPath: 'Type__c' },
        additionalFields: [{ fieldPath: 'Sub_Type__c' }],
    };

    displayInfo = {
        primaryField: 'Type_SubType_LOB__c'
    };

    recordPickerFilter = {
        criteria: [
            {
                fieldPath: 'Business_Unit__c',
                operator: 'eq',
                value: '',
            },
            {
                fieldPath: 'LOB__c',
                operator: 'eq',
                value: ''
            },
            {
                fieldPath: 'Quick_Kill__c',
                operator: 'eq',
                value: true,
            }
        ]
    };

    @wire(getRecord, { recordId: "$cccRecordId", fields: [CCC_External_Id_FIELD] })
    wiredCCCRecord({ error, data }) {
        if (data) {
            this.cccExternalId = data?.fields?.CCC_External_Id__c?.value;
            if (this.cccExternalId) {
                this.callGetCaseFieldsConfig();
            }
        } else if (error) {
            this.error = error;
            console.log(error);
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [LOB_FIELD, BUSINESS_UNIT_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountData = data;
            this.recordPickerFilter.criteria[0].value = this.accountData.fields.Business_Unit__c.value;
            this.recordPickerFilter.criteria[1].value = this.accountData.fields.Line_of_Business__c.value;
            this.template.querySelector('lightning-record-picker').filter = JSON.parse(JSON.stringify(this.recordPickerFilter));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accountData = undefined;
            console.log(error);
        }
    }

    invokeCloseModal() {
        this.dispatchEvent(new CustomEvent('closepopup', {
            detail: {
                message: true
            }
        }));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    async callGetCaseFieldsConfig() {
        if (this.cccExternalId) {
            this.loading = true;
            let result = await getCaseFieldsConfig({ cccId: this.cccExternalId, status: 'Open', caseId: '' })
                .catch(error => {
                    console.log(error);
                    this.loading = false;
                    this.showToast('Error', this.label.errorMessage, 'Error');
                });

            if (result) {
                this.fieldsMetadata = JSON.parse(JSON.stringify(result));
                let caseFieldsCount = 0, extnFieldsCount = 0;
                for (let item of this.fieldsMetadata) {
                    if (item.isCase == true) {
                        caseFieldsCount++;
                    } else {
                        extnFieldsCount++;
                        this.caseRelObjName = item.ObjectAPIName;
                    }
                }
                let isOdd = (caseFieldsCount % 2 == 1);
                let isOddExtn = (extnFieldsCount % 2 == 1);

                this.fieldsMetadata = this.fieldsMetadata.map((item, index) => {
                    if (item.isCase == true) {
                        caseFieldsCount--;
                        if (isOdd && caseFieldsCount == 0) {
                            //last item
                            item['layoutItemSize'] = 12;
                        } else {
                            item['layoutItemSize'] = 6;
                        }
                    } else {
                        extnFieldsCount--;
                        if (isOddExtn && item.isCase == undefined && extnFieldsCount == 0) {
                            //last item
                            item['layoutItemSize'] = 12;
                        } else {
                            item['layoutItemSize'] = 6;
                        }
                    }
                    return item;
                });
                this.submitButtonDisabled = false;
                this.loading = false;
            }
        }
    }

    async handleRecordPickerChange(event) {
        this.cccRecordId = event.detail.recordId;

        if (this.cccRecordId == null) {
            this.fieldsMetadata = null;
            this.cccExternalId = null;
            this.submitButtonDisabled = true;
        }
    }

    async handleSubmit() {
        let isFormValidated = this.validateFields();
        if (!isFormValidated) {
            this.showToast('Mandatory fields missing', 'Please fill all mandatory fields for this stage', 'error');
            return;
        }
        this.loading = true;

        if (this.caseRelObjName) {
            let caseExtfields = {};

            let caseExtnElement = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjForm"]');
            if (caseExtnElement) {
                let inputFields = [...caseExtnElement.querySelectorAll('lightning-input-field')];
                let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
                caseExtfields = Object.fromEntries([...fieldsVar]);

                const caseExtnRecord = { apiName: this.caseRelObjName, fields: caseExtfields };

                await createRecord(caseExtnRecord)
                    .then(result => {
                        this.caseExtensionRecordId = result.id;
                    })
                    .catch(error => {
                        this.loading = false;
                        this.showToast('Error', this.label.errorMessage, 'Error');
                    })

            }
        }

        let caseFields = {};
        let caseElement = this.template.querySelector('lightning-record-edit-form[data-id="CaseForm"]');
        if (caseElement) {
            let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
            let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
            caseFields = Object.fromEntries([...fieldsVar]);
            if (this.caseRelObjName) {
                caseFields[this.caseRelObjName] = this.caseExtensionRecordId;
            }

            await getUserDetails()
                .then(result => {
                    if (result.lstChannel != null && result.lstChannel.length > 0) {
                        caseFields["Source__c"] = result.strSource;
                        caseFields["Channel__c"] = result.lstChannel[0].label;
                    }
                })
                .catch(error => {
                    this.loading = false;
                    this.showToast('Error', this.label.errorMessage, 'Error');
                })

            caseFields["CCC_External_Id__c"] = this.cccExternalId;
            caseFields["Technical_Source__c"] = 'LWC';
            caseFields['AccountId'] = this.recordId;
            caseFields["OnCreateCloseSR__c"] = true;
            caseFields["No_Auto_Communication__c"] = 'Email;SMS;WhatsApp';
            caseFields["Business_Unit__c"] = this.accountData.fields.Business_Unit__c.value;
            //add source from user record

            const caseRecord = { apiName: 'Case', fields: caseFields };

            createRecord(caseRecord)
                .then(result => {
                    this.caseRecordId = result.id;
                    this.loading = false;
                    this.showToast('Success', 'Case record created successfully', 'success');
                    this.invokeCloseModal();
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.caseRecordId,
                            actionName: 'view'
                        },
                        state: {
                            mode: 'edit'
                        }
                    });
                    this.dispatchEvent(new CloseActionScreenEvent());

                })
                .catch(error => {
                    this.loading = false;
                    this.showToast('Error', this.label.errorMessage, 'Error');
                })
        }
    }

    validateFields() {
        this.template.querySelectorAll("lightning-input-field").forEach(field => {
            field.reportValidity();
        });
        return [...this.template.querySelectorAll("lightning-input-field")].reduce((validSoFar, field) => {

            return (validSoFar && field.reportValidity());
        }, true);
    }
}