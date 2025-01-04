/*******************************************************************************************
* @Name         cloneCaseActionWebComp
* @Author       Santanu Halder
* @Description  This LWC component provides the UI and client controller logic for the "Clone Case" action on Case object
                The component confirms the user action before performing server request.
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Developer          Date               Description
*-------------------------------------------------------------------------------------------
*  1.0          Santanu Halder      23/10/2023          Initial Creation
*******************************************************************************************/

/** Module imports */
import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import { reduceErrors } from 'c/asf_ldsUtils';
import ABHI_BU from '@salesforce/label/c.ABHI_BU';


/* Apex method imports */
import isCaseCloneable from '@salesforce/apex/ASF_CloneCaseActionController.isCaseCloneable';
import fetchCommonFieldsToCopy from '@salesforce/apex/ASF_CloneCaseActionController.fetchCommonFieldsToCopy';
import fetchCCCSpecificFieldsToCopy from '@salesforce/apex/ASF_CloneCaseActionController.fetchCCCSpecificFieldsToCopy';
import fetchCaseDetailsWithExtension from '@salesforce/apex/ASF_CloneCaseActionController.fetchCaseDetailsWithExtension';
import createCloneCaseV2 from '@salesforce/apex/ASF_CloneCaseActionController.createCloneCaseV2';
import { getRecord } from "lightning/uiRecordApi";

import ACCOUNT_NAME from "@salesforce/schema/Case.Account.Id";
import ASSET_NAME from "@salesforce/schema/Case.Asset.Id";
import BUSINESS_UNIT from "@salesforce/schema/Case.Business_Unit__c";
import ASSET_ID from "@salesforce/schema/Customer_Member_Mapping__c.Policy_Number__c";
import CLIENT_CODE from "@salesforce/schema/Customer_Member_Mapping__c.MemberId__r.Client_Code__c";
import SELECTED_ACCOUNT_ID from "@salesforce/schema/Customer_Member_Mapping__c.MemberId__c";
import ABSLAMC_BU from '@salesforce/label/c.ABSLAMC_BU';

export default class Asf_CloneCaseActionWebCompV2 extends NavigationMixin(LightningElement) {
    /* API variables */
    @api recordId; //Case Id

    /* UI controller variables */
    showConfirmMsg = false;
    isLoading = false; //for spinner control
    accountId ;
    accountName;
    currentAssetName;
    showStartPage = false;
    initialValue;
    filter = {}; 
    filterCm = {};
    cmRecordId;
    newAssetSelected = 'NA';
    caseBusinessUnit = '';
    selectedClientCode = '';
    selectedAccountId = '';
    matchingInfo = {
        primaryField: { fieldPath: "Name" },
        additionalFields: [{ fieldPath: "LAN__c"}],
    };

    displayInfo = {
        additionalFields: ["LAN__c"] 
    };
    matchingInfoCm = {
        primaryField: { fieldPath: "Member_Name__c"},
        additionalFields: [{ fieldPath: "Policy_Number__r.Name"}],
    };

    displayInfoCm = {
        additionalFields: ["MemberId__r.Client_Code__c"]
    };

    get showCustomerMember(){
        return (this.caseBusinessUnit == ABHI_BU);
    }
    handleChange(event) {
        this.newAssetSelected = event.detail.recordId;
        console.log(`Selected record: ${event.detail.recordId}`);
        this.template.querySelector(".assetPicker").reportValidity();
    }
    handleCMChange(event) {
        console.log('selected rec--'+event.detail.recordId+'--'+JSON.stringify(event.detail));
        this.cmRecordId = event.detail.recordId;
        this.template.querySelector(".cmPicker").reportValidity();
    }

