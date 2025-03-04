import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Days_For_Repeated_Indicator from '@salesforce/label/c.Repeated_Indicator';
import getRecords from '@salesforce/apex/Abhfl_GenericRepeatingAndOpenComplntClas.genericFetchQuery';
import getCaseCounts from '@salesforce/apex/Asf_NpsIndicatiorController.getCaseCounts';
import getNpsScore from '@salesforce/apex/Asf_NpsIndicatiorController.getNpsScore';
import BUSINESS_UNIT from '@salesforce/schema/Account.Business_Unit__c';
import { lanLabels } from 'c/asf_ConstantUtility';
import loggedInUserId from '@salesforce/user/Id';
import UserBusinessUnit from '@salesforce/schema/User.Business_Unit__c';
import { CurrentPageReference } from 'lightning/navigation';
import { EnclosingTabId, getTabInfo, openSubtab } from 'lightning/platformWorkspaceApi';
import { NavigationMixin} from 'lightning/navigation';
export default class Abhfl_GenericRepeatingAndOpenComplaintCase extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;
    isAbhfl;
    isWellness;
    isOther;
    @track caseRecord;
    @track records;
    @track fieldArr = 'id';

    
    @track showdetailsbuttonhide = false;
    @track loggedInUserBusinessUnit = '';
    

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
    showEscalatedCases=0;
    nps = undefined;
    isAccount = false;
    showCustomerNPSbyNumber;
    customerBU = '';

     @wire(EnclosingTabId) tabId;
     @wire(CurrentPageReference) pageRef;
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
            if (this.loggedInUserBusinessUnit == 'ABHFL' && this.objectApiName == 'Account') {
                this.showdetailsbuttonhide = true;
            }
        } else if (error) {
            console.error('Error occured in  retrieving business unit', JSON.stringify(error));
        }
    }
    loadNpsScore() {
        getNpsScore({ customerId: this.recordId })
            .then(result => {
                this.nps = result;
                console.log('NPS record', this.nps); 
                this.claculateNPSRating();
            })
            .catch(error => {
                console.error('Error loading NPS record', error);
            });
    }

    claculateNPSRating() {

        this.showCustomerNPSbyNumber = undefined;

        if(JSON.stringify(this.nps) !== "{}") {
            this.businessUnit = Object.keys(this.nps)[0];
            this.showCustomerNPSbyNumber = this.nps[this.businessUnit];
        }
        else {
            this.businessUnit = this.customerBU;
        }

        if(this.businessUnit && (this.businessUnit !== lanLabels[this.businessUnit].ABHI_BUSINESS_UNIT)) {
            if(this.businessUnit == 'ABHFL'){
                if (this.showCustomerNPSbyNumber == undefined) {
                    this.showCustomerNPSbyNumber =  "❌";
                }
                else if(this.showCustomerNPSbyNumber >= 0 && this.showCustomerNPSbyNumber <= 6){
                    this.showCustomerNPSbyNumber =  "🙁";
                }
                else if(this.showCustomerNPSbyNumber > 6 &&  this.showCustomerNPSbyNumber <= 8){
                    this.showCustomerNPSbyNumber =  "😐";
                }
                else if(this.showCustomerNPSbyNumber > 8 && this.showCustomerNPSbyNumber <= 10){
                    this.showCustomerNPSbyNumber =  "😁";
                }
                else {
                    this.showCustomerNPSbyNumber = '';
                }
            }else{
                if (this.showCustomerNPSbyNumber == 0 || this.showCustomerNPSbyNumber == undefined) {
                    this.showCustomerNPSbyNumber =  "❌";
                }
                else if(this.showCustomerNPSbyNumber > 0 && this.showCustomerNPSbyNumber <= 3){
                    this.showCustomerNPSbyNumber =  "🙁";
                }
                else if(this.showCustomerNPSbyNumber > 3 &&  this.showCustomerNPSbyNumber <= 6){
                    this.showCustomerNPSbyNumber =  "😐";
                }
                else if(this.showCustomerNPSbyNumber > 6 && this.showCustomerNPSbyNumber <= 10){
                    this.showCustomerNPSbyNumber =  "😁";
                }
                else {
                    this.showCustomerNPSbyNumber = '';
                }
            }
            
        }
        else if(this.businessUnit && (this.businessUnit === lanLabels[this.businessUnit].ABHI_BUSINESS_UNIT)) {
            this.logicToShowEmoji();
        }
    }

    logicToShowEmoji() {
        if(this.showCustomerNPSbyNumber <= 6){
            this.showCustomerNPSbyNumber =  "🙁";
        }
        else if(this.showCustomerNPSbyNumber <= 8){
            this.showCustomerNPSbyNumber =  "😐";
        }
        else if(this.showCustomerNPSbyNumber <= 10){
            this.showCustomerNPSbyNumber =  "😁";
        }
        else {
            this.showCustomerNPSbyNumber = '';
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [BUSINESS_UNIT]
    })
    wiredAccount({ error, data }) {
        if (data) {
            const businessUnitValue = getFieldValue(data, BUSINESS_UNIT);
            this.isAbhfl = businessUnitValue === 'ABHFL';
            this.isWellness = businessUnitValue === 'Wellness';
            this.isOther = (businessUnitValue !== 'ABHFL' && businessUnitValue !== 'Wellness');
            this.customerBU = businessUnitValue ?? '';
            this.loadNpsScore();
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
                else {
                    this.isLoaded = false;
                }
            }
        }
        else if (this.objectApiName == 'Account') {
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
        iconAttrObjOC.dataId = '[data-id="Open_Complaint_Indicator"]';
        if (sobRecords && sobRecords.length > 0) {
            iconAttrObjOC.variant = 'error';
            this.addAndChangeAttributes(iconAttrObjOC);
        }
        else {
            iconAttrObjOC.variant = '';
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
        await getCaseCounts({ accountId: this.recordId })
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
    getCaseRecordCommon(){
        this.loadNpsScore();
        this.getCaseRecord();
        this.getCaseRecordNps();
    }
    
	// Added By Yogesh start[PR970457-2195]
        async handleClick() {
        try {
            // Get tab info to find the primary tab
            const tabInfo = await getTabInfo(this.tabId);
            const primaryTabId = tabInfo.isSubtab ? tabInfo.parentTabId : tabInfo.tabId;
            this.navigateToFA()
            // Open a new subtab
            /*const newSubtabId = await openSubtab(primaryTabId, {
                pageReference: {
                    type: 'standard__component',
                    attributes: {
                        componentName: 'c:abhfl_NavigationAura'
                    },
                    state: {
                        c__accountId: this.recordId
                    }
                },
                focus: true,
            });

            console.log('Subtab opened with tabId:', newSubtabId);

            // Set the label for the new subtab
            await setTabLabel({
                tabId: newSubtabId,
                label: 'Survey details', // Replace with your desired label
            });

            console.log('Subtab label set successfully.');
            */
        } catch (error) {
            console.error('Error:', error);
        }
        
    }
    navigateToFA() {
        this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
        var strtabId;
        if(focusedTab.tabId){strtabId=focusedTab.tabId}
        if(focusedTab.parentTabId){strtabId=focusedTab.parentTabId}
        this.invokeWorkspaceAPI('openSubtab', {
            parentTabId: strtabId,
            pageReference: {
            type: "standard__component",
            attributes: {
                componentName: "c__abhfl_NavigationAura",
            },
            state: {
                c__accountId: this.recordId
            }
            },
            focus: true
        }).then(response => {
            this.invokeWorkspaceAPI('setTabLabel', {
            tabId: response,
            label: 'Survey Details'
            }),
            this.invokeWorkspaceAPI('setTabIcon', {
                tabId: response,
                icon: "utility:product_transfer",
                iconAlt: "apex_plugin"
            })
        });
        });
    }
    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
        const apiEvent = new CustomEvent("internalapievent", {
            bubbles: true,
            composed: true,
            cancelable: false,
 
            detail: {
            category: "workspaceAPI",
            methodName: methodName,
            methodArgs: methodArgs,
            callback: (err, response) => {
                if (err) {
                return reject(err);
                } else {
                return resolve(response);
                }
            }
            }
        });
        window.dispatchEvent(apiEvent);
        });
    }
}
