import { LightningElement, wire, api, track } from 'lwc';
import { createRecord, notifyRecordUpdateAvailable, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Days_For_Repeated_Indicator from '@salesforce/label/c.Repeated_Indicator';
// import getRecords from '@salesforce/apex/Asf_NpsIndicatiorController.genericFetchQuery';
import getNpsScore from '@salesforce/apex/Asf_NpsIndicatiorController.getNpsScore';


export default class Asf_customernpsresult extends LightningElement {
    @api recordId;
    nps = undefined;
    @api objectApiName;
    @track caseRecord;
    @track records;
    @track fieldArr = 'id,Nature__c,IsEscalated';

    whereClauseForRI = '';
    whereClauseForOC = '';
    riFlag;
    ocFlag;
    isLoaded;
    showOpenCase = "⚪️";
    showEscalatedCases=0;

    customLabel = {
        Days_For_Repeated_Indicator
    };

    @wire (getNpsScore,{customerId: '$recordId'})
	npsScore({data, error}){
		if(data) {
            this.nps =data;
            console.log('nps record', this.nps);
		}else if (error) {
            console.error('Error loading nps record', error);
        }
	}
    connectedCallback() {
        this.getCaseRecord();
    }
    get showCustomerNPSbyNumber() {
        if (this.nps == 0 || this.nps == undefined) {
            return "❌";
        }
        else if(this.nps > 0 && this.nps <= 3){
            return "🙁";
        }
        else if(this.nps > 3 &&  this.nps <= 6){
            return "😐";
        }
        else if(this.nps > 6 && this.nps <= 10){
            return "😁";
        }
        else {
            return this.nps;
        }
    }

    customLabel = {
        Days_For_Repeated_Indicator
    };

    

    connectedCallback() {
        this.getCaseRecord();
    }

    async getCaseRecord() {

            this.initializeWhereClause();
    }

    initializeWhereClause() {

        let withSecEnforced = 'WITH SECURITY_ENFORCED';
        let commonForOC = 'WHERE (IsClosed = False';

            this.whereClauseForOC = `${commonForOC} AND AccountId = \'${this.recordId}\')OR IsEscalated = True ${withSecEnforced} `;
            this.story_328_329();
    }

    async story_328_329() {
        let iconAttrObjOC = {};
        await getRecords({ fields: this.fieldArr, objectName: 'Case', whereClause: this.whereClauseForOC })
        .then((result) => {
            if(result && result.length >0){
                this.showOpenCase = result.length;
                var iCountComplaints = 0;
                var iCountEscalatedCases = 0;
                for(var i = 0;i<result.length;i++){
                    if(result[i].Nature__c == 'Complaint'){
                        iCountComplaints++;
                    }
                    if(result[i].IsEscalated){
                        iCountEscalatedCases++
                    }
                }
                this.showOpenComplaintCase = iCountComplaints;
                this.showEscalatedCases = iCountEscalatedCases;
            }
            else{
                this.showOpenCase = 0;
                this.showOpenComplaintCase = 0;
                this.showEscalatedCases=0;
            }
        })
        .catch((error)=>{
            console.log(error);
        })
        

    }


}