    @wire(getRecord, { recordId: "$cmRecordId", fields: [ASSET_ID,CLIENT_CODE,SELECTED_ACCOUNT_ID] })
    user({ error, data}) {
        if (data){
           this.newAssetSelected = data.fields.Policy_Number__c.value;
           this.selectedClientCode = data.fields.MemberId__r.value.fields.Client_Code__c.value;
           this.selectedAccountId = data.fields.MemberId__c.value;
        } else if (error){
            console.log('error in get CM record--'+JSON.stringify(error));
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [ACCOUNT_NAME,ASSET_NAME,BUSINESS_UNIT] })
        wiredRecord({ error, data }) {
            if (error) {
                let errMsg = reduceErrors(error);
                const event = new ShowToastEvent({
                    variant: 'error',
                    title: 'Error loading the case',
                    message: Array.isArray(errMsg)?errMsg[0]:errMsg
                });
                this.dispatchEvent(event);
            } 
            else if (data) {
                console.log('data', JSON.stringify(data));
                this.accountId = data.fields.Account?.value?.id;
                this.accountName = data.fields.Account?.displayValue;
                this.caseBusinessUnit = data.fields.Business_Unit__c.value;
                if(this.caseBusinessUnit && this.caseBusinessUnit === ABSLAMC_BU){
                    this.filter = {
                        criteria: [
                          {
                            fieldPath: "AccountId",
                            operator: "eq",
                            value: this.accountId,
                          },
                        ],
                      };
                } else {
                this.filter = {
                    criteria: [
                      {
                        fieldPath: "Account.Name",
                        operator: "eq",
                        value: this.accountName,
                      },
                    ],
                  };
                  this.filterCm = {
                    criteria: [
                      {
                        fieldPath: "Client_Id__r.Id",
                        operator: "eq",
                        value: this.accountId ?? '',
                      },
                    ],
                };
            }
                if(data.fields.Asset != undefined && data.fields.Asset.value != undefined ){

                    this.initialValue = data.fields.Asset.value.Id;
                    this.currentAssetName = data.fields.Asset.displayValue;
                }
                //data.fields.Account.displayValue
                this.showStartPage = true;
            }
        }

    /* Lifecycle hooks */
    connectedCallback() {
        this.showConfirmMsg = true;
    }

