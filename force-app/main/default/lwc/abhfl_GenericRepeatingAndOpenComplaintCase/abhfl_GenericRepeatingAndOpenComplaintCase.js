import {
    LightningElement,
    api,
    track,
    wire
} from 'lwc';
import {
    getRecord,
    getFieldValue
} from 'lightning/uiRecordApi';
import Days_For_Repeated_Indicator from '@salesforce/label/c.Repeated_Indicator';
import getRecords from '@salesforce/apex/Abhfl_GenericRepeatingAndOpenComplntClas.genericFetchQuery';
import getCaseCounts from '@salesforce/apex/Asf_NpsIndicatiorController.getCaseCounts';
import getNpsScore from '@salesforce/apex/Asf_NpsIndicatiorController.getNpsScore';
import BUSINESS_UNIT from '@salesforce/schema/Account.Business_Unit__c';
import loggedInUserId from '@salesforce/user/Id';
import UserBusinessUnit from '@salesforce/schema/User.Business_Unit__c';
import getSurveyResponseFieldsByAccountId from '@salesforce/apex/Abhfl_GenericRepeatingAndOpenComplntClas.getSurveyResponseFieldsByAccountId';
export default class Abhfl_GenericRepeatingAndOpenComplaintCase extends LightningElement {
    @track isDisplayVisible = false; // added by nikhil
    showchild = false; // added by nikhil
    @api recordId;
    @api objectApiName;
    isAbhfl;;
    @track caseRecord;
    @track records;
    @track fieldArr = 'id';


    @track surveyresponse = [];
    @track surveyresponse1 = [];
    @track surveyresponse2 = [];
    @track errorinresponse;
    @track columns = [];
    @track columns1 = [];
    @track columns2 = [];
    @track isrespdataaval = false;
    @track isloading = false;
    @track showdetailsbuttonhide = false;
    @track loggedInUserBusinessUnit = '';
    errorMessage;
    whereClauseForRI = '';
    whereClauseForOC = '';
    riFlag;
    ocFlag;
    isLoaded;
    @track fieldArrNps = 'id,Nature__c,IsEscalated';
    whereClauseForRiNps = '';
    whereClauseForOcNps = '';
    riFlagNps;
    ocFlagNps;
    isLoadedNps;
    showOpenCase = "⚪️";
    showEscalatedCases = 0;
    nps = undefined;
    isAccount = false;

