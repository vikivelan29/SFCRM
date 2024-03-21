import { LightningElement, api, track, wire } from 'lwc';
import Days_For_Repeated_Indicator from '@salesforce/label/c.Repeated_Indicator';
import getRecords from '@salesforce/apex/Abhfl_GenericRepeatingAndOpenComplntClas.genericFetchQuery';

export default class Abhfl_GenericRepeatingAndOpenComplaintCase extends LightningElement {

    @api recordId;
    @api objectApiName;

    @track caseRecord;
    @track records;
    @track fieldArr = 'id';

    whereClauseForRI = '';
    whereClauseForOC = '';
    riFlag;
    ocFlag;
    isLoaded;

    customLabel = {
        Days_For_Repeated_Indicator
    };

    renderedCallback() {
        if (this.objectApiName == 'Account') {
            this.addIconClass("[data-id='Repeated_Indicator_div']", 'slds-hide');
        }
    }

    connectedCallback() {
        this.getCaseRecord();
    }

    async getCaseRecord() {

        this.isLoaded = true;
        if (this.objectApiName == 'Case') {

            let fieldArray = "id, AccountId, LAN__c, Nature__c, Type_Text__c, Sub_Type_Text__c";
            let whereClauseOfRI = "WHERE id ='" + this.recordId + "' WITH SECURITY_ENFORCED";

            let rec = await getRecords({ fields: fieldArray, objectName: this.objectApiName, whereClause: whereClauseOfRI });
            if (rec) {
                this.caseRecord = rec[0];
                let caseAccId = this.caseRecord.hasOwnProperty('AccountId') ? this.caseRecord.AccountId : '';
                if(caseAccId) {             
                    if (!this.whereClauseForRI && !this.whereClauseForOC && caseAccId) {
                        this.initializeWhereClause();
                    } 
                    this.story_328_329_330();              
                }
            }
        }
        else if (this.objectApiName == 'Account') {
            this.addIconClass("[data-id='Repeated_Indicator']", 'slds-hide');
            this.removeIconClass("[data-id='Open_Complaint_Indicator_div']", 'slds-hide');
            this.initializeWhereClause();
            this.objectApiName = 'Case';
            this.story_328_329();
            this.objectApiName = 'Account';
        }
    }

    story_328_329_330() {

        let caseNature = this.caseRecord.Nature__c;
        if (caseNature == "Complaint") {
            this.story_328_329();
        }
        else {
            this.addIconClass("[data-id='Open_Complaint_Indicator_div']", 'slds-hide');
        }
        this.story_330();
    }

    initializeWhereClause() {

        let withSecEnforced = 'WITH SECURITY_ENFORCED';
        let commonForOC = `WHERE Stage__c = \'Open\' AND Nature__c = \'Complaint\'`;

        if (this.objectApiName == 'Case') {
            this.whereClauseForRI = `WHERE id != \'${this.recordId}\' AND AccountId = \'${this.caseRecord.AccountId}\' AND Stage__c = \'Resolved\' AND LAN__c = \'${this.caseRecord.LAN__c}\'
                                AND Nature__c = \'${this.caseRecord.Nature__c}\' AND Type_Text__c = \'${this.caseRecord.Type_Text__c}\' 
                                AND Sub_Type_Text__c = \'${this.caseRecord.Sub_Type_Text__c}\' AND CreatedDate = LAST_N_DAYS:${this.customLabel.Days_For_Repeated_Indicator} 
                                 ${withSecEnforced} LIMIT 2`;

            this.whereClauseForOC = `${commonForOC} AND AccountId = \'${this.caseRecord.AccountId}\'  ${withSecEnforced} LIMIT 1`;
        }
        else if (this.objectApiName == 'Account') {
            this.whereClauseForOC = `${commonForOC} AND AccountId = \'${this.recordId}\'  ${withSecEnforced} LIMIT 1`;
        }
    }

    async story_328_329() {
        let iconAttrObjOC = {};
        let sobRecords = await getRecords({ fields: this.fieldArr, objectName: this.objectApiName, whereClause: this.whereClauseForOC });
        if (sobRecords && sobRecords.length > 0) {
            iconAttrObjOC.dataId = '[data-id="Open_Complaint_Indicator"]';
            iconAttrObjOC.variant = 'error';
            this.addAndChangeAttributes(iconAttrObjOC);
        }
        this.isLoaded = false;

    }

    async story_330() {
        let iconAttrObjRI = {};
        let sobRecords = await getRecords({ fields: this.fieldArr, objectName: this.objectApiName, whereClause: this.whereClauseForRI });
        if (sobRecords && sobRecords.length > 0) {
            iconAttrObjRI.dataId = '[data-id="Repeated_Indicator"]';
            iconAttrObjRI.variant = 'error';
            this.addAndChangeAttributes(iconAttrObjRI);
        }
        this.isLoaded = false;
    }

    addAndChangeAttributes(attrbObj) {
        let getLightningIcon = this.template.querySelector(attrbObj.dataId);
        getLightningIcon.variant = attrbObj.variant;
    }

    addIconClass(dataId, iconClass) {
        let getLightningIcon = this.template.querySelector(dataId);
        if (getLightningIcon) {
            getLightningIcon.classList.add(iconClass);
        }
    }

    removeIconClass(dataId, iconClass) {
        let getLightningIcon = this.template.querySelector(dataId);
        if (getLightningIcon) {
            getLightningIcon.classList.remove(iconClass);
        }
    }
}