    /* Component functions */
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /** proceedCloning - This is invoked once user confirms the Clone action. Performs the below tasks-
     * 1. Server check if the case is configured as cloneable
     * 2. fetches common fields to copy from Custom Metadata
     * 3. fetches Category specific fields to copy from Field Config
     * 4. fetches existing records with all fields to copy
     * 5. Creates clones of the Case and its extension records
     * 6. Passes the cloned copies to server to insert the data with few other technical fields to populate
     * 7. shows toasts on success and errors
     */
    async proceedCloning() {
        console.log('Cloning...');
        let fieldsToCopy = [];
        let clonedCaseRecord = {};
        let clonedCaseExtnRecords = {}; //Its a map of objectapiname to cloned record
        let isFAMandatory = false;
        let componentName = this.showCustomerMember ? '.cmPicker' : '.assetPicker';
        if(!this.template.querySelector(componentName).reportValidity()){
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error on asset selector',
                message: ''
            });
            this.dispatchEvent(event);
            return;
        }
        //start spinner
        this.isLoading = true;

        //check if cloneable CCC
        try {
            let isCloneableCCCWrap = await isCaseCloneable({
                caseId: this.recordId
            });
            if (!isCloneableCCCWrap.resultFlag) {
                //cloneable CCC NOT found, throw error and abort
                const event = new ShowToastEvent({
                    variant: 'error',
                    title: 'Error',
                    message: isCloneableCCCWrap.reasonIfFalse
                });
                this.dispatchEvent(event);
                this.closeAction();
            }

            //check if user has proper rights to clone (provisional as of now)

            //fetch the common fields to clone from metadata
            let commonFields = await fetchCommonFieldsToCopy({});
            if (commonFields.fieldList
                && commonFields.fieldList.length > 0) {
                fieldsToCopy = [...commonFields.fieldList];
            }
            //override asset here if value is not null

            console.log(JSON.stringify(fieldsToCopy));

            //fetch the cloneable fields from field config
            let specificFields = await fetchCCCSpecificFieldsToCopy({
                caseId: this.recordId
            });
            if (specificFields.fieldList
                && specificFields.fieldList.length > 0) {
                fieldsToCopy = [...fieldsToCopy, ...specificFields.fieldList];
            }
            //checks whether folio is mandatory on CCC, throws error when user proceeds to cloning the case without selecting folio
            isFAMandatory = specificFields.isFAMandatory;
            if(isFAMandatory && (this.newAssetSelected == 'NA' || !this.newAssetSelected)){
               let recpicker = this.template.querySelector(componentName);
               recpicker.setCustomValidity('Please select an asset');
               recpicker.reportValidity();
               recpicker.setCustomValidity('');
               this.isLoading = false;
               return;
            }
            console.log(JSON.stringify(fieldsToCopy), fieldsToCopy.length);


            //fetch existing case with clonable fields with case extension objects
            let caseWrapper = await fetchCaseDetailsWithExtension({
                fieldsToCopy: fieldsToCopy,
                caseId: this.recordId
            });
            console.log(JSON.stringify(caseWrapper));

            //create a clone in JS
            if (caseWrapper.caseRecord) {
                //start cloning
                fieldsToCopy.forEach((field, index) => {
                    if (field.objectAPIName.toUpperCase() == 'Case'.toUpperCase()) {
                        clonedCaseRecord[field.fieldAPIName] = caseWrapper.caseRecord[field.fieldAPIName];
                    }
                });
            }
            console.log(JSON.stringify(clonedCaseRecord));

            //Create extn clones
            if(caseWrapper.extnRecords){
                fieldsToCopy.forEach((field, index) => {
                    console.log('1', field, index);
                    if (field.objectAPIName.toUpperCase() != 'Case'.toUpperCase()) {
                        let sobjectRecord = caseWrapper.extnRecords[field.objectAPIName];
                        if(!clonedCaseExtnRecords.hasOwnProperty(field.objectAPIName)){
                            clonedCaseExtnRecords[field.objectAPIName] = {'sobjectType':field.objectAPIName};
                        }
                        clonedCaseExtnRecords[field.objectAPIName][field.fieldAPIName] = sobjectRecord[field.fieldAPIName];
                    }
                });
            }
            console.log(JSON.stringify(clonedCaseExtnRecords));
        }
        catch (error) {
            //common exception handling for all the check and fetch methods
            console.log(error.body.message, typeof error.body.message, JSON.stringify(reduceErrors(error)));
            let errMsg = reduceErrors(error);
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error while processing',
                message: Array.isArray(errMsg)?errMsg[0]:errMsg
            });
            this.dispatchEvent(event);
            this.isLoading = false;
            this.closeAction();
            return;
        }
        const inpArg = new Map();

        inpArg['clientCode'] = this.selectedClientCode;
        inpArg['memberId'] = this.selectedAccountId;

        let strInpArg = JSON.stringify(inpArg);

        try {
            //insert the clone records
            let caseResult = await createCloneCaseV2({
                cloneCaseRecord: clonedCaseRecord,
                clonedCaseExtnRecords : clonedCaseExtnRecords,
                originalCaseId : this.recordId,
                assetId : this.newAssetSelected,
                inpArg : strInpArg

            });
            console.log('Cloned case id ', caseResult.caseRecord.Id);

            const successevent = new ShowToastEvent({
                variant: 'success',
                title: 'Cloning successful',
                message: 'Successfully cloned the Case'
            });
            this.dispatchEvent(successevent);

            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    objectApiName: "Case",
                    actionName: "view",
                    recordId: caseResult.caseRecord.Id
                }
            });
            this.isLoading = false;
            //check if the fields which are supposed to be recalculated are recalculated or not - Unit testing.
        }
        catch (error) {
            let errMsg = reduceErrors(error);
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Error while creating clone',
                message: Array.isArray(errMsg)?errMsg[0]:errMsg
            });
            this.dispatchEvent(event);
            this.isLoading = false;
            this.closeAction();
        }
    }

}