    @wire(getRecord, {
        recordId: loggedInUserId,
        fields: [UserBusinessUnit]
    })
    currentUserInfo({
        error,
        data
    }) {
        if (data) {
            console.log('dataaa-->' + JSON.stringify(data));
            this.loggedInUserBusinessUnit = data.fields.Business_Unit__c.value;
            console.log('loggedInUserBusinessUnit--->' + this.loggedInUserBusinessUnit);
            if (this.loggedInUserBusinessUnit == 'ABHFL') {
                this.showdetailsbuttonhide = true;
            }
        } else if (error) {
            console.error('Error occured in  retrieving business unit', JSON.stringify(error));
        }
    }
    loadNpsScore() {
        getNpsScore({
                customerId: this.recordId
            })
            .then(result => {
                this.nps = result;
                console.log('NPS record', this.nps);
            })
            .catch(error => {
                console.error('Error loading NPS record', error);
            });
    }
    get showCustomerNPSbyNumber() {
        if (this.nps == undefined) {
            return "❌";
        } else if (this.nps >= 0 && this.nps <= 6) {
            return "🙁";
        } else if (this.nps > 6 && this.nps <= 8) {
            return "😐";
        } else if (this.nps > 8 && this.nps <= 10) {
            return "😁";
        } else {
            return this.nps;
        }
    }
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [BUSINESS_UNIT]
    })
    wiredAccount({
        error,
        data
    }) {
        if (data) {
            const businessUnitValue = getFieldValue(data, BUSINESS_UNIT);
            this.isAbhfl = businessUnitValue === 'ABHFL';
        } else if (error) {
            console.error('Error occured in  retrieving business unit', error);
        }
    }

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
        this.getCaseRecordNps();
        this.loadNpsScore();
    }

    async getCaseRecord() {

        this.isLoaded = true;
        if (this.objectApiName == 'Case') {

            let fieldArray = "id, AccountId, LAN__c, Nature__c, Type_Text__c, Sub_Type_Text__c";
            let whereClauseOfRI = "WHERE id ='" + this.recordId + "' WITH SECURITY_ENFORCED";

            let rec = await getRecords({
                fields: fieldArray,
                objectName: this.objectApiName,
                whereClause: whereClauseOfRI
            });
            if (rec) {
                this.caseRecord = rec[0];
                let caseAccId = this.caseRecord.hasOwnProperty('AccountId') ? this.caseRecord.AccountId : '';
                if (caseAccId) {
                    if (!this.whereClauseForRI && !this.whereClauseForOC && caseAccId) {
                        this.initializeWhereClause();
                    }
                    this.story_328_329_330();
                } else {
                    this.isLoaded = false;
                }
            }
        } else if (this.objectApiName == 'Account') {
            this.isAccount = true;
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
        } else {
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
        } else if (this.objectApiName == 'Account') {
            this.whereClauseForOC = `${commonForOC} AND AccountId = \'${this.recordId}\'  ${withSecEnforced} LIMIT 1`;
        }
    }

    async story_328_329() {
        let iconAttrObjOC = {};
        let sobRecords = await getRecords({
            fields: this.fieldArr,
            objectName: this.objectApiName,
            whereClause: this.whereClauseForOC
        });
        iconAttrObjOC.dataId = '[data-id="Open_Complaint_Indicator"]';
        if (sobRecords && sobRecords.length > 0) {
            iconAttrObjOC.variant = 'error';
            this.addAndChangeAttributes(iconAttrObjOC);
        } else {
            iconAttrObjOC.variant = '';
            this.addAndChangeAttributes(iconAttrObjOC);
        }
        this.isLoaded = false;

    }

    async story_330() {
        let iconAttrObjRI = {};
        let sobRecords = await getRecords({
            fields: this.fieldArr,
            objectName: this.objectApiName,
            whereClause: this.whereClauseForRI
        });
        if (sobRecords && sobRecords.length > 0) {
            iconAttrObjRI.dataId = '[data-id="Repeated_Indicator"]';
            iconAttrObjRI.variant = 'error';
            this.addAndChangeAttributes(iconAttrObjRI);
        }
        this.isLoaded = false;
    }

    addAndChangeAttributes(attrbObj) {
        let getLightningIcon = this.template.querySelector(attrbObj.dataId);
        //  getLightningIcon.variant = attrbObj.variant;
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
    async getCaseRecordNps() {
        this.initializeWhereClauseNps();
    }
    initializeWhereClauseNps() {
        let withSecEnforcedNps = 'WITH SECURITY_ENFORCED';
        let commonForOcNps = 'WHERE (IsClosed = False';
        this.whereClauseForOcNps = `${commonForOcNps} AND AccountId = \'${this.recordId}\')OR IsEscalated = True ${withSecEnforcedNps} `;
        this.npsIndicator();
    }
    async npsIndicator() {
        await getCaseCounts({
                accountId: this.recordId
            })
            .then((result) => {
                this.isLoaded = false;
                if (result) {
                    this.showOpenCase = result.openCases || 0;
                    this.showOpenComplaintCase = result.complaintCases || 0;
                    this.showEscalatedCases = result.escalatedCases || 0;
                } else {
                    this.showOpenCase = 0;
                    this.showOpenComplaintCase = 0;
                    this.showEscalatedCases = 0;
                }
            })
            .catch((error) => {
                console.error(error);
            });
    }
    getCaseRecordCommon() {
        this.loadNpsScore();
        this.getCaseRecord();
        this.getCaseRecordNps();
    }

    // Added By Yogesh start[PR970457-2195]     
     async handleClick() {
        console.log('I m here');
        // this.getCaseRecordCommon();
        this.isloading = true;
        await getSurveyResponseFieldsByAccountId({
                accountId: this.recordId
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
                    /*if(picklistField == 'Case__r.Nature__c'){
                        if(row['Case__r'] != undefined && row['Case__r'].Nature__c != undefined)
                         selectedValue = row['Case__r'].Nature__c
                    }*/
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

    /*  setupColumns(data) {
        if (data.length > 0) {
            this.columns = Object.keys(data[0]).map(field => ({
                label: this.formatFieldLabel(field),
                fieldName: field,
                type: 'text'
            }));
            console.log('columns-->'+JSON.stringify(columns));
        }
    }

    formatFieldLabel(field) {
        // Format field name for better readability
        return field.replace(/_/g, ' ').replace(/\b\w/g, char => char.toUpperCase());
    }*/
    closeresp() {
        this.isrespdataaval = false;
    }
}